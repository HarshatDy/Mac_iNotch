import SwiftUI

/// Shown when a focus session or break ends.
struct AlarmView: View {
    @Environment(NotchState.self) private var state
    let alarm: Alarm

    var body: some View {
        let focusDone: Bool
        let subtitle: String
        switch alarm {
        case .focusDone(let cycle):
            focusDone = true
            subtitle = "Cycle \(cycle) of 4 done. Take a \(cycle == 4 ? "15" : "5")-minute break."
        case .breakDone(let nextCycle):
            focusDone = false
            subtitle = "Ready for cycle \(nextCycle) of 4?"
        }
        let color = focusDone ? NT.orange : NT.green
        let sound = state.alertType == .sound

        return HStack(spacing: 16) {
            Ring(size: 64, stroke: 6, progress: 1, color: color) {
                Icon(name: focusDone ? .check : .timer, size: 24, color: color, stroke: 2.4)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text(focusDone ? "Focus session complete" : "Break’s over")
                    .font(NT.font(17, .semibold))
                    .tracking(-0.34)
                    .foregroundStyle(NT.label)
                Text(subtitle)
                    .font(NT.font(13))
                    .foregroundStyle(NT.secondary)
                    .padding(.top, 2)
                HStack(spacing: 5) {
                    Icon(name: sound ? .speaker : .watch, size: 12, stroke: 2).pulsing(1.2)
                    Text(sound ? "Playing chime" : "Tapping your Apple Watch")
                }
                .font(NT.font(11, .medium))
                .foregroundStyle(NT.tertiary)
                .padding(.top, 6)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Btn(variant: .glass, title: focusDone ? "Skip" : "Later") { state.alarmSecondary() }
                Btn(variant: .prom, title: focusDone ? "Start Break" : "Start Focus") { state.alarmPrimary() }
            }
        }
        .padding(.horizontal, 22)
        .frame(maxHeight: .infinity)
    }
}
