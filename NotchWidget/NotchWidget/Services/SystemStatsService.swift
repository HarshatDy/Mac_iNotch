import Foundation
import Darwin.Mach

struct RAMInfo {
    var used:  Double = 11.4
    var total: Double = 18
    var free:  Double = 6.6
}

final class SystemStatsService {
    static let shared = SystemStatsService()
    private init() {}

    // C macros don't bridge to Swift directly; compute counts from layout sizes.
    private static let cpuLoadInfoCount = mach_msg_type_number_t(
        MemoryLayout<host_cpu_load_info>.stride / MemoryLayout<integer_t>.stride
    )
    private static let vmInfo64Count = mach_msg_type_number_t(
        MemoryLayout<vm_statistics64>.stride / MemoryLayout<integer_t>.stride
    )

    // MARK: - CPU usage

    private var prevIdle:  UInt64 = 0
    private var prevTotal: UInt64 = 0

    func cpuUsage() -> Double {
        var count = SystemStatsService.cpuLoadInfoCount
        var info  = host_cpu_load_info()

        let kr = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics(mach_host_self(), HOST_CPU_LOAD_INFO, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return 0 }

        let idle  = UInt64(info.cpu_ticks.3)
        let user  = UInt64(info.cpu_ticks.0)
        let sys   = UInt64(info.cpu_ticks.1)
        let nice  = UInt64(info.cpu_ticks.2)
        let total = idle + user + sys + nice

        let dIdle  = total > prevTotal ? idle  - prevIdle  : 0
        let dTotal = total > prevTotal ? total - prevTotal : 1
        prevIdle  = idle
        prevTotal = total

        return Double(dTotal - dIdle) / Double(dTotal) * 100
    }

    // MARK: - RAM

    func ramInfo() -> RAMInfo {
        var stats = vm_statistics64()
        var count = SystemStatsService.vmInfo64Count

        let kr = withUnsafeMutablePointer(to: &stats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        guard kr == KERN_SUCCESS else { return RAMInfo() }

        let page    = Double(vm_kernel_page_size)
        let used    = Double(stats.active_count + stats.wire_count) * page / 1e9
        let free    = Double(stats.free_count) * page / 1e9
        let inactive = Double(stats.inactive_count) * page / 1e9
        let total   = used + free + inactive

        return RAMInfo(used: used, total: total, free: free)
    }
}
