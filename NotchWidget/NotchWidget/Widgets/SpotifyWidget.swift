import SwiftUI

struct SpotifyWidget: View {
    let state: NotchState

    var body: some View {
        let svc = SpotifyService.shared
        VStack(spacing: 9) {
            HStack(spacing: 9) {
                // Album art placeholder
                RoundedRectangle(cornerRadius: 10)
                    .fill(
                        LinearGradient(
                            colors: [svc.accentColor.opacity(0.6), svc.accentColor.opacity(0.27)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white.opacity(0.13), lineWidth: 1)
                    )
                    .shadow(color: svc.accentColor.opacity(0.27), radius: 7, x: 0, y: 4)
                    .frame(width: 46, height: 46)
                    .overlay(Image(systemName: "music.note").foregroundStyle(.white.opacity(0.4)))

                VStack(alignment: .leading, spacing: 1) {
                    Text(svc.trackTitle)
                        .font(.system(size: 12.5, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.94))
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(svc.artistName)
                        .font(.system(size: 10.5))
                        .foregroundStyle(.white.opacity(0.46))
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VizBars(playing: state.playing, color: svc.accentColor)
            }

            SlimProgressBar(value: svc.progress, color: svc.accentColor)

            HStack {
                Text(svc.elapsed)
                    .font(.system(size: 9.5))
                    .foregroundStyle(.white.opacity(0.30))
                    .monospacedDigit()

                Spacer()

                HStack(spacing: 10) {
                    GlassButton(size: 22, action: { SpotifyService.shared.previous() }) {
                        AnyView(
                            Image(systemName: "backward.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.white.opacity(0.65))
                        )
                    }
                    GlassButton(size: 30, action: { state.playing.toggle(); SpotifyService.shared.playPause() }, isAccent: true) {
                        AnyView(
                            Image(systemName: state.playing ? "pause.fill" : "play.fill")
                                .font(.system(size: 9))
                                .foregroundStyle(.white)
                                .offset(x: state.playing ? 0 : 1)
                        )
                    }
                    GlassButton(size: 22, action: { SpotifyService.shared.next() }) {
                        AnyView(
                            Image(systemName: "forward.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.white.opacity(0.65))
                        )
                    }
                }

                Spacer()

                Text(svc.duration)
                    .font(.system(size: 9.5))
                    .foregroundStyle(.white.opacity(0.30))
                    .monospacedDigit()
            }
        }
    }
}
