import SwiftUI

// MARK: - Root view embedded in the hosting view

struct NotchRootView: View {
    let state: NotchState

    var body: some View {
        ZStack(alignment: .top) {
            NotchShell()
            ProgressOutline()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .environment(state)
        .environment(\.colorScheme, .dark)
    }
}

// MARK: - The glass shell that grows out of the hardware notch

private struct NotchShell: View {
    @Environment(NotchState.self) private var state

    var body: some View {
        let display = state.display
        ZStack(alignment: .top) {
            panelContent(display)

            if display == .compact {
                if state.variant == .short { CompactBar().transition(.nwFade) }
            } else {
                HeaderBar(display: display)
            }

            // Hardware notch
            NotchShape(radius: 12)
                .fill(Color.black)
                .frame(width: state.hwWidth, height: state.hwHeight)

            if display == .open {
                Button { state.showSettings = true } label: { Icon(name: .gear, size: 13, stroke: 1.9) }
                    .buttonStyle(MiniButtonStyle())
                    .help("Settings")
                    .padding(.top, (state.hwHeight - 22) / 2)
                    .padding(.trailing, 14)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .transition(.nwFade)
            }
        }
        .frame(width: state.width, height: state.height, alignment: .top)
        .background {
            ZStack {
                VisualEffectView(material: .hudWindow)
                Color(red: 20 / 255, green: 20 / 255, blue: 24 / 255).opacity(0.62)
            }
        }
        .clipShape(NotchShape(radius: state.radius))
        .overlay(NotchBorder(radius: state.radius).stroke(Color.white.opacity(0.14), lineWidth: 0.5))
        .background {
            NotchShape(radius: state.radius)
                .fill(Color.black)
                .shadow(color: .black.opacity(0.45), radius: 25, y: 20)
        }
        .animation(NT.ease(0.5), value: display)
        .animation(NT.ease(0.5), value: state.variant)
        .animation(NT.ease(0.5), value: state.width)
    }

    @ViewBuilder
    private func panelContent(_ display: NotchDisplay) -> some View {
        let top = state.hwHeight + 8
        switch display {
        case .open:
            OpenGrid()
                .frame(width: state.width - 28, height: state.height - top - 14)
                .padding(.top, top)
                .transition(.nwIn)
        case .settings:
            SettingsView()
                .frame(width: state.width - 28, height: state.height - top - 14)
                .padding(.top, top)
                .transition(.nwIn)
        case .alarm:
            if let alarm = state.alarm {
                AlarmView(alarm: alarm)
                    .frame(width: state.width, height: state.height - state.hwHeight)
                    .padding(.top, state.hwHeight)
                    .transition(.nwIn)
            }
        case .compact:
            EmptyView()
        }
    }
}

// MARK: - Resting "short bar": next reminder on the left, timers on the right

private struct CompactBar: View {
    @Environment(NotchState.self) private var state

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 5) {
                if let next = state.nextReminder, let due = next.due {
                    Icon(name: .bell, size: 12, color: NT.orange, stroke: 2.1)
                    Text(Fmt.shortCountdown(due, state.now))
                        .foregroundStyle(NT.label)
                        .monospacedDigit()
                }
            }
            .help(tooltip)
            .padding(.leading, 14)
            .padding(.trailing, 6)
            .frame(maxWidth: .infinity, alignment: .leading)

            Color.clear.frame(width: state.hwWidth)

            trailing
                .monospacedDigit()
                .padding(.leading, 6)
                .padding(.trailing, 14)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(NT.rounded(12))
        .lineLimit(1)
        .frame(height: state.hwHeight)
    }

    @ViewBuilder
    private var trailing: some View {
        let pomo = state.pomo
        HStack(spacing: 5) {
            if let task = state.activeTask, !pomo.active {
                // Work timer alone
                if task.overdue {
                    Text("\(task.min)m").foregroundStyle(NT.yellow)
                    Circle().fill(NT.yellow).frame(width: 7, height: 7).pulsing(3.2)
                } else {
                    Text("\(Int(ceil(Double(state.workRemaining) / 60)))m").foregroundStyle(state.workColor)
                    TimerRings(size: 14, stroke: 2.6)
                }
            } else {
                // Pomodoro alone (or idle), or both — the rings add an inner work layer when both run.
                Text("\(Int(ceil(Double(pomo.remaining) / 60)))m")
                    .foregroundStyle(pomo.active ? pomo.color : NT.tertiary)
                TimerRings(size: 14, stroke: 2.6)
            }
        }
        .help(timersTooltip)
    }

    private var tooltip: String {
        guard let next = state.nextReminder, let due = next.due else { return "" }
        return "\(next.title) · \(Fmt.countdown(due, state.now))"
    }

    private var timersTooltip: String {
        var parts: [String] = []
        if state.pomo.active { parts.append("\(state.pomo.isFocus ? "Focus" : "Break") \(Fmt.mmss(state.pomo.remaining))") }
        if let task = state.activeTask {
            parts.append(task.overdue ? "\(task.title) · time’s up" : "\(task.title) \(Fmt.mmss(state.workRemaining))")
        }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Timer ring(s): a single ring for one active timer, nested rings when Pomodoro and work both run

private struct TimerRings: View {
    @Environment(NotchState.self) private var state
    let size: CGFloat
    let stroke: CGFloat

    var body: some View {
        let pomo = state.pomo
        if pomo.active && state.workActive {
            let outer = size + 2, outerStroke = stroke * 0.85
            let inner = outer - 2 * (outerStroke + 1.2)
            ZStack {
                Ring(size: outer, stroke: outerStroke, progress: pomo.progress, color: pomo.color)
                Ring(size: inner, stroke: stroke * 0.75, progress: state.workProgress, color: state.workColor)
            }
            .frame(width: outer, height: outer)
        } else if state.workActive {
            Ring(size: size, stroke: stroke, progress: state.workProgress, color: state.workColor)
        } else {
            Ring(size: size, stroke: stroke, progress: pomo.progress, color: pomo.color)
        }
    }
}

// MARK: - Expanded header: reminder title on the left, timers on the right

private struct HeaderBar: View {
    @Environment(NotchState.self) private var state
    let display: NotchDisplay

    var body: some View {
        HStack(spacing: 0) {
            HStack(spacing: 6) {
                if let next = state.nextReminder, let due = next.due {
                    Icon(name: .bell, size: 12, color: NT.orange, stroke: 2.1)
                    Text(next.title)
                        .foregroundStyle(NT.label)
                        .truncationMode(.tail)
                    Text("· \(Fmt.countdown(due, state.now))")
                        .foregroundStyle(NT.secondary)
                        .fixedSize()
                }
            }
            .font(NT.font(12, .medium))
            .tracking(-0.12)
            .padding(.leading, 16)
            .padding(.trailing, 10)
            .frame(maxWidth: .infinity, alignment: .leading)

            Color.clear.frame(width: state.hwWidth)

            trailing
                .font(NT.font(12, .medium))
                .padding(.leading, 10)
                .padding(.trailing, display == .open ? 44 : 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .lineLimit(1)
        .frame(height: state.hwHeight)
    }

    @ViewBuilder
    private var trailing: some View {
        let pomo = state.pomo
        HStack(spacing: 6) {
            if let task = state.activeTask {
                workSegment(task)
                if pomo.active {
                    Text("·").foregroundStyle(NT.tertiary)
                    pomoSegment(pomo)
                }
            } else {
                pomoSegment(pomo)
            }
            TimerRings(size: 15, stroke: 2.6)
        }
    }

    @ViewBuilder
    private func workSegment(_ task: ActiveTask) -> some View {
        if task.overdue {
            Circle().fill(NT.yellow).frame(width: 6, height: 6).pulsing(3.2)
            Text(task.title).foregroundStyle(NT.label).truncationMode(.tail)
            Text("· \(task.min) min").foregroundStyle(NT.secondary).fixedSize()
        } else {
            Text(task.title).foregroundStyle(NT.secondary).truncationMode(.tail)
            Text(Fmt.mmss(state.workRemaining))
                .font(NT.rounded(12.5))
                .monospacedDigit()
                .foregroundStyle(state.workColor)
                .fixedSize()
        }
    }

    @ViewBuilder
    private func pomoSegment(_ pomo: Pomodoro) -> some View {
        if pomo.active {
            Text(pomo.isFocus ? (pomo.running ? "Focus" : "Paused") : "Break")
                .foregroundStyle(pomo.isFocus ? NT.secondary : NT.green)
                .fixedSize()
        }
        Text(Fmt.mmss(pomo.remaining))
            .font(NT.rounded(12.5))
            .monospacedDigit()
            .foregroundStyle(pomo.active ? pomo.color : NT.tertiary)
            .fixedSize()
    }
}

// MARK: - "Progress outline" resting variant: running timers trace the notch edge
//
// One timer → one outline hugging the notch. Pomodoro + work → Pomodoro stays on the inner
// outline and the work timer gets a second, outer layer.

private struct ProgressOutline: View {
    @Environment(NotchState.self) private var state

    var body: some View {
        let pomo = state.pomo
        let both = pomo.active && state.workActive
        ZStack(alignment: .top) {
            if pomo.active || !state.workActive {
                OutlineLayer(gap: 3, progress: pomo.progress, color: pomo.color, dimmed: !pomo.running)
            }
            if state.workActive {
                OutlineLayer(gap: both ? 8 : 3, progress: state.workProgress, color: state.workColor, dimmed: false)
            }
        }
        .shadow(color: .black.opacity(0.4), radius: 1.5, y: 1)
        .opacity(state.showProgressOutline ? 1 : 0)
        .animation(NT.ease(0.35), value: state.showProgressOutline)
        .animation(NT.ease(0.35), value: both)
        .allowsHitTesting(false)
    }
}

private struct OutlineLayer: View {
    @Environment(NotchState.self) private var state
    let gap: CGFloat          // distance from the notch edge to the stroke's inner side
    let progress: Double
    let color: Color
    let dimmed: Bool

    var body: some View {
        let sw: CGFloat = 3
        let o = gap + sw / 2
        let w = state.hwWidth + 2 * o, h = state.hwHeight + o
        let path = Self.outline(width: w, inset: o - gap, bottom: state.hwHeight + gap, radius: 12 + gap)

        ZStack {
            path.stroke(Color.white.opacity(0.16), style: StrokeStyle(lineWidth: sw, lineCap: .round))
            path.trim(from: 0, to: max(0, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: sw, lineCap: .round))
                .opacity(dimmed ? 0.45 : 1)
                .animation(.linear(duration: 0.5), value: progress)
                .animation(.easeOut(duration: 0.3), value: dimmed)
                .animation(.easeOut(duration: 0.3), value: color)
        }
        .frame(width: w, height: h)
    }

    /// Open "U" around the notch: down the left side, round the bottom corners, up the right side.
    static func outline(width: CGFloat, inset x0: CGFloat, bottom yb: CGFloat, radius r: CGFloat) -> Path {
        let x1 = width - x0
        var p = Path()
        p.move(to: CGPoint(x: x0, y: 0))
        p.addArc(tangent1End: CGPoint(x: x0, y: yb), tangent2End: CGPoint(x: x1, y: yb), radius: r)
        p.addArc(tangent1End: CGPoint(x: x1, y: yb), tangent2End: CGPoint(x: x1, y: 0), radius: r)
        p.addLine(to: CGPoint(x: x1, y: 0))
        return p
    }
}

// MARK: - Expanded grid: day strip / focus · up next · inbox / snip · nudge

private struct OpenGrid: View {
    var body: some View {
        GeometryReader { g in
            let gap: CGFloat = 12
            let unit = (g.size.width - 2 * gap) / 3.16
            let wide = unit * 1.16
            VStack(spacing: gap) {
                DayStripCard()
                    .fixedSize(horizontal: false, vertical: true)
                HStack(spacing: gap) {
                    FocusCard().frame(width: wide)
                    RemindersCard().frame(width: unit)
                    InboxCard().frame(width: unit)
                }
                .frame(height: 204)
                HStack(spacing: gap) {
                    SnipsCard().frame(width: wide + unit + gap)
                    WorkCard().frame(width: unit)
                }
                .frame(maxHeight: .infinity)
            }
        }
    }
}
