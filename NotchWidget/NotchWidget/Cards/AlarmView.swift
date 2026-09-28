import SwiftUI

/// Shown when a focus session or break ends, or a timed reminder comes due.
struct AlarmView: View {
    let alarm: Alarm

    var body: some View {
        switch alarm {
        case .focusDone(let cycle):
            PomodoroAlarmView(focusDone: true,
                              subtitle: "Cycle \(cycle) of 4 done. Take a \(cycle == 4 ? "15" : "5")-minute break.")
        case .breakDone(let nextCycle):
            PomodoroAlarmView(focusDone: false, subtitle: "Ready for cycle \(nextCycle) of 4?")
        case .reminder(_, let title):
            ReminderAlarmView(title: title)
        }
    }
}

private struct PomodoroAlarmView: View {
    @Environment(NotchState.self) private var state
    let focusDone: Bool
    let subtitle: String

    var body: some View {
        let color = focusDone ? NT.orange : NT.green

        HStack(spacing: 16) {
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
                AlertFeedbackLabel()
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

/// A timed Up Next reminder has come due.
private struct ReminderAlarmView: View {
    @Environment(NotchState.self) private var state
    let title: String

    var body: some View {
        HStack(spacing: 16) {
            Ring(size: 64, stroke: 6, progress: 1, color: NT.blue) {
                Icon(name: .bell, size: 24, color: NT.blue, stroke: 2.4)
            }

            VStack(alignment: .leading, spacing: 0) {
                Text("Reminder")
                    .font(NT.font(13))
                    .foregroundStyle(NT.secondary)
                Marquee(text: title)
                    .font(NT.font(17, .semibold))
                    .tracking(-0.34)
                    .foregroundStyle(NT.label)
                    .padding(.top, 2)
                AlertFeedbackLabel()
                    .padding(.top, 6)
            }
            .lineLimit(1)
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 8) {
                Btn(variant: .glass, title: "Snooze \(NotchState.snoozeMinutes)m") { state.alarmSecondary() }
                Btn(variant: .prom, title: "Done") { state.alarmPrimary() }
            }
        }
        .padding(.horizontal, 22)
        .frame(maxHeight: .infinity)
    }
}

private struct AlertFeedbackLabel: View {
    @Environment(NotchState.self) private var state

    var body: some View {
        let sound = state.alertType == .sound
        HStack(spacing: 5) {
            Icon(name: sound ? .speaker : .watch, size: 12, stroke: 2).pulsing(1.2)
            Text(sound ? "Playing chime" : "Tapping your Apple Watch")
        }
        .font(NT.font(11, .medium))
        .foregroundStyle(NT.tertiary)
    }
}
