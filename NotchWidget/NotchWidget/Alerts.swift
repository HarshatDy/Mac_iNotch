import AppKit
import AVFoundation
import UserNotifications

/// Break-alert feedback: the prototype's two-tone chime, or a haptic tap.
@MainActor
enum Alerts {
    private static var player: AVAudioPlayer?
    private static let chime = makeChimeWAV()

    static func play(_ type: AlertType) {
        switch type {
        case .sound:
            player = try? AVAudioPlayer(data: chime)
            player?.play()
        case .haptic:
            // There is no public API to tap an Apple Watch from macOS; the Force Touch trackpad stands in.
            let performer = NSHapticFeedbackManager.defaultPerformer
            for i in 0..<3 {
                Task {
                    try? await Task.sleep(for: .milliseconds(300 * i))
                    performer.perform(.generic, performanceTime: .now)
                }
            }
        }
    }

    /// Three rings of an A5 + E6 sine pair: 10ms attack to 0.16, exponential decay over 1.3s.
    private static func makeChimeWAV() -> Data {
        let sampleRate = 44_100.0
        let count = Int(sampleRate * 2.8)
        var samples = [Double](repeating: 0, count: count)

        for t0 in [0.0, 0.6, 1.2] {
            for (j, freq) in [880.0, 1318.5].enumerated() {
                let start = Int((t0 + Double(j) * 0.14) * sampleRate)
                for i in 0..<Int(1.4 * sampleRate) {
                    let k = start + i
                    guard k < count else { break }
                    let t = Double(i) / sampleRate
                    let gain = t < 0.01 ? 0.16 * t / 0.01 : 0.16 * pow(0.0001 / 0.16, min(1, (t - 0.01) / 1.29))
                    samples[k] += gain * sin(2 * .pi * freq * t)
                }
            }
        }

        var data = Data()
        func u32(_ v: UInt32) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }
        func u16(_ v: UInt16) { withUnsafeBytes(of: v.littleEndian) { data.append(contentsOf: $0) } }

        let bytes = UInt32(count * 2)
        data.append(contentsOf: Array("RIFF".utf8)); u32(36 + bytes)
        data.append(contentsOf: Array("WAVE".utf8))
        data.append(contentsOf: Array("fmt ".utf8)); u32(16); u16(1); u16(1)
        u32(UInt32(sampleRate)); u32(UInt32(sampleRate) * 2); u16(2); u16(16)
        data.append(contentsOf: Array("data".utf8)); u32(bytes)
        for s in samples {
            u16(UInt16(bitPattern: Int16(max(-1, min(1, s)) * Double(Int16.max))))
        }
        return data
    }
}

/// System notification for the "Working On" task, scheduled for when its planned time runs out.
enum TaskNotifier {
    private static let id = "working-on-task"

    static func schedule(title: String, minutes: Int, at date: Date) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Time’s up: \(title)"
            content.body = "You planned \(minutes) min for this task."
            content.sound = .default
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, date.timeIntervalSinceNow), repeats: false)
            center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
    }

    static func cancel() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [id])
        center.removeDeliveredNotifications(withIdentifiers: [id])
    }
}
