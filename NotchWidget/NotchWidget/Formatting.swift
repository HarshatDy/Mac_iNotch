import Foundation

// MARK: - Natural-language reminder parsing (port of parseReminder in notch/modules.jsx)

struct ParsedReminder {
    var title: String
    var due: Date?
}

enum ReminderParser {
    private static let weekdays = ["sun", "mon", "tue", "wed", "thu", "fri", "sat"]
    private static let partsOfDay = ["noon": 12, "morning": 9, "afternoon": 15, "evening": 18]

    static func parse(_ input: String, now: Date = Date()) -> ParsedReminder {
        var s = " " + input + " "

        /// Finds the first match, cuts it out of `s` (leaving a space) and returns its capture groups.
        func take(_ pattern: String, caseInsensitive: Bool = true) -> [String?]? {
            guard let re = try? NSRegularExpression(pattern: pattern, options: caseInsensitive ? [.caseInsensitive] : []) else { return nil }
            let ns = s as NSString
            guard let m = re.firstMatch(in: s, range: NSRange(location: 0, length: ns.length)) else { return nil }
            let groups = (0..<m.numberOfRanges).map { i -> String? in
                let r = m.range(at: i)
                return r.location == NSNotFound ? nil : ns.substring(with: r)
            }
            s = ns.replacingCharacters(in: m.range, with: " ")
            return groups
        }

        let cal = Calendar.current
        var due: Date?
        var dayOffset: Int?
        var weekday: Int?
        var hh: Int?
        var mm = 0

        if let m = take(#"\s+in\s+(\d+)\s*(minutes?|mins?|m|hours?|hrs?|hr|h)(?=\s)"#),
           let n = Double(m[1] ?? "") {
            let hours = (m[2] ?? "").lowercased().hasPrefix("h")
            due = now.addingTimeInterval(hours ? n * 3600 : n * 60)
        } else {
            if take(#"\s+today(?=\s)"#) != nil {
                dayOffset = 0
            } else if take(#"\s+(tomorrow|tmrw|tmr)(?=\s)"#) != nil {
                dayOffset = 1
            } else if take(#"\s+tonight(?=\s)"#) != nil {
                dayOffset = 0
                hh = 20
            } else if let m = take(#"\s+(?:on\s+|next\s+)?(sunday|monday|tuesday|wednesday|thursday|friday|saturday|sun|mon|tue|wed|thu|fri|sat)(?=\s)"#),
                      let name = m[1] {
                weekday = weekdays.firstIndex(of: String(name.lowercased().prefix(3)))
            }

            if let m = take(#"\s+(?:at\s+)?(\d{1,2})(?::(\d{2}))?\s*(am|pm)(?=\s)"#) {
                hh = (Int(m[1] ?? "") ?? 0) % 12 + ((m[3] ?? "").lowercased() == "pm" ? 12 : 0)
                mm = Int(m[2] ?? "0") ?? 0
            } else if let m = take(#"\s+at\s+(\d{1,2})(?::(\d{2}))?(?=\s)"#) {
                var h = Int(m[1] ?? "") ?? 0
                if h < 8 { h += 12 }
                hh = h
                mm = Int(m[2] ?? "0") ?? 0
            } else if let m = take(#"\s+(\d{1,2}):(\d{2})(?=\s)"#, caseInsensitive: false) {
                hh = Int(m[1] ?? "") ?? 0
                mm = Int(m[2] ?? "") ?? 0
            } else if let m = take(#"\s+(?:at\s+|in the\s+|this\s+)?(noon|morning|afternoon|evening)(?=\s)"#) {
                hh = partsOfDay[(m[1] ?? "").lowercased()]
            }

            if dayOffset != nil || weekday != nil || hh != nil {
                var day = cal.startOfDay(for: now)
                if let weekday {
                    var diff = (weekday - (cal.component(.weekday, from: now) - 1) + 7) % 7
                    if diff == 0 { diff = 7 }
                    day = cal.date(byAdding: .day, value: diff, to: day) ?? day
                } else if let dayOffset, dayOffset != 0 {
                    day = cal.date(byAdding: .day, value: dayOffset, to: day) ?? day
                }
                // Adding components (rather than setting them) lets out-of-range values roll over like JS setHours.
                var d = cal.date(byAdding: DateComponents(hour: hh ?? 9, minute: hh != nil ? mm : 0), to: day) ?? day
                if dayOffset == nil && weekday == nil && d <= now {
                    d = cal.date(byAdding: .day, value: 1, to: d) ?? d
                }
                due = d
            }
        }

        var title = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespaces)
        title = title.replacingOccurrences(of: #"\s+(at|on|by)$"#, with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespaces)
        title = title.prefix(1).uppercased() + title.dropFirst()
        return ParsedReminder(title: title, due: due)
    }
}

// MARK: - Formatting helpers

enum Fmt {
    static func time(_ d: Date) -> String {
        d.formatted(date: .omitted, time: .shortened)
    }

    static func dayDiff(_ d: Date, _ now: Date) -> Int {
        let cal = Calendar.current
        return cal.dateComponents([.day], from: cal.startOfDay(for: now), to: cal.startOfDay(for: d)).day ?? 0
    }

    /// "Today, 6:00 PM" / "Tomorrow, …" / "Friday, …" / "28 Sep, …"
    static func due(_ d: Date, _ now: Date) -> String {
        let k = dayDiff(d, now)
        let day: String
        switch k {
        case 0:  day = "Today"
        case 1:  day = "Tomorrow"
        case ..<7: day = d.formatted(.dateTime.weekday(.wide))
        default: day = d.formatted(.dateTime.day().month(.abbreviated))
        }
        return "\(day), \(time(d))"
    }

    /// "in 40 min" / "in 3 hr 15 min" / "tomorrow, 6:00 PM"
    static func countdown(_ d: Date, _ now: Date) -> String {
        let min = Int(ceil(d.timeIntervalSince(now) / 60))
        if min <= 0 { return "now" }
        if min < 60 { return "in \(min) min" }
        let h = min / 60, r = min % 60
        if h < 24 && dayDiff(d, now) == 0 { return r > 0 ? "in \(h) hr \(r) min" : "in \(h) hr" }
        return dayDiff(d, now) == 1 ? "tomorrow, \(time(d))" : due(d, now)
    }

    /// Compact countdown for the resting notch: "40m" / "3h" / "2d"
    static func shortCountdown(_ d: Date, _ now: Date) -> String {
        let m = Int(ceil(d.timeIntervalSince(now) / 60))
        if m < 60 { return "\(m)m" }
        if m < 1440 { return "\(m / 60)h" }
        return "\(m / 1440)d"
    }

    static func mmss(_ seconds: Int) -> String {
        let s = max(0, seconds)
        return String(format: "%02d:%02d", s / 60, s % 60)
    }

    static func ago(_ t: Date, _ now: Date) -> String {
        let m = Int(floor(now.timeIntervalSince(t) / 60))
        if m < 1 { return "Now" }
        if m < 60 { return "\(m)m" }
        if m < 1440 { return "\(m / 60)h" }
        return "\(m / 1440)d"
    }
}
