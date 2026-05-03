import SwiftUI
import AppKit

// MARK: - NSVisualEffectView bridge

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .behindWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = blendingMode
        v.state = .active
        return v
    }

    func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.material = material
        v.blendingMode = blendingMode
    }
}

// MARK: - Bottom-corners-only rounded shape (top edge is flush with screen)

struct NotchShape: Shape {
    var radius: CGFloat

    var animatableData: CGFloat {
        get { radius }
        set { radius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let r = min(radius, rect.height / 2)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - r))
        p.addArc(center: CGPoint(x: rect.maxX - r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        p.addLine(to: CGPoint(x: rect.minX + r, y: rect.maxY))
        p.addArc(center: CGPoint(x: rect.minX + r, y: rect.maxY - r),
                 radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        p.closeSubpath()
        return p
    }
}

// MARK: - Liquid Glass background

struct GlassBackground: View {
    let radius: CGFloat

    var body: some View {
        ZStack {
            NotchShape(radius: radius)
                .fill(Color.clear)
                .background(
                    VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                        .clipShape(NotchShape(radius: radius))
                )

            // White frosted overlay
            NotchShape(radius: radius)
                .fill(Color.white.opacity(0.07))

            // Top-heavy gradient shine (specular)
            NotchShape(radius: radius)
                .fill(
                    LinearGradient(
                        colors: [.white.opacity(0.13), .white.opacity(0.04), .white.opacity(0.01)],
                        startPoint: .top, endPoint: .bottom
                    )
                )

            // Border: stronger at top, fades down sides
            NotchShape(radius: radius)
                .stroke(
                    LinearGradient(
                        colors: [.white.opacity(0.26), .white.opacity(0.20), .white.opacity(0.18)],
                        startPoint: .top, endPoint: .bottom
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: .black.opacity(0.50), radius: 32, x: 0, y: 24)
        .shadow(color: .black.opacity(0.30), radius: 7,  x: 0, y: 4)
    }
}

// MARK: - Glass button

struct GlassButton: View {
    let size: CGFloat
    let action: () -> Void
    var isAccent = false
    let label: () -> AnyView

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            label()
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(hovering
                              ? Color.white.opacity(isAccent ? 0.26 : 0.14)
                              : Color.white.opacity(isAccent ? 0.16 : 0.07))
                        .overlay(Circle().stroke(Color.white.opacity(isAccent ? 0.28 : 0.12), lineWidth: 1))
                )
                .scaleEffect(hovering ? 1.06 : 1.0)
                .animation(.easeOut(duration: 0.15), value: hovering)
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}

// MARK: - Progress bar

struct SlimProgressBar: View {
    let value: Double    // 0–1
    let color: Color
    var height: CGFloat = 2.5

    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.10))
                Capsule().fill(color)
                    .frame(width: max(0, min(1, value)) * g.size.width)
                    .animation(.easeInOut(duration: 0.6), value: value)
            }
        }
        .frame(height: height)
    }
}

// MARK: - Vertical bar visualizer

struct VizBars: View {
    let playing: Bool
    let color: Color

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(0..<5) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(playing ? color : Color.white.opacity(0.18))
                    .frame(width: 3)
                    .frame(height: playing ? CGFloat.random(in: 6...18) : 4)
                    .animation(
                        playing
                            ? .easeInOut(duration: 0.4 + Double(i) * 0.08)
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.06)
                            : .default,
                        value: playing
                    )
            }
        }
        .frame(width: 20, height: 18, alignment: .bottom)
    }
}
