import SwiftUI

/// "Today" timeline from 7 AM to 11 PM with Apple Calendar events, reminder dots and a now-line.
struct DayStripCard: View {
    @Environment(NotchState.self) private var state
    private let calendar = CalendarService.shared

    private struct Block: Identifiable {
        let id: String
        let s: Double, e: Double      // hours since today's midnight (may fall outside 0…24)
        let t: String, c: Color
        let start: Date, end: Date
    }

    private static let d0 = 7.0, d1 = 23.0

    private static func pct(_ h: Double) -> Double {
        (max(d0, min(d1, h)) - d0) / (d1 - d0)
    }

    private func hours(_ d: Date) -> Double {
        d.timeIntervalSince(Calendar.current.startOfDay(for: state.now)) / 3600
    }

    private var blocks: [Block] {
        calendar.events.map {
            Block(id: $0.id, s: hours($0.start), e: hours($0.end), t: $0.title, c: $0.color, start: $0.start, end: $0.end)
        }
    }

    var body: some View {
        let now = state.now
        let nh = hours(now)
        let blocks = self.blocks
        let cur = blocks.last { nh >= $0.s && nh < $0.e }
        let next = blocks.first { $0.s > nh }
        let status = cur.map { "\($0.t) · until \(Fmt.time($0.end))" }
            ?? next.map { "Free until \(Fmt.time($0.start)) · \($0.t)" }
            ?? "Nothing else scheduled"
        let todays = state.reminders.compactMap(\.due).filter { Fmt.dayDiff($0, now) == 0 }

        Card(spacing: 8) {
            CardTitle(icon: .calendar, color: NT.red) {
                HStack(spacing: 6) {
                    Text("Today")
                    Text(now.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                        .fontWeight(.regular)
                        .foregroundStyle(NT.tertiary)
                }
            } right: {
                switch calendar.access {
                case .granted:
                    Text(status).fontWeight(.regular).foregroundStyle(NT.secondary)
                case .notDetermined:
                    Button("Connect Apple Calendar") { calendar.requestAccess() }
                        .buttonStyle(.plain)
                        .fontWeight(.medium)
                        .foregroundStyle(NT.blue)
                case .denied:
                    Button("Allow Calendar access in Settings") { calendar.openPrivacySettings() }
                        .buttonStyle(.plain)
                        .fontWeight(.medium)
                        .foregroundStyle(NT.blue)
                }
            }

            GeometryReader { g in
                let w = g.size.width
                ZStack(alignment: .topLeading) {
                    ForEach(blocks) { b in
                        let x = Self.pct(b.s) * w
                        let bw = max(0, (Self.pct(b.e) - Self.pct(b.s)) * w - 2)
                        Text(b.t)
                            .font(NT.font(11, .medium))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .padding(.horizontal, 6)
                            .frame(width: bw, height: 20, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 5).fill(b.c.opacity(b.id == cur?.id ? 0.62 : 0.38)))
                            .clipShape(RoundedRectangle(cornerRadius: 5))
                            .opacity(b.e <= nh ? 0.4 : 1)
                            .help("\(b.t) · \(Fmt.time(b.start))–\(Fmt.time(b.end))")
                            .offset(x: x, y: 3)
                    }

                    ForEach(Array(todays.enumerated()), id: \.offset) { _, due in
                        Circle()
                            .fill(NT.label)
                            .frame(width: 5, height: 5)
                            .offset(x: Self.pct(hours(due)) * w - 2.5, y: 26)
                    }

                    // Now-line
                    ZStack(alignment: .top) {
                        Capsule().fill(NT.red).frame(width: 2, height: 34)
                            .shadow(color: .black.opacity(0.25), radius: 0.5)
                        Circle().fill(NT.red).frame(width: 8, height: 8).offset(y: -3)
                    }
                    .frame(width: 8)
                    .offset(x: Self.pct(nh) * w - 4, y: -4)
                    .animation(.linear(duration: 1), value: nh)
                }
            }
            .frame(height: 26)
            .background(RoundedRectangle(cornerRadius: 8).fill(NT.fill))

            GeometryReader { g in
                ForEach([8, 10, 12, 14, 16, 18, 20, 22], id: \.self) { h in
                    Text("\(h % 12 == 0 ? 12 : h % 12) \(h < 12 ? "AM" : "PM")")
                        .font(NT.font(10))
                        .foregroundStyle(NT.tertiary)
                        .fixedSize()
                        .position(x: Self.pct(Double(h)) * g.size.width, y: 6)
                }
            }
            .frame(height: 12)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            calendar.openCalendarApp()
            state.collapse()
        }
        .help("Open Calendar")
    }
}
