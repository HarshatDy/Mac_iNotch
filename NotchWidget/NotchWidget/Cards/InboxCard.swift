import SwiftUI

/// "Brain Dump": quick capture for stray thoughts; each can be turned into a reminder or marked done.
struct InboxCard: View {
    @Environment(NotchState.self) private var state
    @State private var text = ""

    var body: some View {
        let items = state.inbox

        Card {
            CardTitle(icon: .tray, color: NT.teal) {
                Text("Brain Dump")
            } right: {
                if !items.isEmpty {
                    Text("\(items.count)")
                        .font(NT.font(10.5, .semibold))
                        .foregroundStyle(NT.secondary)
                        .padding(.horizontal, 5)
                        .frame(minWidth: 18, minHeight: 16)
                        .background(Capsule().fill(NT.fill))
                }
            }

            NTextField(id: "inbox", placeholder: "Capture a thought…", text: $text, onSubmit: submit)

            // Scrolls once there are more thoughts than fit, instead of pushing the card out of the grid.
            ScrollView(.vertical) {
                LazyVStack(alignment: .leading, spacing: 0) {
                    if items.isEmpty {
                        Text("All sorted.")
                            .font(NT.font(12))
                            .foregroundStyle(NT.tertiary)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                    }
                    ForEach(items) { item in
                        InboxRow(item: item)
                    }
                }
            }
            .scrollIndicators(.automatic)
            .padding(.horizontal, -6)
            .frame(maxHeight: .infinity, alignment: .top)
        }
    }

    private func submit() {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        state.addInbox(t)
        text = ""
    }
}

private struct InboxRow: View {
    @Environment(NotchState.self) private var state
    let item: InboxItem
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 8) {
            Marquee(text: item.text)
                .foregroundStyle(NT.label)
            Text(Fmt.ago(item.t, state.now))
                .font(NT.font(11))
                .foregroundStyle(NT.tertiary)
                .opacity(hovering ? 0 : 1)
        }
        .font(NT.font(12))
        .padding(.horizontal, 6)
        .frame(height: 26)
        .background(RoundedRectangle(cornerRadius: 7).fill(Color.white.opacity(hovering ? 0.06 : 0)))
        .overlay(alignment: .trailing) {
            HStack(spacing: 2) {
                Button { state.remind(item) } label: { Icon(name: .bell, size: 12, stroke: 2) }
                    .help("Make reminder")
                Button { state.completeInbox(item.id) } label: { Icon(name: .check, size: 12, stroke: 2.2) }
                    .help("Done")
            }
            .buttonStyle(MiniButtonStyle())
            .padding(.trailing, 4)
            .opacity(hovering ? 1 : 0)
            .allowsHitTesting(hovering)
        }
        .onHover { hovering = $0 }
        .animation(.easeOut(duration: 0.12), value: hovering)
    }
}
