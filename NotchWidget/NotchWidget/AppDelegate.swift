import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var windowController: NotchWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        windowController = NotchWindowController(state: NotchState.shared)
        windowController?.showWindow(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        windowController?.close()
    }
}
