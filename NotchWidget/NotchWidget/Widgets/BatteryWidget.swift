import SwiftUI

struct BatteryWidget: View {
    @State private var info = BatteryService.shared.snapshot()
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var statusColor: Color {
        if info.charging { return Color(hex: 0x30D158) }
        if info.percentage < 20 { return Color(hex: 0xFF453A) }
        if info.percentage < 50 { return Color(hex: 0xFF9F0A) }
        return Color(hex: 0x30D158)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                BatteryIcon(percentage: info.percentage, color: statusColor)

                VStack(alignment: .leading, spacing: 1) {
                    Text("\(Int(info.percentage))%")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(statusColor)
                        .monospacedDigit()

                    Text(info.charging ? "⚡ Charging" : info.timeRemaining)
                        .font(.system(size: 9.5))
                        .foregroundStyle(.white.opacity(0.36))
                }
            }

            // 10-segment bar
            HStack(spacing: 2.5) {
                ForEach(0..<10) { i in
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(i < Int(info.percentage / 10) ? statusColor : Color.white.opacity(0.09))
                        .frame(height: 5)
                        .animation(.easeInOut(duration: 0.4), value: info.percentage)
                }
            }

            Text("MacBook Pro · \(info.charging ? "AC" : "Battery")")
                .font(.system(size: 9.5))
                .foregroundStyle(.white.opacity(0.26))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onReceive(timer) { _ in info = BatteryService.shared.snapshot() }
    }
}

private struct BatteryIcon: View {
    let percentage: Double
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            let body = CGRect(x: 0.5, y: 0.5, width: 24, height: 13)
            let tip  = CGRect(x: 25, y: 4, width: 2.5, height: 5)
            let fill = CGRect(x: 2, y: 2, width: max(0, 20 * percentage / 100), height: 9)

            ctx.stroke(Path(roundedRect: body, cornerRadius: 3.5), with: .color(.white.opacity(0.4)), lineWidth: 1)
            ctx.fill(Path(roundedRect: tip, cornerRadius: 1.5), with: .color(.white.opacity(0.3)))
            ctx.fill(Path(roundedRect: fill, cornerRadius: 2), with: .color(color))
        }
        .frame(width: 28, height: 14)
    }
}
