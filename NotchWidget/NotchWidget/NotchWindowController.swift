import AppKit
import SwiftUI

// MARK: - Transparent panel that sits at the notch position

final class NotchPanel: NSPanel {

    static let windowWidth:  CGFloat = 1000
    static let windowHeight: CGFloat = 280

    init(screen: NSScreen) {
        let w = NotchPanel.windowWidth
        let h = NotchPanel.windowHeight
        let x = screen.frame.origin.x + (screen.frame.width - w) / 2
        let y = screen.frame.maxY - h
        super.init(
            contentRect: CGRect(x: x, y: y, width: w, height: h),
            styleMask:   [.borderless, .nonactivatingPanel],
            backing:     .buffered,
            defer:       false
        )
        level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.mainMenuWindow)) + 2)
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        isMovable = false
        acceptsMouseMovedEvents = true
        collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary, .ignoresCycle]
    }

    override var canBecomeKey: Bool  { false }
    override var canBecomeMain: Bool { false }
}

// MARK: - Passthrough container: only forwards hit-tests over the glass panel

final class PassthroughContainerView: NSView {
    private let state: NotchState
    private let hostingView: NSHostingView<NotchRootView>

    init(state: NotchState, frame: NSRect) {
        self.state = state
        self.hostingView = NSHostingView(rootView: NotchRootView(state: state))
        super.init(frame: frame)

        hostingView.frame = frame
        hostingView.autoresizingMask = [.width, .height]
        addSubview(hostingView)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func hitTest(_ point: NSPoint) -> NSView? {
        let pw = state.notchWidth
        let ph = state.notchHeight

        // NSView default coordinate system: y=0 at bottom-left.
        // The glass panel occupies top-center of the window.
        // In screen/window coords the "top" of the view is at y = frame.height.
        let px = (bounds.width - pw) / 2
        let py = bounds.height - ph   // bottom of glass panel in view coords
        let panelRect = CGRect(x: px, y: py, width: pw, height: ph)

        guard panelRect.contains(point) else { return nil }
        return hostingView.hitTest(point)
    }
}

// MARK: - Window controller

@MainActor
final class NotchWindowController: NSWindowController {
    private let state: NotchState

    init(state: NotchState) {
        self.state = state
        let screen = NSScreen.main ?? NSScreen.screens[0]
        let panel  = NotchPanel(screen: screen)
        super.init(window: panel)

        let containerFrame = CGRect(
            x: 0, y: 0,
            width:  NotchPanel.windowWidth,
            height: NotchPanel.windowHeight
        )
        panel.contentView = PassthroughContainerView(state: state, frame: containerFrame)
    }

    required init?(coder: NSCoder) { fatalError() }
}
