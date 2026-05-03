import SwiftUI

struct ExpandedWidgetsView: View {
    let state: NotchState

    var body: some View {
        HStack(spacing: 0) {
            let widgets = state.enabledWidgets
            let scale   = state.scaleFactor

            ForEach(Array(widgets.enumerated()), id: \.element.id) { index, id in
                if index > 0 {
                    Rectangle()
                        .fill(Color.white.opacity(0.09))
                        .frame(width: 1)
                        .padding(.vertical, 16)
                }

                widgetView(for: id)
                    .frame(width: (WidgetID.naturalWidths[id] ?? 100) * scale)
                    .scaleEffect(scale < 0.85 ? scale : 1.0)
                    .padding(.horizontal, max(6, 14 * scale))
            }

            Spacer(minLength: 4)

            // Gear button
            GlassButton(size: 20, action: { state.openConfigure() }) {
                AnyView(
                    Image(systemName: "gearshape")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                )
            }
            .padding(.trailing, 10)
        }
        .padding(.horizontal, 14)
    }

    @ViewBuilder
    func widgetView(for id: WidgetID) -> some View {
        switch id {
        case .spotify:       SpotifyWidget(state: state)
        case .battery:       BatteryWidget()
        case .clock:         ClockWidget()
        case .weather:       WeatherWidget()
        case .wifi:          WiFiWidget()
        case .cpu:           CPUWidget()
        case .ram:           RAMWidget()
        case .volume:        VolumeWidget(state: state)
        case .notifications: NotificationsWidget()
        case .dnd:           FocusWidget(state: state)
        case .mic:           MicrophoneWidget(state: state)
        }
    }
}
