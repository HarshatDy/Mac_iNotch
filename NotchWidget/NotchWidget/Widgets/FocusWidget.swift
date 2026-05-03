import SwiftUI

struct FocusWidget: View {
    let state: NotchState

    var body: some View {
        VStack(spacing: 9) {
            HStack {
                VStack(alignment: .leading, spacing: 1) {
                    Text("Focus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text(state.dndEnabled ? "On · \(state.dndUntil)" : "Off")
                        .font(.system(size: 9.5))
                        .foregroundStyle(state.dndEnabled ? Color(hex: 0xFF9F0A) : .white.opacity(0.30))
                }

                Spacer()

                Button(action: { state.dndEnabled.toggle() }) {
                    Text(state.dndEnabled ? "🌙" : "🔔")
                        .font(.system(size: 15))
                        .frame(width: 32, height: 32)
                        .background(
                            RoundedRectangle(cornerRadius: 9)
                                .fill(state.dndEnabled
                                      ? Color(hex: 0xFF9F0A).opacity(0.22)
                                      : Color.white.opacity(0.07))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 9)
                                        .stroke(state.dndEnabled
                                                ? Color(hex: 0xFF9F0A).opacity(0.40)
                                                : Color.white.opacity(0.12), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
                .animation(.easeInOut(duration: 0.2), value: state.dndEnabled)
            }

            if state.dndEnabled {
                HStack(spacing: 4) {
                    ForEach(["1 hour", "Tonight", "All Day"], id: \.self) { opt in
                        let sel = state.dndUntil == opt
                        Button(action: { state.dndUntil = opt }) {
                            Text(opt)
                                .font(.system(size: 8.5))
                                .foregroundStyle(sel ? Color(hex: 0xFF9F0A) : .white.opacity(0.45))
                                .padding(.vertical, 3)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 5)
                                        .fill(sel ? Color(hex: 0xFF9F0A).opacity(0.28) : Color.white.opacity(0.07))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 5)
                                                .stroke(sel ? Color(hex: 0xFF9F0A).opacity(0.40) : Color.white.opacity(0.09), lineWidth: 1)
                                        )
                                )
                        }
                        .buttonStyle(.plain)
                        .animation(.easeOut(duration: 0.15), value: sel)
                    }
                }
                .transition(.opacity.combined(with: .offset(y: 4)))
            }
        }
        .animation(.easeOut(duration: 0.18), value: state.dndEnabled)
    }
}
