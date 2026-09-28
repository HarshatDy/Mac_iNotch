import AppKit
import UserNotifications

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private var windowController: NotchWindowController?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        windowController = NotchWindowController(state: NotchState.shared)
        windowController?.showWindow(nil)
        setupStatusItem()
        UNUserNotificationCenter.current().delegate = self
        if CalendarService.shared.access == .notDetermined {
            CalendarService.shared.requestAccess()
        }
        ReminderSync.shared.start(state: NotchState.shared)
    }

    /// Show the "Working On" time's-up banner even while the app counts as frontmost.
    /// Reminder notifications are only a backup for when the app isn't running; the notch alarm covers them here.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        notification.request.identifier.hasPrefix(ReminderNotifier.prefix) ? [] : [.banner, .sound]
    }

    func applicationWillTerminate(_ notification: Notification) {
        windowController?.close()
    }

    // MARK: - Menu bar item (Quit, plus the prototype's test controls in DEBUG builds)

    private func setupStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "Notcheee")

        let menu = NSMenu()
        #if DEBUG
        menu.addItem(withTitle: "Prototype controls", action: nil, keyEquivalent: "").isEnabled = false
        menu.addItem(withTitle: "End current timer in 3s", action: #selector(endTimerSoon), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Start last task, ending in 6s", action: #selector(startTaskEndingSoon), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Add reminder due in 5s", action: #selector(reminderDueSoon), keyEquivalent: "").target = self
        menu.addItem(withTitle: "Finish working-on task", action: #selector(finishTask), keyEquivalent: "").target = self
        menu.addItem(.separator())
        #endif
        menu.addItem(withTitle: "Quit Notcheee", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.menu = menu
        statusItem = item
    }

    @objc private func endTimerSoon()     { NotchState.shared.simulateTimerEnd() }
    @objc private func startTaskEndingSoon() { NotchState.shared.simulateTaskEnding() }
    @objc private func finishTask()          { NotchState.shared.finishTask() }
    @objc private func reminderDueSoon()     { NotchState.shared.simulateReminderDue() }
}
