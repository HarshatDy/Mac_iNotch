import SwiftUI

struct ClockWidget: View {
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 7) {
            AnalogClock(date: now)
                .frame(width: 60, height: 60)

            VStack(spacing: 1) {
                Text(now, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute().second())
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.88))
                    .monospacedDigit()

                Text(now, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day())
                    .font(.system(size: 9.5))
                    .foregroundStyle(.white.opacity(0.36))
            }
        }
        .onReceive(timer) { now = $0 }
    }
}

private struct AnalogClock: View {
    let date: Date

    private var components: (h: Double, m: Double, s: Double) {
        let c = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        let h = Double(c.hour ?? 0) + Double(c.minute ?? 0) / 60
        let m = Double(c.minute ?? 0) + Double(c.second ?? 0) / 60
        let s = Double(c.second ?? 0)
        return (h, m, s)
    }

    var body: some View {
        Canvas { ctx, size in
            let r = size.width / 2
            let cx = size.width / 2
            let cy = size.height / 2
            let c = components

            // Face
            ctx.fill(Path(ellipseIn: CGRect(x: 0, y: 0, width: size.width, height: size.height)),
                     with: .color(.white.opacity(0.04)))
            ctx.stroke(Path(ellipseIn: CGRect(x: 0.5, y: 0.5, width: size.width - 1, height: size.height - 1)),
                       with: .color(.white.opacity(0.10)), lineWidth: 0.8)

            // Tick marks
            for i in 0..<12 {
                let a = Double(i) * .pi / 6 - .pi / 2
                let isMajor = i % 3 == 0
                let inner: Double = isMajor ? r - 6 : r - 4
                let outer: Double = r - 1.5
                var tick = Path()
                tick.move(to: CGPoint(x: cx + inner * cos(a), y: cy + inner * sin(a)))
                tick.addLine(to: CGPoint(x: cx + outer * cos(a), y: cy + outer * sin(a)))
                ctx.stroke(tick, with: .color(.white.opacity(0.22)),
                           style: StrokeStyle(lineWidth: isMajor ? 1.2 : 0.6, lineCap: .round))
            }

            // Hands
            drawHand(ctx: ctx, cx: cx, cy: cy, angle: (c.h / 12) * 2 * .pi - .pi / 2,
                     length: 15, width: 2.2, color: .white.opacity(0.90))
            drawHand(ctx: ctx, cx: cx, cy: cy, angle: (c.m / 60) * 2 * .pi - .pi / 2,
                     length: 20, width: 1.6, color: .white.opacity(0.78))
            drawHand(ctx: ctx, cx: cx, cy: cy, angle: (c.s / 60) * 2 * .pi - .pi / 2,
                     length: 22, width: 0.9, color: Color(hex: 0xFF453A))

            // Center dot
            ctx.fill(Path(ellipseIn: CGRect(x: cx - 1.8, y: cy - 1.8, width: 3.6, height: 3.6)),
                     with: .color(.white.opacity(0.9)))
        }
    }

    private func drawHand(ctx: GraphicsContext, cx: Double, cy: Double,
                          angle: Double, length: Double, width: Double, color: Color) {
        var p = Path()
        p.move(to: CGPoint(x: cx, y: cy))
        p.addLine(to: CGPoint(x: cx + length * cos(angle), y: cy + length * sin(angle)))
        ctx.stroke(p, with: .color(color),
                   style: StrokeStyle(lineWidth: width, lineCap: .round))
    }
}
