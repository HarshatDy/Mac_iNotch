import SwiftUI

struct ConfigureView: View {
    let state: NotchState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerRow
            chipGrid
            footerHint
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 10)
    }

    // MARK: - Header

    var headerRow: some View {
        HStack(spacing: 8) {
            // Back arrow
            Button(action: state.closeConfigure) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .overlay(Circle().stroke(Color.white.opacity(0.16), lineWidth: 1))
                        .frame(width: 22, height: 22)
                    Image(systemName: "chevron.left")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.80))
                }
            }
            .buttonStyle(.plain)

            Text("Widgets")
                .font(.system(size: 11.5, weight: .semibold))
                .foregroundStyle(.white.opacity(0.75))

            Spacer()

            // Accent picker
            HStack(spacing: 5) {
                Text("Accent")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.28))

                ForEach(AccentTint.allCases, id: \.rawValue) { tint in
                    Button(action: { state.tweaks.accentTint = tint }) {
                        Circle()
                            .fill(tint.glowColor)
                            .frame(width: 14, height: 14)
                            .overlay(
                                Circle()
                                    .stroke(
                                        state.tweaks.accentTint == tint
                                            ? Color.white.opacity(0.88)
                                            : Color.clear,
                                        lineWidth: 2
                                    )
                            )
                            .shadow(color: state.tweaks.accentTint == tint ? tint.glowColor : .clear, radius: 3)
                    }
                    .buttonStyle(.plain)
                    .animation(.easeOut(duration: 0.15), value: state.tweaks.accentTint == tint)
                }
            }
        }
    }

    // MARK: - Widget chips

    var chipGrid: some View {
        FlowLayout(spacing: 5) {
            ForEach(WidgetID.allCases) { id in
                WidgetChip(id: id, isOn: state.isEnabled(id)) {
                    state.toggleWidget(id)
                }
            }
        }
    }

    // MARK: - Footer

    var footerHint: some View {
        Text("Right-click notch anytime to return here")
            .font(.system(size: 9))
            .foregroundStyle(.white.opacity(0.18))
            .frame(maxWidth: .infinity)
    }
}

// MARK: - Widget chip

struct WidgetChip: View {
    let id: WidgetID
    let isOn: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: id.systemIcon)
                    .font(.system(size: 11))
                    .foregroundStyle(isOn ? .white.opacity(0.88) : .white.opacity(0.35))

                Text(id.label)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(isOn ? .white.opacity(0.88) : .white.opacity(0.35))

                if isOn {
                    Circle()
                        .fill(Color(hex: 0x30D158))
                        .frame(width: 5, height: 5)
                }
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isOn ? Color.white.opacity(0.14) : Color.white.opacity(0.05))
                    .overlay(
                        Capsule()
                            .stroke(isOn ? Color.white.opacity(0.24) : Color.white.opacity(0.09), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.16), value: isOn)
    }
}

// MARK: - Simple flow layout for chips

struct FlowLayout: Layout {
    var spacing: CGFloat = 5

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowH: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > width && x > 0 {
                y += rowH + spacing
                x = 0
                rowH = 0
            }
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
        return CGSize(width: width, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowH: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowH + spacing
                x = bounds.minX
                rowH = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}
