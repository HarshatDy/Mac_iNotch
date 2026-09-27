import SwiftUI

/// "Working On": a list of tasks with planned durations. Picking one starts its timer;
/// when the time runs out the notch glows and a system notification is posted.
struct WorkCard: View {
    @Environment(NotchState.self) private var state
    @State private var adding = false
    @State private var title = ""
    @State private var mins = 15

    private var trimmed: String { title.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        if adding { addForm } else { overview }
    }

    // MARK: Overview

    private var overview: some View {
        Card(spacing: 8) {
            CardTitle(icon: .scope, color: NT.teal) {
                Text("Working On")
            } right: {
                if state.activeTask == nil {
                    Button { adding = true } label: { Icon(name: .plus, size: 12, stroke: 2.2) }
                        .buttonStyle(MiniButtonStyle())
                        .help("Add a task")
                }
            }

            if let task = state.activeTask {
                activeView(task)
            } else {
                Text(state.tasks.isEmpty ? "Add a task, then pick it to start." : "Pick a task to start its timer.")
                    .font(NT.font(11))
                    .foregroundStyle(NT.tertiary)
                // Scrolls once there are more chips than fit, instead of pushing the card out of the grid.
                ScrollView(.vertical) {
                    FlowLayout(spacing: 4) {
                        ForEach(state.tasks) { TaskChip(task: $0) }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollIndicators(.automatic)
                .frame(maxHeight: .infinity)
            }
        }
    }

    @ViewBuilder
    private func activeView(_ task: ActiveTask) -> some View {
        let elapsed = max(0, state.now.timeIntervalSince(task.since))
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(task.title)
                .font(NT.font(13, .semibold))
                .foregroundStyle(NT.label)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .help(task.title)
            Text(Fmt.mmss(Int(elapsed)))
                .font(NT.rounded(12, .medium))
                .monospacedDigit()
                .foregroundStyle(state.workColor)
        }
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(NT.track)
                Capsule()
                    .fill(state.workColor)
                    .frame(width: geo.size.width * min(1, elapsed / Double(task.min * 60)))
                    .animation(.linear(duration: 1), value: elapsed)
            }
        }
        .frame(height: 4)
        HStack(spacing: 8) {
            Text(task.overdue ? "Time’s up · \(task.min) min" : "\(task.min) min planned")
                .font(NT.font(11))
                .foregroundStyle(task.overdue ? NT.secondary : NT.tertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
            Btn(variant: task.overdue ? .prom : .glass, small: true, title: "Done") { state.finishTask() }
        }
    }

    // MARK: Add form

    private var addForm: some View {
        Card(spacing: 8) {
            CardTitle(icon: .scope, color: NT.teal) {
                Text("New Task")
            } right: {
                Button("Cancel", action: cancel)
                    .buttonStyle(.plain)
                    .font(NT.font(12, .medium))
                    .foregroundStyle(NT.blue)
            }

            NTextField(id: "task", placeholder: "Task, e.g. Write project brief", text: $title, autoFocus: true, onSubmit: submit)

            HStack(spacing: 6) {
                Text("For")
                    .font(NT.font(11))
                    .foregroundStyle(NT.secondary)
                HStack(spacing: 2) {
                    Button { mins = max(5, mins - 5) } label: { Text("−") }
                        .disabled(mins <= 5)
                    Text("\(mins) min")
                        .font(NT.rounded(12))
                        .monospacedDigit()
                        .foregroundStyle(NT.label)
                        .frame(minWidth: 42)
                    Button { mins = min(120, mins + 5) } label: { Text("+") }
                        .disabled(mins >= 120)
                }
                .buttonStyle(MiniButtonStyle(size: 20, background: nil, hoverBackground: Color.white.opacity(0.2)))
                .padding(2)
                .frame(height: 24)
                .background(Capsule().fill(NT.controlBG))
                Spacer(minLength: 0)
                Btn(variant: .prom, small: true, title: "Add", action: submit)
                    .disabled(trimmed.isEmpty)
            }
        }
        .onExitCommand(perform: cancel)
    }

    private func submit() {
        guard !trimmed.isEmpty else { return }
        state.addTask(WorkTask(title: trimmed, min: mins))
        title = ""
        mins = 15
        adding = false
    }

    private func cancel() {
        adding = false
        title = ""
    }
}

/// A saved task: click to start it, hover to reveal remove.
private struct TaskChip: View {
    @Environment(NotchState.self) private var state
    let task: WorkTask
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 5) {
            Text(task.title)
            Text("\(task.min)m")
                .foregroundStyle(NT.tertiary)
                .opacity(hovering ? 0 : 1)
        }
        .font(NT.font(11, .medium))
        .foregroundStyle(Color(red: 235 / 255, green: 235 / 255, blue: 245 / 255).opacity(0.75))
        .lineLimit(1)
        .padding(.horizontal, 9)
        .frame(height: 22)
        .background(Capsule().fill(Color.white.opacity(hovering ? 0.14 : 0.08)))
        .contentShape(Capsule())
        .onTapGesture { state.startTask(task) }
        // Remove button takes the place of the "15m" label, so the chip never changes width.
        .overlay(alignment: .trailing) {
            Button { state.removeTask(task.id) } label: { Icon(name: .xmark, size: 8, stroke: 2.6) }
                .buttonStyle(MiniButtonStyle(size: 14, background: Color.white.opacity(0.18), hoverBackground: Color.white.opacity(0.3)))
                .help("Remove")
                .padding(.trailing, 5)
                .opacity(hovering ? 1 : 0)
                .allowsHitTesting(hovering)
        }
        .help("Start “\(task.title)” · \(task.min) min")
        .onHover { hovering = $0 }
    }
}
