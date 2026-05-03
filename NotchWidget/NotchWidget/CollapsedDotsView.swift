import SwiftUI

struct CollapsedDotsView: View {
    let state: NotchState

    var body: some View {
        HStack(spacing: 5) {
            ForEach(state.enabledWidgets.prefix(6)) { id in
                Circle()
                    .fill(id.dotColor)
                    .frame(width: 4.5, height: 4.5)
                    .opacity(0.7)
            }
        }
    }
}

extension WidgetID: Identifiable {
    public var id: String { rawValue }
}
