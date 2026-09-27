import SwiftUI
import EventKit

struct DayEvent: Identifiable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let color: Color
}

/// Today's timed events from Apple Calendar, kept fresh as the calendar or the day changes.
@Observable
@MainActor
final class CalendarService {
    static let shared = CalendarService()

    enum Access { case notDetermined, granted, denied }

    private(set) var access: Access
    private(set) var events: [DayEvent] = []

    @ObservationIgnored private let store = EKEventStore()
    @ObservationIgnored private var observers: [NSObjectProtocol] = []

    private init() {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess:    access = .granted
        case .notDetermined: access = .notDetermined
        default:             access = .denied
        }

        let nc = NotificationCenter.default
        observers.append(nc.addObserver(forName: .EKEventStoreChanged, object: store, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.reload() }
        })
        observers.append(nc.addObserver(forName: .NSCalendarDayChanged, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.reload() }
        })
        reload()
    }

    func requestAccess() {
        store.requestFullAccessToEvents { [weak self] granted, _ in
            Task { @MainActor in
                self?.access = granted ? .granted : .denied
                self?.reload()
            }
        }
    }

    func openCalendarApp() {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.iCal") else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    func openPrivacySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
            NSWorkspace.shared.open(url)
        }
    }

    func reload() {
        guard access == .granted else {
            events = []
            return
        }
        let cal = Calendar.current
        let start = cal.startOfDay(for: Date())
        let end = cal.date(byAdding: .day, value: 1, to: start) ?? start.addingTimeInterval(86_400)
        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        events = store.events(matching: predicate)
            .filter { !$0.isAllDay }
            .sorted { $0.startDate < $1.startDate }
            .map { e in
                DayEvent(id: "\(e.eventIdentifier ?? UUID().uuidString)-\(e.startDate.timeIntervalSince1970)",
                         title: (e.title?.isEmpty == false ? e.title : nil) ?? "Busy",
                         start: e.startDate,
                         end: e.endDate,
                         color: e.calendar.map { Color(nsColor: $0.color) } ?? NT.blue)
            }
    }
}
