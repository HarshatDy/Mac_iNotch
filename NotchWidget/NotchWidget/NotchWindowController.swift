import AppKit
import SwiftUI

// MARK: - Transparent panel that sits over the notch

final class NotchPanel: NSPanel {
    init() {
        super.init(contentRect: .zero, styleMask: [.borderless, .nonactivatingPanel],
                   backing: .buffered, defer: false)
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        ignoresMouseEvents = true
        becomesKeyOnlyIfNeeded = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
    }

    // Key status lets the Up Next / Inbox / Nudge fields take typing without activating the app.
    override var canBecomeKey: Bool  { true }
    override var canBecomeMain: Bool { false }
}

// MARK: - Window controller

@MainActor
final class NotchWindowController: NSWindowController {
    /// Room for the largest panel (800 × ~510) plus its shadow.
    private static let canvas = CGSize(width: 960, height: 640)

    private let state: NotchState
    private let snipper: SnipCaptureController
    private var screen: NSScreen
    private var monitors: [Any] = []
    private var observers: [NSObjectProtocol] = []
    private var pointerInside = false

    init(state: NotchState) {
        self.state = state
        self.snipper = SnipCaptureController(state: state)
        self.screen = Self.preferredScreen()
        let panel = NotchPanel()
        super.init(window: panel)

        let host = NSHostingView(rootView: NotchRootView(state: state))
        host.sizingOptions = []
        panel.contentView = host

        state.resignInputFocus = { [weak panel] in _ = panel?.makeFirstResponder(nil) }
        state.captureHandler = { [weak self] mode in
            guard let self else { return }
            self.snipper.begin(mode, on: self.screen)
        }

        layoutForScreen()
        installMonitors()
        observeGeometry()
    }

    required init?(coder: NSCoder) { fatalError() }

    deinit {
        monitors.forEach(NSEvent.removeMonitor)
        observers.forEach(NotificationCenter.default.removeObserver)
    }

    // MARK: Screen + physical notch

    private static func preferredScreen() -> NSScreen {
        NSScreen.screens.first { $0.safeAreaInsets.top > 0 } ?? NSScreen.main ?? NSScreen.screens[0]
    }

    private func layoutForScreen() {
        screen = Self.preferredScreen()
        let f = screen.frame

        if screen.safeAreaInsets.top > 0,
           let left = screen.auxiliaryTopLeftArea, let right = screen.auxiliaryTopRightArea {
            state.hwWidth = f.width - left.width - right.width
            state.hwHeight = screen.safeAreaInsets.top
        } else {
            state.hwWidth = 184
            state.hwHeight = 32
        }
        state.screenSize = f.size
        state.wallpaper = NSWorkspace.shared.desktopImageURL(for: screen).flatMap(Self.thumbnail)

        let w = min(f.width, Self.canvas.width), h = Self.canvas.height
        window?.setFrame(CGRect(x: f.midX - w / 2, y: f.maxY - h, width: w, height: h), display: true)
        window?.orderFrontRegardless()
    }

    /// Downsampled wallpaper for snip thumbnails.
    private static func thumbnail(_ url: URL) -> NSImage? {
        guard let src = CGImageSourceCreateWithURL(url as CFURL, nil),
              let cg = CGImageSourceCreateThumbnailAtIndex(src, 0, [
                  kCGImageSourceCreateThumbnailFromImageAlways: true,
                  kCGImageSourceThumbnailMaxPixelSize: 1280,
              ] as CFDictionary)
        else { return nil }
        return NSImage(cgImage: cg, size: .zero)
    }

    // MARK: Pointer tracking
    //
    // The panel ignores the mouse except while the pointer is over the glass shell, so
    // clicks anywhere else fall through to the apps underneath.

    private func installMonitors() {
        let moves: NSEvent.EventTypeMask = [.mouseMoved, .leftMouseDragged, .rightMouseDragged]
        if let m = NSEvent.addGlobalMonitorForEvents(matching: moves, handler: { [weak self] _ in
            MainActor.assumeIsolated { self?.updatePointer() }
        }) { monitors.append(m) }
        if let m = NSEvent.addLocalMonitorForEvents(matching: moves, handler: { [weak self] event in
            MainActor.assumeIsolated { self?.updatePointer() }
            return event
        }) { monitors.append(m) }

        // Right-click on the notch opens Settings.
        if let m = NSEvent.addLocalMonitorForEvents(matching: .rightMouseDown, handler: { [weak self] event in
            let target = event.window
            let handled = MainActor.assumeIsolated { () -> Bool in
                guard let self, target === self.window else { return false }
                self.state.openSettings()
                return true
            }
            return handled ? nil : event
        }) { monitors.append(m) }

        let nc = NotificationCenter.default
        observers.append(nc.addObserver(forName: NSWindow.didResignKeyNotification, object: window, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.state.clearInputFocus() }
        })
        observers.append(nc.addObserver(forName: NSApplication.didChangeScreenParametersNotification, object: nil, queue: .main) { [weak self] _ in
            MainActor.assumeIsolated { self?.layoutForScreen() }
        })
    }

    private func updatePointer() {
        let p = NSEvent.mouseLocation
        let f = screen.frame
        let shell = CGRect(x: f.midX - state.width / 2, y: f.maxY - state.height,
                           width: state.width, height: state.height + 1)
        let inside = shell.contains(p) && !state.capturing

        window?.ignoresMouseEvents = !inside
        guard inside != pointerInside else { return }
        pointerInside = inside
        if inside { state.pointerEntered() } else { state.pointerExited() }
    }

    /// Re-evaluate the hit area whenever the shell changes size under a still pointer.
    private func observeGeometry() {
        withObservationTracking {
            _ = state.width
            _ = state.height
            _ = state.capturing
        } onChange: { [weak self] in
            Task { @MainActor in
                self?.updatePointer()
                self?.observeGeometry()
            }
        }
    }
}
