import SwiftUI
import AppKit

// MARK: - Design tokens (notch/ui.jsx → NT)

enum NT {
    static let blue   = Color(hex: 0x0A84FF)
    static let orange = Color(hex: 0xFF9F0A)
    static let green  = Color(hex: 0x30D158)
    static let red    = Color(hex: 0xFF453A)
    static let yellow = Color(hex: 0xFFD60A)
    static let indigo = Color(hex: 0x5E5CE6)
    static let teal   = Color(hex: 0x64D2FF)
    static let pink   = Color(hex: 0xFF375F)
    static let purple = Color(hex: 0xBF5AF2)

    static let label       = Color.white.opacity(0.92)
    static let secondary   = Color(red: 235 / 255, green: 235 / 255, blue: 245 / 255).opacity(0.62)
    static let tertiary    = Color(red: 235 / 255, green: 235 / 255, blue: 245 / 255).opacity(0.38)
    static let placeholder = Color(red: 235 / 255, green: 235 / 255, blue: 245 / 255).opacity(0.34)
    static let fill        = Color.white.opacity(0.08)
    static let track       = Color.white.opacity(0.12)
    static let controlBG   = Color(red: 118 / 255, green: 118 / 255, blue: 128 / 255).opacity(0.24)

    /// cubic-bezier(0.32, 0.72, 0, 1)
    static func ease(_ duration: Double) -> Animation {
        .timingCurve(0.32, 0.72, 0, 1, duration: duration)
    }

    static func font(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .semibold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension Color {
    init(hex: UInt32) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8)  & 0xFF) / 255
        let b = Double(hex         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}

// MARK: - Icons (SF Symbol equivalents of the prototype's stroked SVGs)

enum NIcon {
    case bell, play, pause, reset, plus, tray, check, xmark, speaker, watch
    case area, window, display, calendar, eye, scope, viewfinder, timer, chevronLeft, gear

    var symbol: String {
        switch self {
        case .bell:        return "bell"
        case .play:        return "play.fill"
        case .pause:       return "pause.fill"
        case .reset:       return "arrow.counterclockwise"
        case .plus:        return "plus"
        case .tray:        return "tray"
        case .check:       return "checkmark"
        case .xmark:       return "xmark"
        case .speaker:     return "speaker.wave.2"
        case .watch:       return "applewatch"
        case .area:        return "rectangle.dashed"
        case .window:      return "macwindow"
        case .display:     return "display"
        case .calendar:    return "calendar"
        case .eye:         return "eye"
        case .scope:       return "scope"
        case .viewfinder:  return "viewfinder"
        case .timer:       return "timer"
        case .chevronLeft: return "chevron.left"
        case .gear:        return "gearshape"
        }
    }
}

struct Icon: View {
    let name: NIcon
    var size: CGFloat = 14
    var color: Color? = nil
    var stroke: CGFloat = 1.8

    private var weight: Font.Weight {
        switch stroke {
        case ..<1.9:  return .regular
        case ..<2.1:  return .medium
        case ..<2.35: return .semibold
        default:      return .bold
        }
    }

    var body: some View {
        Image(systemName: name.symbol)
            .font(.system(size: size * 0.86, weight: weight))
            .foregroundStyle(color.map { AnyShapeStyle($0) } ?? AnyShapeStyle(.foreground))
            .frame(width: size, height: size)
    }
}

// MARK: - Buttons (.nb / .nmini)

struct NButtonStyle: ButtonStyle {
    enum Variant { case prom, glass }

    var variant: Variant = .glass
    var small = false
    var iconOnly = false
    var stretch = false

    func makeBody(configuration: Configuration) -> some View {
        NButtonBody(configuration: configuration, style: self)
    }
}

private struct NButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let style: NButtonStyle

    @Environment(\.isEnabled) private var isEnabled
    @State private var hovering = false

    private var height: CGFloat { style.small ? 24 : 28 }

    private var background: Color {
        switch style.variant {
        case .prom:  return hovering ? Color(hex: 0x2491FF) : NT.blue
        case .glass: return Color.white.opacity(hovering ? 0.18 : 0.12)
        }
    }

    var body: some View {
        configuration.label
            .font(NT.font(style.small ? 12 : 13, .medium))
            .tracking(-0.13)
            .lineLimit(1)
            .foregroundStyle(style.variant == .prom ? Color.white : NT.label)
            .padding(.horizontal, style.iconOnly ? 0 : (style.small ? 10 : 14))
            .frame(width: style.iconOnly ? height : nil, height: height)
            .frame(maxWidth: style.stretch ? .infinity : nil)
            .background(Capsule().fill(background))
            .overlay(
                Capsule().strokeBorder(
                    LinearGradient(colors: [.white.opacity(style.variant == .prom ? 0.3 : 0.18), .clear],
                                   startPoint: .top, endPoint: .center),
                    lineWidth: 0.5)
            )
            .contentShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(isEnabled ? 1 : 0.35)
            .onHover { hovering = $0 }
            .animation(.easeOut(duration: 0.15), value: hovering)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// Text / icon button in the prototype's `Btn` shape.
struct Btn: View {
    var variant: NButtonStyle.Variant = .glass
    var small = false
    var icon: NIcon? = nil
    var title: String? = nil
    var stretch = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let icon { Icon(name: icon, size: small ? 12 : 13, stroke: 2) }
                if let title { Text(title) }
            }
        }
        .buttonStyle(NButtonStyle(variant: variant, small: small, iconOnly: title == nil, stretch: stretch))
    }
}

/// Small circular glyph button (.nmini).
struct MiniButtonStyle: ButtonStyle {
    var size: CGFloat = 22
    var background: Color? = Color.white.opacity(0.1)
    var hoverBackground: Color? = Color.white.opacity(0.2)

    func makeBody(configuration: Configuration) -> some View {
        MiniButtonBody(configuration: configuration, style: self)
    }
}

private struct MiniButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let style: MiniButtonStyle

    @Environment(\.isEnabled) private var isEnabled
    @State private var hovering = false

    var body: some View {
        configuration.label
            .foregroundStyle(Color.white.opacity(0.85))
            .frame(width: style.size, height: style.size)
            .background(Circle().fill((hovering ? style.hoverBackground : style.background) ?? .clear))
            .contentShape(Circle())
            .opacity(isEnabled ? 1 : 0.3)
            .onHover { hovering = $0 }
    }
}

// MARK: - Segmented control

struct SegOption<Value: Hashable> {
    let value: Value
    var label: String = ""
    var icon: NIcon? = nil
    var help: String? = nil
}

struct Segmented<Value: Hashable>: View {
    let options: [SegOption<Value>]
    @Binding var value: Value

    var body: some View {
        let index = options.firstIndex { $0.value == value } ?? 0
        GeometryReader { g in
            let segW = (g.size.width - 4) / CGFloat(max(1, options.count))
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.22))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10).strokeBorder(
                            LinearGradient(colors: [.white.opacity(0.25), .clear], startPoint: .top, endPoint: .center),
                            lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.25), radius: 1.5, y: 1)
                    .frame(width: segW, height: g.size.height - 4)
                    .offset(x: CGFloat(index) * segW)
                    .animation(NT.ease(0.32), value: index)

                HStack(spacing: 0) {
                    ForEach(options.indices, id: \.self) { i in
                        let o = options[i]
                        Button { value = o.value } label: {
                            HStack(spacing: 4) {
                                if let icon = o.icon { Icon(name: icon, size: 12, stroke: 1.9) }
                                if !o.label.isEmpty { Text(o.label) }
                            }
                            .font(NT.font(11.5, .medium))
                            .tracking(-0.12)
                            .lineLimit(1)
                            .foregroundStyle(o.value == value ? NT.label : NT.secondary)
                            .animation(.easeOut(duration: 0.2), value: value)
                            .frame(width: segW, height: g.size.height - 4)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .help(o.help ?? o.label)
                    }
                }
            }
            .padding(2)
        }
        .frame(height: 24)
        .background(RoundedRectangle(cornerRadius: 12).fill(NT.controlBG))
    }
}

// MARK: - Progress ring

struct Ring<Content: View>: View {
    let size: CGFloat
    let stroke: CGFloat
    let progress: Double
    let color: Color
    @ViewBuilder var content: Content

    var body: some View {
        ZStack {
            Circle()
                .inset(by: stroke / 2)
                .stroke(NT.track, lineWidth: stroke)
            Circle()
                .inset(by: stroke / 2)
                .trim(from: 0, to: max(0, min(1, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: stroke, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.4), value: progress)
                .animation(.easeOut(duration: 0.3), value: color)
            content
        }
        .frame(width: size, height: size)
    }
}

extension Ring where Content == EmptyView {
    init(size: CGFloat, stroke: CGFloat, progress: Double, color: Color) {
        self.init(size: size, stroke: stroke, progress: progress, color: color) { EmptyView() }
    }
}

// MARK: - Card (.ncard) + title (.ntitle)

struct Card<Content: View>: View {
    var spacing: CGFloat = 10
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing) { content }
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.white.opacity(0.055)))
            .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5))
    }
}

struct CardTitle<Title: View, Right: View>: View {
    let icon: NIcon
    let color: Color
    @ViewBuilder var title: Title
    @ViewBuilder var right: Right

    var body: some View {
        HStack(spacing: 6) {
            Icon(name: icon, size: 13, color: color, stroke: 2)
            title.lineLimit(1)
            Spacer(minLength: 0)
            right
        }
        .font(NT.font(12, .semibold))
        .foregroundStyle(NT.secondary)
        .frame(height: 16)
    }
}

extension CardTitle where Right == EmptyView {
    init(icon: NIcon, color: Color, @ViewBuilder title: () -> Title) {
        self.init(icon: icon, color: color, title: title) { EmptyView() }
    }
}

// MARK: - Text field (.ntf)

struct NTextField: View {
    @Environment(NotchState.self) private var state

    let id: String
    let placeholder: String
    @Binding var text: String
    var trailingInset: CGFloat = 10
    var autoFocus = false
    var onSubmit: () -> Void = {}

    @FocusState private var focused: Bool

    private var field: some View {
        TextField("", text: $text, prompt: Text(placeholder).foregroundStyle(NT.placeholder))
            .textFieldStyle(.plain)
            .font(NT.font(13))
            .tracking(-0.13)
            .foregroundStyle(NT.label)
            .focused($focused)
            .onSubmit(onSubmit)
    }

    private var fillColor: Color { Color.white.opacity(focused ? 0.09 : 0.07) }
    private var borderColor: Color { focused ? NT.blue.opacity(0.9) : Color.white.opacity(0.14) }
    private var ringColor: Color { NT.blue.opacity(focused ? 0.35 : 0) }

    var body: some View {
        field
            .padding(.leading, 10)
            .padding(.trailing, trailingInset)
            .frame(height: 30)
            .background(RoundedRectangle(cornerRadius: 10).fill(fillColor))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(borderColor, lineWidth: 0.5))
            .overlay(RoundedRectangle(cornerRadius: 11.5).stroke(ringColor, lineWidth: 3).padding(-1.5))
            .animation(.easeOut(duration: 0.15), value: focused)
            .onChange(of: focused) { _, isFocused in state.setInputFocus(id, isFocused) }
            .onAppear { if autoFocus { focused = true } }
            .onDisappear { state.setInputFocus(id, false) }
    }
}

// MARK: - Window chrome helpers

struct VisualEffectView: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow

    func makeNSView(context: Context) -> NSVisualEffectView {
        let v = NSVisualEffectView()
        v.material = material
        v.blendingMode = .behindWindow
        v.state = .active
        v.appearance = NSAppearance(named: .darkAqua)
        return v
    }

    func updateNSView(_ v: NSVisualEffectView, context: Context) {
        v.material = material
    }
}

/// Rectangle with only the bottom corners rounded — the top edge is flush with the screen.
struct NotchShape: Shape {
    var radius: CGFloat

    var animatableData: CGFloat {
        get { radius }
        set { radius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let r = min(radius, rect.height / 2, rect.width / 2)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
                 tangent2End: CGPoint(x: rect.minX, y: rect.maxY), radius: r)
        p.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
                 tangent2End: CGPoint(x: rect.minX, y: rect.minY), radius: r)
        p.closeSubpath()
        return p
    }
}

/// Sides + bottom of `NotchShape` (the shell's border has no top edge).
struct NotchBorder: Shape {
    var radius: CGFloat

    var animatableData: CGFloat {
        get { radius }
        set { radius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let r = min(radius, rect.height / 2, rect.width / 2)
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addArc(tangent1End: CGPoint(x: rect.minX, y: rect.maxY),
                 tangent2End: CGPoint(x: rect.maxX, y: rect.maxY), radius: r)
        p.addArc(tangent1End: CGPoint(x: rect.maxX, y: rect.maxY),
                 tangent2End: CGPoint(x: rect.maxX, y: rect.minY), radius: r)
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        return p
    }
}

// MARK: - Animations

/// `nwIn`: fade + slight scale + blur-in.
struct NWInEffect: ViewModifier {
    let progress: Double

    func body(content: Content) -> some View {
        content
            .opacity(progress)
            .scaleEffect(0.98 + 0.02 * progress)
            .blur(radius: 6 * (1 - progress))
    }
}

extension AnyTransition {
    static var nwIn: AnyTransition {
        .asymmetric(
            insertion: .modifier(active: NWInEffect(progress: 0), identity: NWInEffect(progress: 1))
                .animation(NT.ease(0.4).delay(0.08)),
            removal: .opacity.animation(.linear(duration: 0.06))
        )
    }

    static var nwFade: AnyTransition {
        .asymmetric(insertion: .opacity.animation(.easeOut(duration: 0.3)),
                    removal: .opacity.animation(.linear(duration: 0.06)))
    }
}

/// `nwPulse`: opacity 1 → .45 and scale 1 → .9, looping.
struct Pulse: ViewModifier {
    let period: Double
    @State private var on = false

    func body(content: Content) -> some View {
        content
            .opacity(on ? 0.45 : 1)
            .scaleEffect(on ? 0.9 : 1)
            .onAppear {
                withAnimation(.easeInOut(duration: period / 2).repeatForever(autoreverses: true)) { on = true }
            }
    }
}

extension View {
    func pulsing(_ period: Double) -> some View { modifier(Pulse(period: period)) }
}

// MARK: - Flow layout (chips)

struct FlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowH: CGFloat = 0, maxX: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(ProposedViewSize(width: proposal.width, height: nil))
            if x + size.width > width && x > 0 {
                y += rowH + spacing
                x = 0
                rowH = 0
            }
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
            rowH = max(rowH, size.height)
        }
        return CGSize(width: proposal.width ?? maxX, height: y + rowH)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowH: CGFloat = 0
        for view in subviews {
            let size = view.sizeThatFits(ProposedViewSize(width: bounds.width, height: nil))
            if x + size.width > bounds.maxX && x > bounds.minX {
                y += rowH + spacing
                x = bounds.minX
                rowH = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}
