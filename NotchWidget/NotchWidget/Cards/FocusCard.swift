import SwiftUI

/// Pomodoro: 4 × 25-minute focus cycles with 5-minute breaks and a 15-minute long break.
struct FocusCard: View {
    @Environment(NotchState.self) private var state

    var body: some View {
        @Bindable var state = state
        let pomo = state.pomo

        Card {
            CardTitle(icon: .timer, color: NT.orange) { Text("Pomodoro") }
                .help("25 min focus + 5 min break per cycle; a 15 min long break after cycle 4")

            HStack(spacing: 14) {
                Ring(size: 112, stroke: 7, progress: pomo.progress, color: pomo.color) {
                    VStack(spacing: 1) {
                        Text(Fmt.mmss(pomo.remaining))
                            .font(NT.rounded(25))
                            .monospacedDigit()
                            .tracking(-0.5)
                            .foregroundStyle(NT.label)
                        Text(pomo.isFocus ? "Focus" : pomo.phase == .long ? "Long Break" : "Break")
                            .font(NT.font(11, .medium))
                            .foregroundStyle(pomo.isFocus ? NT.secondary : NT.green)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    VStack(alignment: .leading, spacing: 5) {
                        HStack(spacing: 5) {
                            ForEach(0..<4, id: \.self) { i in
                                let done = i < pomo.done
                                let current = i == pomo.cycle - 1 && !done
                                Circle()
                                    .fill(done ? NT.orange : .clear)
                                    .overlay(Circle().strokeBorder(done || current ? NT.orange : NT.track, lineWidth: 1.5))
                                    .frame(width: 9, height: 9)
                            }
                        }
                        Text("Cycle \(pomo.cycle) of 4 · \(pomo.phase.length / 60) min \(pomo.isFocus ? "focus" : "break")")
                            .font(NT.font(11))
                            .foregroundStyle(NT.secondary)
                    }

                    HStack(spacing: 6) {
                        if pomo.running {
                            Btn(variant: .glass, icon: .pause, title: "Pause", stretch: true) { state.pause() }
                        } else {
                            Btn(variant: .prom, icon: .play, title: pomo.idle ? "Start" : "Resume", stretch: true) { state.start() }
                        }
                        Btn(variant: .glass, icon: .reset) { state.reset() }
                            .disabled(pomo.idle)
                            .help("Reset")
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Break alert")
                            .font(NT.font(10.5))
                            .foregroundStyle(NT.tertiary)
                        Segmented(options: [
                            SegOption(value: AlertType.sound, label: "Sound", icon: .speaker),
                            SegOption(value: AlertType.haptic, label: "Watch", icon: .watch, help: "Haptic on Apple Watch"),
                        ], value: $state.alertType)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(maxHeight: .infinity)
        }
    }
}
