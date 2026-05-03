import SwiftUI

struct RAMWidget: View {
    @State private var info = SystemStatsService.shared.ramInfo()
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()

    var barColor: Color {
        let pct = info.used / info.total
        if pct > 0.85 { return Color(hex: 0xFF453A) }
        if pct > 0.65 { return Color(hex: 0xFF9F0A) }
        return Color(hex: 0x64B4FF).opacity(0.85)
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(String(format: "%.1fGB", info.used))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white.opacity(0.90))
                    .monospacedDigit()
                Text("RAM")
                    .font(.system(size: 9.5))
                    .foregroundStyle(.white.opacity(0.36))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            GeometryReader { g in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3).fill(Color.white.opacity(0.09))
                    RoundedRectangle(cornerRadius: 3).fill(barColor)
                        .frame(width: g.size.width * CGFloat(info.used / info.total))
                        .animation(.easeInOut(duration: 0.8), value: info.used)
                }
            }
            .frame(height: 6)

            Text(String(format: "%.0fGB total · %.1fGB free", info.total, info.free))
                .font(.system(size: 9.5))
                .foregroundStyle(.white.opacity(0.26))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .onReceive(timer) { _ in info = SystemStatsService.shared.ramInfo() }
    }
}
