import SwiftUI

// MARK: - Root view embedded in the hosting view

struct NotchRootView: View {
    let state: NotchState

    var body: some View {
        NotchContainerView(state: state)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

// MARK: - Main container with glass panel + state-driven content

struct NotchContainerView: View {
    let state: NotchState

    var body: some View {
        ZStack(alignment: .top) {
            Color.clear

            glassPanel
                .frame(width: state.notchWidth, height: state.notchHeight)
                .animation(notchAnimation,       value: state.notchWidth)
                .animation(notchHeightAnimation, value: state.notchHeight)

            // Ambient glow below glass
            ambientGlow
                .offset(y: state.notchHeight - 4)
                .animation(notchAnimation, value: state.notchHeight)
        }
        .onHover { hovering in
            if hovering { state.handleMouseEnter() }
            else        { state.handleMouseLeave() }
        }
    }

    // MARK: - Glass panel

    var glassPanel: some View {
        ZStack {
            GlassBackground(radius: state.notchRadius)
                .animation(Animation.timingCurve(0.4, 0, 0.2, 1, duration: 0.28), value: state.notchRadius)

            content
                .animation(.easeOut(duration: 0.22), value: state.displayState)
        }
        .clipShape(NotchShape(radius: state.notchRadius))
        .contentShape(NotchShape(radius: state.notchRadius))
        .simultaneousGesture(
            TapGesture(count: 1).onEnded { }  // absorb taps so they don't fall through
        )
        .contextMenu {
            Button("Configure Widgets…") { state.openConfigure() }
        }
    }

    // MARK: - State-driven content

    @ViewBuilder
    var content: some View {
        switch state.displayState {
        case .collapsed:
            CollapsedDotsView(state: state)
                .transition(.opacity)

        case .hoverCompact:
            HoverCompactView(state: state)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: -3)),
                    removal:   .opacity
                ))

        case .expanded:
            ExpandedWidgetsView(state: state)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 4)),
                    removal:   .opacity
                ))

        case .configure:
            ConfigureView(state: state)
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .offset(y: 4)),
                    removal:   .opacity
                ))
        }
    }

    // MARK: - Ambient glow

    var ambientGlow: some View {
        Ellipse()
            .fill(
                RadialGradient(
                    colors: [state.tweaks.accentTint.glowColor.opacity(0.5), .clear],
                    center: .center,
                    startRadius: 0,
                    endRadius: 50
                )
            )
            .frame(width: state.notchWidth * 0.6, height: 30)
            .blur(radius: 6)
            .opacity(state.displayState == .collapsed ? 0.15 : 0.35)
            .animation(notchAnimation, value: state.displayState)
    }
}
