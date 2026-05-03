import SwiftUI

struct MicrophoneWidget: View {
    let state: NotchState
    @State private var level: Double = 0
    private let timer = Timer.publish(every: 0.15, on: .main, in: .common).autoconnect()

    var activeColor: Color { Color(hex: 0x30D158) }

    var body: some View {
        VStack(spacing: 9) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Mic")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(state.micActive ? "Active" : "Muted")
                        .font(.system(size: 9.5))
                        .foregroundStyle(state.micActive ? activeColor : .white.opacity(0.30))
                }

                Spacer()

                Button(action: { state.micActive.toggle() }) {
                    MicIcon(active: state.micActive)
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(state.micActive ? activeColor.opacity(0.18) : Color.white.opacity(0.07))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9)
                                        .stroke(state.micActive ? activeColor.opacity(0.35) : Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )
                        .animation(
                            state.micActive
                                ? .easeInOut(duration: 2).repeatForever(autoreverses: true)
                                : .default,
                            value: state.micActive
                        )
                }
                .buttonStyle(.plain)
            }

            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2).fill(Color.white.opacity(0.08))
                    RoundedRectangle(cornerRadius: 2).fill(activeColor)
                        .frame(width: g.size.width * CGFloat(level / 100))
                        .animation(.easeOut(duration: 0.12), value: level)
                }
            }
            .frame(height: 4)
        }
        .onReceive(timer) { _ in
            level = state.micActive ? Double.random(in: 20...100) : 0
        }
    }
}

private struct MicIcon: View {
    let active: Bool

    var color: Color { active ? Color(hex: 0x30D158) : .white.opacity(0.35) }
    var strokeColor: Color { active ? Color(hex: 0x30D158) : .white.opacity(0.25) }

    var body: some View {
        Canvas { ctx, size in
            let cx = size.width / 2
            // Capsule body
            let cap = CGRect(x: cx - 3, y: 1, width: 6, height: 10)
            ctx.fill(Path(roundedRect: cap, cornerRadius: 3), with: .color(color))
            // Arc
            var arc = Path()
            arc.move(to: CGPoint(x: 1, y: 8))
            arc.addQuadCurve(to: CGPoint(x: 11, y: 8),
                             control: CGPoint(x: 6, y: 13))
            ctx.stroke(arc, with: .color(strokeColor),
                       style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
            // Stand
            var stand = Path()
            stand.move(to: CGPoint(x: cx, y: 13))
            stand.addLine(to: CGPoint(x: cx, y: 15.5))
            stand.move(to: CGPoint(x: 3.5, y: 15.5))
            stand.addLine(to: CGPoint(x: 8.5, y: 15.5))
            ctx.stroke(stand, with: .color(strokeColor),
                       style: StrokeStyle(lineWidth: 1.2, lineCap: .round))
        }
    }
}
