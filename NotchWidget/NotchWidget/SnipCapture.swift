import AppKit
import SwiftUI

/// Drives the Screen Snip flow: the area-selection overlay and the capture flash.
/// Pixels aren't grabbed yet; the snip records the selected rect.
@MainActor
final class SnipCaptureController {
    private let state: NotchState
    private var overlay: NSPanel?
    private var flash: NSWindow?
    private var keyMonitor: Any?

    init(state: NotchState) {
        self.state = state
    }

    func begin(_ mode: SnipMode, on screen: NSScreen) {
        Task {
            switch mode {
            case .area:
                try? await Task.sleep(for: .milliseconds(150))
                state.capturing = true
                showOverlay(on: screen)
            case .window, .screen:
                try? await Task.sleep(for: .milliseconds(250))
                let s = screen.frame.size
                let rect = mode == .screen
                    ? CGRect(origin: .zero, size: s)
                    : CGRect(x: s.width * 0.18, y: s.height * 0.16, width: s.width * 0.64, height: s.height * 0.66)
                finish(rect, on: screen)
            }
        }
    }

    private func showOverlay(on screen: NSScreen) {
        let panel = KeyablePanel(contentRect: screen.frame, styleMask: [.borderless, .nonactivatingPanel],
                                 backing: .buffered, defer: false)
        panel.level = .screenSaver
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.contentView = NSHostingView(rootView: SnipOverlayView(
            onDone: { [weak self] rect in self?.finish(rect, on: screen) },
            onCancel: { [weak self] in self?.cancel() }
        ))
        panel.makeKeyAndOrderFront(nil)
        overlay = panel

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard event.keyCode == 53 else { return event }   // Esc
            MainActor.assumeIsolated { self?.cancel() }
            return nil
        }
    }

    private func closeOverlay() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
        overlay?.orderOut(nil)
        overlay = nil
        NSCursor.arrow.set()
    }

    private func cancel() {
        closeOverlay()
        state.capturing = false
    }

    private func finish(_ rect: CGRect, on screen: NSScreen) {
        closeOverlay()
        state.finishCapture(rect, screen: screen.frame.size)
        showFlash(on: screen)
    }

    /// `nwFlash`: a white full-screen flash fading from 0.85 to 0 over 0.35s.
    private func showFlash(on screen: NSScreen) {
        let w = NSWindow(contentRect: screen.frame, styleMask: .borderless, backing: .buffered, defer: false)
        w.level = .screenSaver
        w.isOpaque = false
        w.backgroundColor = .white
        w.ignoresMouseEvents = true
        w.isReleasedWhenClosed = false
        w.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        w.alphaValue = 0.85
        w.orderFrontRegardless()
        flash = w
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.35
            ctx.timingFunction = CAMediaTimingFunction(name: .easeOut)
            w.animator().alphaValue = 0
        } completionHandler: {
            w.orderOut(nil)
        }
    }
}

private final class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
}

// MARK: - Drag-to-select overlay

private struct SnipOverlayView: View {
    let onDone: (CGRect) -> Void
    let onCancel: () -> Void

    @State private var start: CGPoint?
    @State private var end: CGPoint?

    private var selection: CGRect? {
        guard let a = start, let b = end else { return nil }
        return CGRect(x: min(a.x, b.x), y: min(a.y, b.y), width: abs(a.x - b.x), height: abs(a.y - b.y))
    }

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .topLeading) {
                if let r = selection {
                    Path { p in
                        p.addRect(CGRect(origin: .zero, size: g.size))
                        p.addRect(r)
                    }
                    .fill(Color.black.opacity(0.32), style: FillStyle(eoFill: true))

                    Rectangle()
                        .stroke(Color.white.opacity(0.85), lineWidth: 1)
                        .frame(width: r.width, height: r.height)
                        .offset(x: r.minX, y: r.minY)

                    Text("\(Int(r.width)) × \(Int(r.height))")
                        .font(NT.font(11, .medium))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.6), radius: 1.5, y: 1)
                        .fixedSize()
                        .frame(width: max(r.width, 1), alignment: .trailing)
                        .offset(x: r.minX, y: r.maxY + 6)
                } else {
                    Color.black.opacity(0.22)
                }

                if start == nil {
                    Text("Drag to select an area · Esc to cancel")
                        .font(NT.font(12, .medium))
                        .foregroundStyle(NT.label)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 7)
                        .background(Capsule().fill(Color(red: 30 / 255, green: 30 / 255, blue: 34 / 255).opacity(0.7)))
                        .background(VisualEffectView(material: .hudWindow).clipShape(Capsule()))
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 0.5))
                        .frame(maxWidth: .infinity)
                        .padding(.top, 64)
                        .allowsHitTesting(false)
                }
            }
        }
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { v in
                    if start == nil { start = v.startLocation }
                    end = v.location
                }
                .onEnded { _ in
                    if let r = selection, r.width > 12, r.height > 12 {
                        onDone(r)
                    } else {
                        start = nil
                        end = nil
                    }
                }
        )
        .onContinuousHover { phase in
            if case .active = phase { NSCursor.crosshair.set() }
        }
    }
}
