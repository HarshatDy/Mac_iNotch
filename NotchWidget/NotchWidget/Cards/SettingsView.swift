import SwiftUI

/// Settings panel (gear button or right-click): choose what the resting notch shows.
struct SettingsView: View {
    @Environment(NotchState.self) private var state

    private let options: [(RestingVariant, String, String)] = [
        (.short, "Short bar", "Next reminder and focus minutes beside the notch."),
        (.progress, "Progress outline", "Just the notch. The running timer traces its edge."),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Button { state.showSettings = false } label: { Icon(name: .chevronLeft, size: 12, stroke: 2.4) }
                    .buttonStyle(MiniButtonStyle())
                    .help("Back")
                Text("Settings")
                    .font(NT.font(13, .semibold))
                    .foregroundStyle(NT.label)
            }

            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Resting notch")
                        .font(NT.font(13, .semibold))
                        .foregroundStyle(NT.label)
                    Text("What the notch shows when you’re not hovering over it.")
                        .font(NT.font(11))
                        .foregroundStyle(NT.secondary)
                }
                HStack(alignment: .top, spacing: 10) {
                    ForEach(options, id: \.0) { value, title, detail in
                        VariantOption(kind: value, title: title, detail: detail,
                                      isOn: state.variant == value) { state.variant = value }
                    }
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.055)))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))

            ReminderSyncSection()

            Spacer(minLength: 0)
        }
    }
}

private struct VariantOption: View {
    let kind: RestingVariant
    let title: String
    let detail: String
    let isOn: Bool
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 9) {
                NotchPreview(kind: kind)
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(isOn ? Color.white : .clear)
                        .overlay(Circle().strokeBorder(isOn ? NT.blue : Color.white.opacity(0.3), lineWidth: isOn ? 4.5 : 1))
                        .frame(width: 14, height: 14)
                        .padding(.top, 1)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(NT.font(13, .medium))
                            .foregroundStyle(NT.label)
                        Text(detail)
                            .font(NT.font(11))
                            .foregroundStyle(NT.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.bottom, 2)
            }
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 14).fill(background))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(isOn ? NT.blue : Color.white.opacity(0.1), lineWidth: isOn ? 2 : 0.5)
            )
            .contentShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.2), value: isOn)
    }

    private var background: Color {
        if isOn { return NT.blue.opacity(0.08) }
        return Color.white.opacity(hovering ? 0.07 : 0.04)
    }
}

/// Miniature of each resting variant.
private struct NotchPreview: View {
    let kind: RestingVariant
    private let nw: CGFloat = 72, nh: CGFloat = 18

    var body: some View {
        ZStack(alignment: .top) {
            RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.28))
            if kind == .short { shortBar } else { outline }
        }
        .frame(height: 60)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
    }

    private var shortBar: some View {
        ZStack {
            NotchShape(radius: 9).fill(Color(red: 58 / 255, green: 58 / 255, blue: 64 / 255).opacity(0.95))
            HStack(spacing: 0) {
                HStack(spacing: 3) {
                    Icon(name: .bell, size: 8, color: NT.orange, stroke: 2.4)
                    Text("40m").foregroundStyle(NT.label)
                }
                Spacer(minLength: 0)
                HStack(spacing: 3) {
                    Text("18m").foregroundStyle(NT.orange)
                    Ring(size: 8, stroke: 1.8, progress: 0.3, color: NT.orange)
                }
            }
            .font(NT.rounded(8.5))
            .padding(.horizontal, 7)
            NotchShape(radius: 7).fill(Color.black).frame(width: nw)
        }
        .frame(width: nw + 76, height: nh)
    }

    private var outline: some View {
        let path = Self.outlinePath(nw: nw, nh: nh)
        return ZStack(alignment: .topLeading) {
            NotchShape(radius: 7).fill(Color.black)
                .frame(width: nw, height: nh)
                .offset(x: 4)
            path.stroke(Color.white.opacity(0.16), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            path.trim(from: 0, to: 0.62).stroke(NT.orange, style: StrokeStyle(lineWidth: 2, lineCap: .round))
        }
        .frame(width: nw + 8, height: nh + 4, alignment: .topLeading)
    }

    private static func outlinePath(nw: CGFloat, nh: CGFloat) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 2, y: 0))
        p.addArc(tangent1End: CGPoint(x: 2, y: nh + 2), tangent2End: CGPoint(x: nw + 6, y: nh + 2), radius: 9)
        p.addArc(tangent1End: CGPoint(x: nw + 6, y: nh + 2), tangent2End: CGPoint(x: nw + 6, y: 0), radius: 9)
        p.addLine(to: CGPoint(x: nw + 6, y: 0))
        return p
    }
}

/// Status of the Apple Reminders bridge that carries alerts to iPhone and Apple Watch.
private struct ReminderSyncSection: View {
    private let sync = ReminderSync.shared

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("iPhone & Apple Watch")
                        .font(NT.font(13, .semibold))
                        .foregroundStyle(NT.label)
                    if sync.isActive {
                        Circle().fill(NT.green).frame(width: 6, height: 6)
                        Text("Syncing").font(NT.font(11, .medium)).foregroundStyle(NT.green)
                    }
                }
                Text(detail)
                    .font(NT.font(11))
                    .foregroundStyle(NT.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            switch sync.access {
            case .notDetermined:
                Btn(variant: .prom, small: true, title: "Turn On") { sync.requestAccess() }
            case .denied:
                Btn(variant: .glass, small: true, title: "Allow in Settings") { sync.openPrivacySettings() }
            case .granted:
                EmptyView()
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.055)))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
    }

    private var detail: String {
        switch sync.access {
        case .notDetermined:
            return "Sync Up Next, Brain Dump and timer alerts through Apple Reminders so they reach your iPhone and Watch."
        case .denied:
            return "Notcheee needs access to Reminders to send alerts to your iPhone and Watch."
        case .granted:
            if let error = sync.lastError, !sync.ready { return error }
            return "Via Apple Reminders: “\(ReminderSync.upNextName)”, “\(ReminderSync.brainDumpName)” and “\(ReminderSync.timersName)” lists. Tip: turn off Reminders notifications on this Mac to avoid double alerts."
        }
    }
}
