import SwiftUI

struct HoverCompactView: View {
    let state: NotchState
    @State private var now = Date()
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        HStack(spacing: 7) {
            if state.isEnabled(.spotify) {
                SpotifyIcon()
                Text(SpotifyService.shared.trackTitle)
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.82))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: 90, alignment: .leading)
            }

            if state.isEnabled(.battery) {
                Text("\(Int(BatteryService.shared.percentage))%")
                    .font(.system(size: 10.5, weight: .semibold))
                    .foregroundStyle(Color(hex: 0x30D158))
                    .monospacedDigit()
            }

            if state.isEnabled(.clock) {
                Text(now, format: .dateTime.hour(.twoDigits(amPM: .omitted)).minute())
                    .font(.system(size: 10.5, weight: .medium))
                    .foregroundStyle(.white.opacity(0.55))
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 12)
        .onReceive(timer) { now = $0 }
    }
}

private struct SpotifyIcon: View {
    var body: some View {
        ZStack {
            Circle().fill(Color(hex: 0x1DB954))
            Image(systemName: "music.note")
                .font(.system(size: 5.5, weight: .bold))
                .foregroundStyle(.black)
        }
        .frame(width: 11, height: 11)
    }
}
