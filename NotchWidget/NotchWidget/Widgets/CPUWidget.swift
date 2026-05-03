import SwiftUI

struct CPUWidget: View {
    @State private var history: [Double] = Array(repeating: 0, count: 16)
    @State private var current: Double = 0
    private let timer = Timer.publish(every: 1.8, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 7) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text("\(Int(current))%")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.white.opacity(0.90))
                    .monospacedDigit()
                Text("CPU")
                    .font(.system(size: 9.5))
                    .foregroundStyle(.white.opacity(0.36))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Sparkline(history: history, color: Color(hex: 0x64B4FF))
                .frame(width: 80, height: 40)

            Text("Peak \(Int(history.max() ?? 0))% · \(cpuModel())")
                .font(.system(size: 9.5))
                .foregroundStyle(.white.opacity(0.26))
                .lineLimit(1)
        }
        .onReceive(timer) { _ in
            current = SystemStatsService.shared.cpuUsage()
            history = history.dropFirst() + [current]
        }
        .onAppear {
            current = SystemStatsService.shared.cpuUsage()
            history = Array(repeating: current, count: 16)
        }
    }

    private func cpuModel() -> String {
        var size: size_t = 0
        sysctlbyname("machdep.cpu.brand_string", nil, &size, nil, 0)
        var brand = [CChar](repeating: 0, count: size)
        sysctlbyname("machdep.cpu.brand_string", &brand, &size, nil, 0)
        let full = String(cString: brand)
        // e.g. "Apple M3 Pro" → "M3 Pro"
        return full.replacingOccurrences(of: "Apple ", with: "")
    }
}

struct Sparkline: View {
    let history: [Double]
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            guard history.count > 1 else { return }
            let W = size.width
            let H = size.height
            let maxV = max(history.max() ?? 1, 1)

            var linePath = Path()
            var fillPath = Path()

            for (i, v) in history.enumerated() {
                let x = CGFloat(i) / CGFloat(history.count - 1) * W
                let y = H - (CGFloat(v) / CGFloat(maxV)) * H
                if i == 0 {
                    linePath.move(to: CGPoint(x: x, y: y))
                    fillPath.move(to: CGPoint(x: 0, y: H))
                    fillPath.addLine(to: CGPoint(x: x, y: y))
                } else {
                    linePath.addLine(to: CGPoint(x: x, y: y))
                    fillPath.addLine(to: CGPoint(x: x, y: y))
                }
            }
            fillPath.addLine(to: CGPoint(x: W, y: H))
            fillPath.closeSubpath()

            ctx.fill(fillPath, with: .linearGradient(
                Gradient(colors: [color.opacity(0.45), color.opacity(0.02)]),
                startPoint: CGPoint(x: 0, y: 0), endPoint: CGPoint(x: 0, y: H)
            ))
            ctx.stroke(linePath, with: .color(color.opacity(0.70)),
                       style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round))
        }
    }
}
