import Foundation
import IOKit.ps

struct BatterySnapshot {
    var percentage: Double  = 78
    var charging: Bool      = false
    var timeRemaining: String = "4h 23m left"
}

final class BatteryService {
    static let shared = BatteryService()
    private init() {}

    func snapshot() -> BatterySnapshot {
        guard
            let blob = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
            let list = IOPSCopyPowerSourcesList(blob)?.takeRetainedValue() as? [CFTypeRef],
            let src  = list.first,
            let info = IOPSGetPowerSourceDescription(blob, src)?.takeUnretainedValue() as? [String: Any]
        else {
            return BatterySnapshot()
        }

        let pct      = info[kIOPSCurrentCapacityKey] as? Double ?? 78
        let charging = (info[kIOPSPowerSourceStateKey] as? String) == kIOPSACPowerValue

        var remaining = "–"
        if !charging, let mins = info[kIOPSTimeToEmptyKey] as? Int, mins > 0 {
            remaining = "\(mins / 60)h \(mins % 60)m left"
        }

        return BatterySnapshot(percentage: pct, charging: charging, timeRemaining: remaining)
    }

    // Convenience for the compact view
    var percentage: Double { snapshot().percentage }
}
