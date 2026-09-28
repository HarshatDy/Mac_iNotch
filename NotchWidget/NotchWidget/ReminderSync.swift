import SwiftUI
import EventKit
import os

/// A reminder as read from Apple Reminders, detached from EventKit so it can cross threads.
struct SyncedItem: Sendable {
    let ekID: String
    let calendarID: String
    let title: String
    let due: Date?
    let hasAlarm: Bool
    let created: Date?
}

/// Mirrors Notcheee's data into Apple Reminders so it syncs over iCloud to iPhone and Apple Watch
/// (no companion app needed — the Reminders app there shows the lists and rings the alarms).
///
/// - "Notcheee"        ⇄ Up Next (two-way)
/// - "Brain Dump"      ⇄ Brain Dump (two-way)
/// - "Notcheee Timers" ← Pomodoro / Working On end times, so the phone and watch alert when they finish
///
/// Apple Reminders is the source of truth once access is granted; Notcheee keeps a local cache
/// (UserDefaults) and falls back to it entirely if access is denied.
@Observable
@MainActor
final class ReminderSync {
    static let shared = ReminderSync()

    enum Access { case notDetermined, granted, denied }
    enum TimerKind: String { case pomodoro, work }

    static let upNextName = "Notcheee"
    static let brainDumpName = "Brain Dump"
    static let timersName = "Notcheee Timers"

    private(set) var access: Access
    private(set) var ready = false
    private(set) var lastError: String?

    var isActive: Bool { access == .granted && ready }

    @ObservationIgnored private let store = EKEventStore()
    @ObservationIgnored private var state: NotchState?
    @ObservationIgnored private var upNextList: EKCalendar?
    @ObservationIgnored private var brainDumpList: EKCalendar?
    @ObservationIgnored private var timersList: EKCalendar?
    @ObservationIgnored private var timerTargets: [TimerKind: (title: String, due: Date)] = [:]
    @ObservationIgnored private var observer: NSObjectProtocol?

    private enum Keys {
        static let upNext = "nw2_list_upnext"
        static let brainDump = "nw2_list_braindump"
        static let timers = "nw2_list_timers"
        static let migrated = "nw2_reminders_migrated"
        static let urgentUpgrade = "nw2_reminders_urgent_v1"
        static func timer(_ kind: TimerKind) -> String { "nw2_timer_\(kind.rawValue)" }
    }

    private init() {
        switch EKEventStore.authorizationStatus(for: .reminder) {
        case .fullAccess:    access = .granted
        case .notDetermined: access = .notDetermined
        default:             access = .denied
        }
    }

    // MARK: - Lifecycle

    func start(state: NotchState) {
        self.state = state
        Self.log.notice("Reminders access: \(String(describing: self.access), privacy: .public)")
        observer = NotificationCenter.default.addObserver(forName: .EKEventStoreChanged, object: store, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.reload() }
        }
        switch access {
        case .granted:       setUp()
        case .notDetermined: requestAccess()
        case .denied:        break
        }
    }

    func requestAccess() {
        store.requestFullAccessToReminders { [weak self] granted, _ in
            Task { @MainActor in
                guard let self else { return }
                self.access = granted ? .granted : .denied
                if granted { self.setUp() }
            }
        }
    }

    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Reminders") {
            NSWorkspace.shared.open(url)
        }
    }

    private func setUp() {
        store.refreshSourcesIfNecessary()
        upNextList = resolveList(Self.upNextName, key: Keys.upNext, color: NSColor(NT.blue))
        brainDumpList = resolveList(Self.brainDumpName, key: Keys.brainDump, color: NSColor(NT.teal))
        timersList = resolveList(Self.timersName, key: Keys.timers, color: NSColor(NT.orange))
        guard upNextList != nil, brainDumpList != nil, timersList != nil else {
            lastError = "Couldn’t create the Reminders lists."
            return
        }
        ready = true
        lastError = nil
        Self.log.notice("Reminders sync ready; Urgent API available: \(NTUrgentReminders.isAvailable, privacy: .public)")
        migrateLocalDataIfNeeded()
        upgradeExistingIfNeeded()
        clearStaleTimers()
        state?.resyncTimers()
        reload()
    }

    /// Finds a list by its saved identifier, then by name, and creates it if missing.
    private func resolveList(_ name: String, key: String, color: NSColor) -> EKCalendar? {
        if let id = UserDefaults.standard.string(forKey: key),
           let cal = store.calendar(withIdentifier: id), cal.allowsContentModifications {
            return cal
        }
        if let cal = store.calendars(for: .reminder).first(where: { $0.title == name && $0.allowsContentModifications }) {
            UserDefaults.standard.set(cal.calendarIdentifier, forKey: key)
            return cal
        }
        guard let source = store.defaultCalendarForNewReminders()?.source
                ?? store.sources.first(where: { $0.sourceType == .calDAV })
                ?? store.sources.first(where: { $0.sourceType == .local })
        else { return nil }
        let cal = EKCalendar(for: .reminder, eventStore: store)
        cal.title = name
        cal.source = source
        cal.cgColor = color.cgColor
        do {
            try store.saveCalendar(cal, commit: true)
        } catch {
            lastError = error.localizedDescription
            return nil
        }
        UserDefaults.standard.set(cal.calendarIdentifier, forKey: key)
        return cal
    }

    /// One-time push of reminders / brain-dump items created before sync was turned on.
    private func migrateLocalDataIfNeeded() {
        guard let state, !UserDefaults.standard.bool(forKey: Keys.migrated) else { return }
        let now = Date()
        for i in state.reminders.indices where state.reminders[i].ekID == nil {
            let r = state.reminders[i]
            guard r.due.map({ $0 > now }) ?? true else { continue }
            state.reminders[i].ekID = saveReminder(r)
        }
        for i in state.inbox.indices where state.inbox[i].ekID == nil {
            state.inbox[i].ekID = saveInbox(state.inbox[i])
        }
        UserDefaults.standard.set(true, forKey: Keys.migrated)
    }

    /// One-time: clear the High priority an earlier build set, and turn on Urgent for existing timed items.
    private func upgradeExistingIfNeeded() {
        guard !UserDefaults.standard.bool(forKey: Keys.urgentUpgrade) else { return }
        let lists = [upNextList, timersList].compactMap { $0 }
        let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: lists)
        let high = Int(EKReminderPriority.high.rawValue)
        store.fetchReminders(matching: predicate) { [weak self] reminders in
            let items = (reminders ?? []).map { ($0.calendarItemIdentifier, $0.priority == high, $0.dueDateComponents != nil && $0.hasAlarms) }
            Task { @MainActor in
                guard let self else { return }
                for (id, isHigh, timed) in items {
                    guard let ek = self.existing(id) else { continue }
                    if isHigh { ek.priority = 0 }
                    if isHigh || timed { _ = self.commit(ek, urgent: timed) }
                }
                UserDefaults.standard.set(true, forKey: Keys.urgentUpgrade)
            }
        }
    }

    // MARK: - Reading

    func reload() {
        guard isActive, let upNext = upNextList, let brainDump = brainDumpList else { return }
        let upNextID = upNext.calendarIdentifier
        let brainDumpID = brainDump.calendarIdentifier
        let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [upNext, brainDump])
        store.fetchReminders(matching: predicate) { [weak self] reminders in
            let items: [SyncedItem] = (reminders ?? []).map { r in
                SyncedItem(ekID: r.calendarItemIdentifier,
                           calendarID: r.calendar?.calendarIdentifier ?? "",
                           title: r.title ?? "",
                           due: r.dueDateComponents.flatMap { Calendar.current.date(from: $0) },
                           hasAlarm: r.hasAlarms,
                           created: r.creationDate)
            }
            Task { @MainActor in
                self?.state?.applyRemote(upNext: items.filter { $0.calendarID == upNextID },
                                         brainDump: items.filter { $0.calendarID == brainDumpID })
            }
        }
    }

    // MARK: - Writing (Up Next / Brain Dump)

    /// Creates or updates the Apple Reminders copy of an Up Next reminder; returns its identifier.
    @discardableResult
    func saveReminder(_ r: Reminder) -> String? {
        guard isActive, let list = upNextList else { return r.ekID }
        let ek = existing(r.ekID) ?? EKReminder(eventStore: store)
        ek.calendar = list
        ek.title = r.title
        setDue(ek, r.due, alarm: r.alarm)
        return commit(ek, urgent: r.due != nil && r.alarm)
    }

    @discardableResult
    func saveInbox(_ item: InboxItem) -> String? {
        guard isActive, let list = brainDumpList else { return item.ekID }
        let ek = existing(item.ekID) ?? EKReminder(eventStore: store)
        ek.calendar = list
        ek.title = item.text
        return commit(ek)
    }

    /// Moves a Brain Dump item into Up Next with a due time (keeps the same Reminders item).
    @discardableResult
    func moveToUpNext(_ ekID: String, title: String, due: Date) -> String? {
        guard isActive, let list = upNextList, let ek = existing(ekID) else { return nil }
        ek.calendar = list
        ek.title = title
        setDue(ek, due, alarm: true)
        return commit(ek, urgent: true)
    }

    func complete(_ ekID: String?) {
        guard isActive, let ek = existing(ekID) else { return }
        ek.isCompleted = true
        _ = commit(ek)
    }

    func remove(_ ekID: String?) {
        guard isActive, let ek = existing(ekID) else { return }
        do { try store.remove(ek, commit: true) } catch { lastError = error.localizedDescription }
    }

    // MARK: - Timers (Pomodoro / Working On end times)

    /// Keeps one "Notcheee Timers" item per timer kind in step with the running timer.
    /// `target == nil` means the timer stopped: a timer cancelled early is removed right away; one
    /// that ran to its end is left for two minutes so the iPhone / Watch alarm still fires, then removed.
    func setTimer(_ kind: TimerKind, _ target: (title: String, due: Date)?) {
        let current = timerTargets[kind]
        switch (current, target) {
        case (nil, nil):
            return
        case let (c?, t?) where c.title == t.title && abs(c.due.timeIntervalSince(t.due)) < 1:
            return
        default:
            break
        }
        timerTargets[kind] = target
        guard isActive, let list = timersList else { return }

        let key = Keys.timer(kind)
        let ek = existing(UserDefaults.standard.string(forKey: key))
        if let target {
            let item = ek ?? EKReminder(eventStore: store)
            item.calendar = list
            item.title = target.title
            item.notes = "Set by Notcheee"
            item.isCompleted = false
            setDue(item, target.due, alarm: true)
            if let id = commit(item, urgent: true) { UserDefaults.standard.set(id, forKey: key) }
        } else if let ek {
            UserDefaults.standard.removeObject(forKey: key)
            let due = ek.dueDateComponents.flatMap { Calendar.current.date(from: $0) }
            if let due, due <= Date().addingTimeInterval(5) {
                let id = ek.calendarItemIdentifier
                Task { [weak self] in
                    try? await Task.sleep(for: .seconds(120))
                    self?.remove(id)
                }
            } else {
                remove(ek.calendarItemIdentifier)
            }
        }
    }

    /// Leftovers from a previous run (e.g. the app quit mid-Pomodoro) are removed; live timers are re-added.
    private func clearStaleTimers() {
        guard let list = timersList else { return }
        timerTargets = [:]
        UserDefaults.standard.removeObject(forKey: Keys.timer(.pomodoro))
        UserDefaults.standard.removeObject(forKey: Keys.timer(.work))
        let predicate = store.predicateForIncompleteReminders(withDueDateStarting: nil, ending: nil, calendars: [list])
        store.fetchReminders(matching: predicate) { [weak self] reminders in
            let ids = (reminders ?? []).map(\.calendarItemIdentifier)
            Task { @MainActor in
                guard let self else { return }
                let live = Set(TimerKind.allCases.compactMap { UserDefaults.standard.string(forKey: Keys.timer($0)) })
                for id in ids where !live.contains(id) { self.remove(id) }
            }
        }
    }

    // MARK: - Helpers

    private func existing(_ ekID: String?) -> EKReminder? {
        ekID.flatMap { store.calendarItem(withIdentifier: $0) as? EKReminder }
    }

    private func setDue(_ ek: EKReminder, _ due: Date?, alarm: Bool) {
        ek.alarms?.forEach { ek.removeAlarm($0) }
        guard let due else {
            ek.dueDateComponents = nil
            return
        }
        var comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: due)
        comps.timeZone = TimeZone.current
        ek.dueDateComponents = comps
        if alarm { ek.addAlarm(EKAlarm(absoluteDate: due)) }
    }

    /// Saves the item. With `urgent`, also switches on the Reminders app's Urgent option so the iPhone and
    /// Apple Watch ring like an alarm; `false` switches it off (e.g. an Up Next reminder's alarm was turned off).
    private func commit(_ ek: EKReminder, urgent: Bool? = nil) -> String? {
        do {
            try store.save(ek, commit: true)
        } catch {
            lastError = error.localizedDescription
            return nil
        }
        if let urgent { setUrgent(urgent, for: ek) }
        return ek.calendarItemIdentifier
    }

    @ObservationIgnored private let urgentQueue = DispatchQueue(label: "com.harshat.NotchWidget.urgent")
    nonisolated private static let log = Logger(subsystem: "com.harshat.NotchWidget", category: "urgent")

    private func setUrgent(_ urgent: Bool, for ek: EKReminder) {
        let id = ek.calendarItemIdentifier
        let external = ek.calendarItemExternalIdentifier
        let title = ek.title ?? ""
        urgentQueue.async {
            do {
                try NTUrgentReminders.setUrgent(urgent, forReminderIdentifier: id, externalIdentifier: external)
                Self.log.notice("Urgent \(urgent ? "on" : "off", privacy: .public) for “\(title, privacy: .public)”")
            } catch {
                Self.log.error("Couldn’t set Urgent for “\(title, privacy: .public)”: \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}

extension ReminderSync.TimerKind: CaseIterable {}
