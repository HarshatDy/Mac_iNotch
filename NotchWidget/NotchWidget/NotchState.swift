import SwiftUI
import AppKit

// MARK: - Model

enum PomoPhase: String {
    case focus, short, long

    var length: Int {
        switch self {
        case .focus: return 25 * 60
        case .short: return 5 * 60
        case .long:  return 15 * 60
        }
    }
}

struct Pomodoro {
    var phase: PomoPhase = .focus
    var cycle = 1            // 1…4
    var done = 0             // focus sessions finished in the current set of four
    var running = false
    var endsAt = Date.distantPast
    var remaining = PomoPhase.focus.length
    var total = PomoPhase.focus.length

    var isFocus: Bool  { phase == .focus }
    var active: Bool   { running || remaining != total }
    var idle: Bool     { !running && remaining == total }
    var progress: Double { total > 0 ? 1 - Double(remaining) / Double(total) : 0 }
    var color: Color   { isFocus ? NT.orange : NT.green }
}

enum Alarm: Equatable {
    case focusDone(cycle: Int)
    case breakDone(nextCycle: Int)
}

struct Reminder: Codable, Identifiable {
    var id = UUID()
    var title: String
    var due: Date?
}

struct InboxItem: Codable, Identifiable {
    var id = UUID()
    var text: String
    var t: Date
}

struct Snip: Codable, Identifiable {
    var id = UUID()
    var rect: CGRect      // top-left origin, in screen points
    var screen: CGSize    // screen size at capture time
    var t: Date
}

/// A task the user can pick to work on, with the time they plan to spend on it.
struct WorkTask: Codable, Identifiable, Equatable {
    var id = UUID()
    var title: String
    var min: Int
}

/// The task currently being worked on; `overdue` flips once its planned time runs out.
struct ActiveTask: Codable {
    var title: String
    var min: Int
    var since: Date
    var overdue = false

    var endsAt: Date { since.addingTimeInterval(Double(min * 60)) }
}

enum RestingVariant: String, Codable { case short, progress }
enum AlertType: String, Codable { case sound, haptic }
enum SnipMode: String { case area, window, screen }
enum NotchDisplay { case compact, open, settings, alarm }

// MARK: - Persistence

private enum Store {
    static let reminders = "nw2_reminders"
    static let inbox     = "nw2_inbox"
    static let snips     = "nw2_snips"
    static let tasks     = "nw2_tasks"
    static let active    = "nw2_active_task"
    static let alert     = "nw2_alert"
    static let variant   = "nw2_variant"

    static func load<T: Decodable>(_ key: String, default fallback: @autoclosure () -> T) -> T {
        guard let data = UserDefaults.standard.data(forKey: key),
              let value = try? JSONDecoder().decode(T.self, from: data)
        else { return fallback() }
        return value
    }

    static func save<T: Encodable>(_ key: String, _ value: T) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }
}

// MARK: - Main state object

@Observable
@MainActor
final class NotchState {
    static let shared = NotchState()

    // Physical notch + screen (kept current by NotchWindowController)
    var hwWidth: CGFloat = 184
    var hwHeight: CGFloat = 32
    var screenSize = CGSize(width: 1440, height: 900)
    var wallpaper: NSImage?

    private(set) var now = Date()

    // Persisted
    var reminders: [Reminder]    { didSet { Store.save(Store.reminders, reminders) } }
    var inbox: [InboxItem]       { didSet { Store.save(Store.inbox, inbox) } }
    var snips: [Snip]            { didSet { Store.save(Store.snips, snips) } }
    var tasks: [WorkTask]        { didSet { Store.save(Store.tasks, tasks) } }
    var activeTask: ActiveTask?  { didSet { Store.save(Store.active, activeTask) } }
    var alertType: AlertType     { didSet { Store.save(Store.alert, alertType) } }
    var variant: RestingVariant  { didSet { Store.save(Store.variant, variant) } }

    // Transient
    var pomo = Pomodoro()
    var alarm: Alarm?
    var snipMode: SnipMode = .area
    var capturing = false
    var showSettings = false
    private(set) var hover = false { didSet { syncSettings() } }
    private var focusedInputs: Set<String> = []

    // Hooks installed by the window layer
    @ObservationIgnored var captureHandler: ((SnipMode) -> Void)?
    @ObservationIgnored var resignInputFocus: (() -> Void)?

    @ObservationIgnored private var enterTask: Task<Void, Never>?
    @ObservationIgnored private var leaveTask: Task<Void, Never>?
    @ObservationIgnored private var ticker: Timer?

    private init() {
        let now = Date()
        reminders = Store.load(Store.reminders, default: Self.seedReminders(now))
        inbox = Store.load(Store.inbox, default: [
            InboxItem(text: "Try Figma variables for spacing tokens", t: now.addingTimeInterval(-42 * 60)),
            InboxItem(text: "Ask Priya about trip dates", t: now.addingTimeInterval(-3 * 3600)),
        ])
        snips = Store.load(Store.snips, default: [
            Snip(rect: CGRect(x: 180, y: 140, width: 520, height: 320), screen: CGSize(width: 1440, height: 900), t: now.addingTimeInterval(-6 * 60)),
            Snip(rect: CGRect(x: 0, y: 0, width: 1440, height: 900), screen: CGSize(width: 1440, height: 900), t: now.addingTimeInterval(-55 * 60)),
        ])
        tasks = Store.load(Store.tasks, default: [
            WorkTask(title: "Write project brief", min: 45),
            WorkTask(title: "Review PRs", min: 20),
            WorkTask(title: "Reply to emails", min: 15),
        ])
        activeTask = Store.load(Store.active, default: nil)
        alertType = Store.load(Store.alert, default: .sound)
        variant = Store.load(Store.variant, default: .short)
        startTicker()
    }

    private static func seedReminders(_ now: Date) -> [Reminder] {
        let cal = Calendar.current
        let tomorrow = cal.date(byAdding: .day, value: 1, to: now) ?? now
        let tomorrow6pm = cal.date(bySettingHour: 18, minute: 0, second: 0, of: tomorrow)
        return [
            Reminder(title: "Pay fees", due: now.addingTimeInterval(40 * 60)),
            Reminder(title: "Submit lab report", due: now.addingTimeInterval(3 * 3600 + 15 * 60)),
            Reminder(title: "Call Rahul", due: tomorrow6pm),
        ]
    }

    // MARK: - Derived

    var inputFocused: Bool { !focusedInputs.isEmpty }
    var isOpen: Bool { !capturing && (hover || inputFocused) }

    var display: NotchDisplay {
        if alarm != nil { return .alarm }
        if isOpen { return showSettings ? .settings : .open }
        return .compact
    }

    /// A physical notch taller than the design's 32pt pushes the panel content down by the difference.
    private var extraTop: CGFloat { max(0, hwHeight - 32) }

    var width: CGFloat {
        switch display {
        case .open, .settings: return min(800, screenSize.width - 32)
        case .alarm:           return 640
        case .compact:         return variant == .short ? hwWidth + 150 : hwWidth
        }
    }

    var height: CGFloat {
        switch display {
        case .open:     return 506 + extraTop
        case .settings: return 296 + extraTop
        case .alarm:    return 150 + extraTop
        case .compact:  return hwHeight
        }
    }

    var radius: CGFloat {
        display == .compact ? (variant == .progress ? 12 : 16) : 32
    }

    var nextReminder: Reminder? {
        upcomingReminders.first
    }

    var upcomingReminders: [Reminder] {
        reminders
            .compactMap { r in r.due.map { (r, $0) } }
            .filter { $0.1 > now }
            .sorted { $0.1 < $1.1 }
            .map(\.0)
    }

    var showProgressOutline: Bool {
        variant == .progress && display == .compact && (pomo.active || workActive)
    }

    var taskOverdue: Bool { activeTask?.overdue == true }
    var workActive: Bool { activeTask != nil }

    /// 0…1 share of the working-on task's planned time that has elapsed.
    var workProgress: Double {
        guard let t = activeTask else { return 0 }
        return max(0, min(1, now.timeIntervalSince(t.since) / Double(t.min * 60)))
    }

    var workRemaining: Int {
        guard let t = activeTask else { return 0 }
        return max(0, Int(ceil(t.endsAt.timeIntervalSince(now))))
    }

    /// Work timer colour: teal while running (distinct from Pomodoro orange/green), yellow once time's up.
    var workColor: Color { taskOverdue ? NT.yellow : NT.teal }

    // MARK: - Clock / engines

    private func startTicker() {
        let t = Timer(timeInterval: 0.25, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(t, forMode: .common)
        ticker = t
    }

    private func tick() {
        let d = Date()
        if Int(d.timeIntervalSince1970) != Int(now.timeIntervalSince1970) { now = d }

        // Pomodoro engine
        if pomo.running {
            let rem = max(0, Int(ceil(pomo.endsAt.timeIntervalSince(d))))
            if rem != pomo.remaining { pomo.remaining = rem }
            if rem == 0 { finishPhase() }
        }

        // Working-on task timer (the system notification is scheduled separately in startTask)
        if let task = activeTask, !task.overdue, d >= task.endsAt {
            activeTask?.overdue = true
        }
    }

    private func finishPhase() {
        let finished = pomo
        pomo.running = false
        pomo.remaining = 0
        if finished.isFocus { pomo.done = finished.cycle }
        alarm = finished.isFocus
            ? .focusDone(cycle: finished.cycle)
            : .breakDone(nextCycle: finished.cycle % 4 + 1)
        Alerts.play(alertType)
    }

    // MARK: - Pomodoro actions

    func start() {
        pomo.running = true
        pomo.endsAt = Date().addingTimeInterval(TimeInterval(pomo.remaining))
    }

    func pause() {
        pomo.remaining = max(0, Int(ceil(pomo.endsAt.timeIntervalSinceNow)))
        pomo.running = false
    }

    func reset() {
        pomo.running = false
        pomo.remaining = pomo.total
    }

    private func begin(_ phase: PomoPhase, cycle: Int, done: Int) {
        let total = phase.length
        pomo = Pomodoro(phase: phase, cycle: cycle, done: done, running: true,
                        endsAt: Date().addingTimeInterval(TimeInterval(total)),
                        remaining: total, total: total)
    }

    func alarmPrimary() {
        guard let alarm else { return }
        switch alarm {
        case .focusDone(let cycle):
            begin(cycle == 4 ? .long : .short, cycle: pomo.cycle, done: pomo.done)
        case .breakDone:
            begin(.focus, cycle: pomo.cycle % 4 + 1, done: pomo.cycle == 4 ? 0 : pomo.done)
        }
        self.alarm = nil
        collapse()
    }

    func alarmSecondary() {
        let c = pomo.cycle
        pomo = Pomodoro(phase: .focus, cycle: c % 4 + 1, done: c == 4 ? 0 : pomo.done)
        alarm = nil
        collapse()
    }

    // MARK: - Reminders / Inbox

    func addReminder(title: String, due: Date?) {
        reminders.append(Reminder(title: title, due: due))
    }

    func addInbox(_ text: String) {
        inbox.insert(InboxItem(text: text, t: Date()), at: 0)
    }

    func completeInbox(_ id: UUID) {
        inbox.removeAll { $0.id == id }
    }

    /// Turns an inbox thought into a reminder; falls back to tomorrow 9 AM when no time is mentioned.
    func remind(_ item: InboxItem) {
        let p = ReminderParser.parse(item.text, now: Date())
        let due = p.due ?? {
            let cal = Calendar.current
            let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            return cal.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        }()
        addReminder(title: p.title.isEmpty ? item.text : p.title, due: due)
        completeInbox(item.id)
    }

    // MARK: - Snips

    func capture() {
        hover = false
        clearInputFocus()
        captureHandler?(snipMode)
    }

    func finishCapture(_ rect: CGRect, screen: CGSize) {
        capturing = false
        snips = Array(([Snip(rect: rect, screen: screen, t: Date())] + snips).prefix(4))
    }

    func deleteSnip(_ id: UUID) {
        snips.removeAll { $0.id == id }
    }

    // MARK: - Up Next

    func deleteReminder(_ id: UUID) {
        reminders.removeAll { $0.id == id }
    }

    // MARK: - Working on

    func addTask(_ task: WorkTask) {
        tasks = tasks.filter { $0.title.caseInsensitiveCompare(task.title) != .orderedSame } + [task]
    }

    func removeTask(_ id: UUID) {
        tasks.removeAll { $0.id == id }
    }

    func startTask(_ task: WorkTask, since: Date = Date()) {
        let active = ActiveTask(title: task.title, min: task.min, since: since)
        activeTask = active
        TaskNotifier.schedule(title: active.title, minutes: active.min, at: active.endsAt)
    }

    func finishTask() {
        activeTask = nil
        TaskNotifier.cancel()
    }

    // MARK: - Prototype controls (menu bar, DEBUG builds)

    func simulateTimerEnd() {
        pomo.running = true
        pomo.endsAt = Date().addingTimeInterval(3)
        pomo.remaining = 3
    }

    /// Starts the last task with only 6 seconds of its planned time left.
    func simulateTaskEnding() {
        guard let task = tasks.last else { return }
        startTask(task, since: Date().addingTimeInterval(-Double(task.min * 60 - 6)))
    }

    // MARK: - Hover / focus

    func pointerEntered() {
        leaveTask?.cancel()
        enterTask?.cancel()
        enterTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(80))
            guard !Task.isCancelled else { return }
            self?.hover = true
        }
    }

    func pointerExited() {
        enterTask?.cancel()
        leaveTask?.cancel()
        leaveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(320))
            guard !Task.isCancelled else { return }
            self?.hover = false
        }
    }

    /// Right-click on the notch jumps straight to Settings.
    func openSettings() {
        leaveTask?.cancel()
        hover = true
        showSettings = true
    }

    func collapse() {
        enterTask?.cancel()
        hover = false
        clearInputFocus()
    }

    func setInputFocus(_ id: String, _ focused: Bool) {
        if focused { focusedInputs.insert(id) } else { focusedInputs.remove(id) }
        syncSettings()
    }

    func clearInputFocus() {
        focusedInputs.removeAll()
        resignInputFocus?()
        syncSettings()
    }

    private func syncSettings() {
        if !hover && !inputFocused { showSettings = false }
    }
}
