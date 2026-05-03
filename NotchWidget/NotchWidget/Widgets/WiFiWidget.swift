import SwiftUI
import CoreWLAN

struct WiFiWidget: View {
    @State private var info = WiFiInfo.current()
    private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 9) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(Color(hex: 0x0A84FF).opacity(0.18))
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .stroke(Color(hex: 0x0A84FF).opacity(0.30), lineWidth: 1)
                        )
                        .frame(width: 34, height: 34)

                    WiFiIcon()
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text(info.ssid.isEmpty ? "Not connected" : info.ssid)
                        .font(.system(size: 11.5, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(info.ssid.isEmpty ? "Wi-Fi off" : "Connected")
                        .font(.system(size: 9.5))
                        .foregroundStyle(Color(hex: 0x0A84FF))
                }
            }

            HStack {
                StatPill(label: "↓ DL", value: info.downloadMbps)
                StatPill(label: "↑ UL", value: info.uploadMbps)
                StatPill(label: "Ping", value: info.pingMs)
            }
        }
        .onReceive(timer) { _ in info = WiFiInfo.current() }
    }
}

private struct WiFiIcon: View {
    var body: some View {
        Canvas { ctx, _ in
            let arcs: [(r: Double, op: Double)] = [(10, 0.9), (7.5, 0.6), (5, 0.3)]
            for arc in arcs {
                var p = Path()
                p.move(to: CGPoint(x: 8 - arc.r, y: 12 - arc.r * 0.7))
                p.addQuadCurve(
                    to:      CGPoint(x: 8 + arc.r, y: 12 - arc.r * 0.7),
                    control: CGPoint(x: 8,          y: 12 - arc.r * 1.4)
                )
                ctx.stroke(p, with: .color(.white.opacity(arc.op)),
                           style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
            }
            ctx.fill(Path(ellipseIn: CGRect(x: 6.8, y: 10, width: 2.4, height: 2.4)),
                     with: .color(.white.opacity(0.9)))
        }
        .frame(width: 16, height: 12)
    }
}

private struct StatPill: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 1) {
            Text(label).font(.system(size: 9.5)).foregroundStyle(.white.opacity(0.28))
            Text(value).font(.system(size: 9.5, weight: .medium)).foregroundStyle(.white.opacity(0.65))
        }
        .frame(maxWidth: .infinity)
    }
}

struct WiFiInfo {
    var ssid: String = ""
    var downloadMbps: String = "–"
    var uploadMbps: String   = "–"
    var pingMs: String       = "–"

    static func current() -> WiFiInfo {
        var info = WiFiInfo()
        if let iface = CWWiFiClient.shared().interface() {
            info.ssid = iface.ssid() ?? ""
        }
        // Real throughput requires private APIs; using mock values for now
        info.downloadMbps = "142 Mb"
        info.uploadMbps   = "38 Mb"
        info.pingMs        = "4 ms"
        return info
    }
}
