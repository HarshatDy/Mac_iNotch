import SwiftUI

/// "Up Next": the next reminder, two more after it, and a natural-language quick-add field.
struct RemindersCard: View {
    @Environment(NotchState.self) private var state
    @State private var text = ""
    @State private var saved = false

    private var parsed: ParsedReminder? {
        text.trimmingCharacters(in: .whitespaces).isEmpty ? nil : ReminderParser.parse(text, now: state.now)
    }

    var body: some View {
        let now = state.now
        let upcoming = state.upcomingReminders
        let parsedDue = parsed?.due

        Card {
            CardTitle(icon: .bell, color: NT.blue) {
                Text("Up Next")
            } right: {
                if saved {
                    HStack(spacing: 3) {
                        Icon(name: .check, size: 11, stroke: 2.4)
                        Text("Saved")
                    }
                    .fontWeight(.medium)
                    .foregroundStyle(NT.green)
                    .transition(.opacity.animation(.easeOut(duration: 0.2)))
                }
            }

            if let next = upcoming.first, let due = next.due {
                NextReminder(reminder: next, due: due)
            } else {
                Text("No upcoming reminders")
                    .font(NT.font(13))
                    .foregroundStyle(NT.tertiary)
            }

            VStack(alignment: .leading, spacing: 5) {
                ForEach(upcoming.dropFirst().prefix(2)) { r in
                    LaterReminderRow(reminder: r)
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .clipped()

            ZStack(alignment: .trailing) {
                NTextField(id: "reminder", placeholder: "Drink water 5pm", text: $text,
                           trailingInset: parsedDue != nil ? 132 : 10, onSubmit: submit)
                if let parsedDue {
                    HStack(spacing: 4) {
                        Icon(name: .calendar, size: 11, stroke: 2)
                        Text(Fmt.due(parsedDue, now))
                    }
                    .font(NT.font(11, .medium))
                    .foregroundStyle(Color(hex: 0x6CB6FF))
                    .lineLimit(1)
                    .padding(.horizontal, 7)
                    .frame(height: 20)
                    .background(Capsule().fill(NT.blue.opacity(0.22)))
                    .padding(.trailing, 5)
                    .allowsHitTesting(false)
                    .transition(.opacity.animation(.easeOut(duration: 0.15)))
                }
            }
        }
    }

    private func submit() {
        guard let p = parsed, !p.title.isEmpty else { return }
        state.addReminder(title: p.title, due: p.due)
        text = ""
        saved = true
        Task {
            try? await Task.sleep(for: .milliseconds(1600))
            saved = false
        }
    }
}

// MARK: - Rows (hover reveals a delete button)

private struct DeleteReminderButton: View {
    @Environment(NotchState.self) private var state
    let id: UUID
    var size: CGFloat = 22

    var body: some View {
        Button { state.deleteReminder(id) } label: { Icon(name: .xmark, size: size * 0.5, stroke: 2.2) }
            .buttonStyle(MiniButtonStyle(size: size))
            .help("Delete reminder")
    }
}

private struct NextReminder: View {
    @Environment(NotchState.self) private var state
    let reminder: Reminder
    let due: Date
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(reminder.title)
                .font(NT.font(15, .semibold))
                .tracking(-0.22)
                .foregroundStyle(NT.label)
                .lineLimit(1)
                .padding(.trailing, hovering ? 26 : 0)   // keep the title clear of the ✕ while it shows
            Text("\(Text(Fmt.countdown(due, state.now)).fontWeight(.medium).foregroundStyle(NT.orange)) · \(Fmt.time(due))")
                .font(NT.font(12))
                .foregroundStyle(NT.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .overlay(alignment: .topTrailing) {
            DeleteReminderButton(id: reminder.id)
                .opacity(hovering ? 1 : 0)
                .allowsHitTesting(hovering)
        }
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}

private struct LaterReminderRow: View {
    @Environment(NotchState.self) private var state
    let reminder: Reminder
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 8) {
            Text(reminder.title)
                .foregroundStyle(NT.label)
                .frame(maxWidth: .infinity, alignment: .leading)
            if let due = reminder.due {
                Text(Fmt.due(due, state.now))
                    .foregroundStyle(NT.tertiary)
                    .opacity(hovering ? 0 : 1)
            }
        }
        .font(NT.font(12))
        .lineLimit(1)
        .frame(height: 18)
        .contentShape(Rectangle())
        .overlay(alignment: .trailing) {
            DeleteReminderButton(id: reminder.id, size: 18)
                .opacity(hovering ? 1 : 0)
                .allowsHitTesting(hovering)
        }
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}
