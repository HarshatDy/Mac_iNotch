import Foundation
import SwiftUI

final class SpotifyService: ObservableObject {
    static let shared = SpotifyService()
    private init() { startPolling() }

    @Published var trackTitle = "Midnight Rain"
    @Published var artistName = "Taylor Swift"
    @Published var progress:   Double = 0.42
    @Published var duration    = "3:42"
    @Published var accentColor = Color(hex: 0x9B59B6)
    @Published var isPlaying   = true

    var elapsed: String {
        let secs = Int(progress * durationSeconds)
        return String(format: "%d:%02d", secs / 60, secs % 60)
    }

    private var durationSeconds: Double {
        let parts = duration.split(separator: ":").compactMap { Double($0) }
        guard parts.count == 2 else { return 222 }
        return parts[0] * 60 + parts[1]
    }

    // MARK: - AppleScript controls

    func playPause() { run("tell application \"Spotify\" to playpause") }
    func next()      { run("tell application \"Spotify\" to next track") }
    func previous()  { run("tell application \"Spotify\" to previous track") }

    @discardableResult
    private func run(_ script: String) -> String? {
        var error: NSDictionary?
        let result = NSAppleScript(source: script)?.executeAndReturnError(&error)
        return result?.stringValue
    }

    // MARK: - Polling for track info

    private func startPolling() {
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.refresh()
        }
    }

    private func refresh() {
        let script = """
        tell application "Spotify"
            if it is running then
                set t to name of current track
                set a to artist of current track
                set d to duration of current track
                set p to player position
                return t & "||" & a & "||" & (d / 1000) & "||" & p
            end if
        end tell
        """
        var error: NSDictionary?
        let descriptor = NSAppleScript(source: script)?.executeAndReturnError(&error)
        guard error == nil, let result = descriptor?.stringValue else { return }

        let parts = result.split(separator: "||", omittingEmptySubsequences: false)
        guard parts.count >= 4 else { return }

        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.trackTitle = String(parts[0])
            self.artistName = String(parts[1])
            let total = Double(parts[2]) ?? 222
            let pos   = Double(parts[3]) ?? 0
            self.progress = total > 0 ? pos / total : 0
            let totalInt = Int(total)
            self.duration = String(format: "%d:%02d", totalInt / 60, totalInt % 60)
        }
    }
}
