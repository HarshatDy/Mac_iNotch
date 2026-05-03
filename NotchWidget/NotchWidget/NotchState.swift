import SwiftUI
import Combine

// MARK: - Display state machine

enum NotchDisplayState: Equatable {
    case collapsed
    case hoverCompact
    case expanded
    case configure
}

// MARK: - Supporting types

enum AccentTint: String, CaseIterable, Codable {
    case blue, purple, green, rose, amber

    var glowColor: Color {
        switch self {
        case .blue:   return Color(red: 0.42, green: 0.60, blue: 0.95)
        case .purple: return Color(red: 0.65, green: 0.42, blue: 0.95)
        case .green:  return Color(red: 0.38, green: 0.85, blue: 0.52)
        case .rose:   return Color(red: 0.92, green: 0.38, blue: 0.58)
        case .amber:  return Color(red: 0.98, green: 0.76, blue: 0.28)
        }
    }
}

enum WidgetID: String, CaseIterable, Codable {
    case spotify, battery, clock, weather, wifi, cpu, ram, volume, notifications, dnd, mic

    var label: String {
        switch self {
        case .spotify:       return "Spotify"
        case .battery:       return "Battery"
        case .clock:         return "Clock"
        case .weather:       return "Weather"
        case .wifi:          return "Wi-Fi"
        case .cpu:           return "CPU"
        case .ram:           return "Memory"
        case .volume:        return "Volume"
        case .notifications: return "Notifications"
        case .dnd:           return "Focus"
        case .mic:           return "Microphone"
        }
    }

    var systemIcon: String {
        switch self {
        case .spotify:       return "music.note"
        case .battery:       return "battery.100"
        case .clock:         return "clock"
        case .weather:       return "sun.max"
        case .wifi:          return "wifi"
        case .cpu:           return "cpu"
        case .ram:           return "memorychip"
        case .volume:        return "speaker.wave.2"
        case .notifications: return "bell"
        case .dnd:           return "moon"
        case .mic:           return "mic"
        }
    }

    var dotColor: Color {
        switch self {
        case .spotify:       return Color(hex: 0x1DB954)
        case .battery:       return Color(hex: 0x30D158)
        case .clock:         return .white.opacity(0.5)
        case .weather:       return Color(hex: 0xFF9F0A)
        case .wifi:          return Color(hex: 0x0A84FF)
        case .cpu, .ram:     return Color(hex: 0x64B4FF)
        case .volume:        return .white.opacity(0.5)
        case .notifications: return Color(hex: 0xFF453A)
        case .dnd:           return Color(hex: 0xFF9F0A)
        case .mic:           return Color(hex: 0x30D158)
        }
    }

    static let naturalWidths: [WidgetID: CGFloat] = [
        .spotify: 228, .battery: 130, .clock: 90, .weather: 118,
        .wifi: 120, .cpu: 100, .ram: 100, .volume: 100,
        .notifications: 186, .dnd: 110, .mic: 96
    ]
}

// MARK: - Tweaks (persisted)

struct NotchTweaks: Codable {
    var enabled: [String: Bool] = [
        "spotify": true, "battery": true, "clock": true, "weather": true,
        "wifi": false, "cpu": false, "ram": false, "volume": false,
        "notifications": false, "dnd": false, "mic": false
    ]
    var accentTint: AccentTint = .blue

    static let key = "notch_tweaks_v2"

    static func load() -> NotchTweaks {
        guard
            let data = UserDefaults.standard.data(forKey: key),
            let tweaks = try? JSONDecoder().decode(NotchTweaks.self, from: data)
        else { return NotchTweaks() }
        return tweaks
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        UserDefaults.standard.set(data, forKey: NotchTweaks.key)
    }
}

// MARK: - Main state object

@Observable
@MainActor
final class NotchState {
    static let shared = NotchState()

    // UI state
    var displayState: NotchDisplayState = .collapsed

    // Persisted tweaks
    var tweaks: NotchTweaks = .load() {
        didSet { tweaks.save() }
    }

    // Runtime widget state
    var playing = true
    var trackIndex = 0
    var volume: Double = 62
    var dndEnabled = false
    var dndUntil = "1 hour"
    var micActive = false

    // Hover timers
    private var enterTask: Task<Void, Never>?
    private var leaveTask: Task<Void, Never>?

    var enabledWidgets: [WidgetID] {
        WidgetID.allCases.filter { tweaks.enabled[$0.rawValue] == true }
    }

    func isEnabled(_ id: WidgetID) -> Bool {
        tweaks.enabled[id.rawValue] == true
    }

    func toggleWidget(_ id: WidgetID) {
        tweaks.enabled[id.rawValue] = !(tweaks.enabled[id.rawValue] ?? false)
    }

    // MARK: - Hover handling

    func handleMouseEnter() {
        leaveTask?.cancel()
        if displayState == .collapsed {
            displayState = .hoverCompact
        }
        enterTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(90))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if self?.displayState == .hoverCompact {
                    self?.displayState = .expanded
                }
            }
        }
    }

    func handleMouseLeave() {
        enterTask?.cancel()
        guard displayState != .configure else { return }
        leaveTask = Task { [weak self] in
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                if self?.displayState != .configure {
                    self?.displayState = .collapsed
                }
            }
        }
    }

    func openConfigure() {
        enterTask?.cancel()
        leaveTask?.cancel()
        withAnimation(notchAnimation) {
            displayState = .configure
        }
    }

    func closeConfigure() {
        withAnimation(notchAnimation) {
            displayState = .collapsed
        }
    }

    // MARK: - Geometry

    var notchWidth: CGFloat {
        switch displayState {
        case .collapsed:    return 158
        case .hoverCompact: return 192
        case .expanded:     return computedExpandedWidth
        case .configure:    return 520
        }
    }

    var notchHeight: CGFloat {
        switch displayState {
        case .collapsed:    return 30
        case .hoverCompact: return 36
        case .expanded:     return 160
        case .configure:    return 190
        }
    }

    var notchRadius: CGFloat {
        switch displayState {
        case .collapsed:    return 16
        case .hoverCompact: return 18
        case .expanded:     return 24
        case .configure:    return 22
        }
    }

    var computedExpandedWidth: CGFloat {
        let screenWidth = NSScreen.main?.frame.width ?? 1440
        let maxW = min(900, screenWidth - 80)
        let widgets = enabledWidgets
        guard !widgets.isEmpty else { return 280 }
        let naturalTotal = widgets.enumerated().reduce(0.0) { sum, pair in
            let (i, w) = pair
            return sum + (WidgetID.naturalWidths[w] ?? 100) + (i > 0 ? 29.0 : 0)
        }
        return min(maxW, max(280, naturalTotal + 40))
    }

    var scaleFactor: CGFloat {
        let available = computedExpandedWidth - 40
        let widgets = enabledWidgets
        guard !widgets.isEmpty else { return 1 }
        let natural = widgets.enumerated().reduce(0.0) { sum, pair in
            let (i, w) = pair
            return sum + (WidgetID.naturalWidths[w] ?? 100) + (i > 0 ? 29.0 : 0)
        }
        return natural > available ? available / natural : 1.0
    }
}

// MARK: - Shared animation curve (cubic-bezier(0.4,0,0.2,1))

let notchAnimation = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 0.35)
let notchHeightAnimation = Animation.timingCurve(0.4, 0, 0.2, 1, duration: 0.32)

// MARK: - Color convenience

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8)  & 0xFF) / 255
        let b = Double(hex         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
