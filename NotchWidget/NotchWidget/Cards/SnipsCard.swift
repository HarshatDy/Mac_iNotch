import SwiftUI

/// Screen Snip: capture mode, capture button and the four most recent snips.
struct SnipsCard: View {
    @Environment(NotchState.self) private var state
    @State private var copied: UUID?

    var body: some View {
        @Bindable var state = state

        Card {
            HStack(alignment: .top, spacing: 14) {
                VStack(alignment: .leading, spacing: 8) {
                    CardTitle(icon: .viewfinder, color: NT.purple) { Text("Screen Snip") }
                    Segmented(options: [
                        SegOption(value: SnipMode.area, icon: .area, help: "Selected area"),
                        SegOption(value: SnipMode.window, icon: .window, help: "Window"),
                        SegOption(value: SnipMode.screen, icon: .display, help: "Entire screen"),
                    ], value: $state.snipMode)
                    Button { state.capture() } label: {
                        HStack(spacing: 6) {
                            Text("Capture")
                            Text("⇧⌘4").font(NT.font(11)).opacity(0.6)
                        }
                    }
                    .buttonStyle(NButtonStyle(variant: .prom, stretch: true))
                }
                .frame(width: 150)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Recent")
                        .font(NT.font(12, .medium))
                        .foregroundStyle(NT.tertiary)
                        .frame(height: 16)
                    HStack(alignment: .top, spacing: 0) {
                        ForEach(0..<4, id: \.self) { i in
                            if i > 0 { Spacer(minLength: 0) }
                            if i < state.snips.count {
                                let snip = state.snips[i]
                                SnipThumb(snip: snip, copied: copied == snip.id, onCopy: { copy(snip.id) })
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(NT.fill, lineWidth: 1)
                                    .frame(width: SnipThumb.tw, height: SnipThumb.th)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func copy(_ id: UUID) {
        copied = id
        Task {
            try? await Task.sleep(for: .milliseconds(1400))
            if copied == id { copied = nil }
        }
    }
}

private struct SnipThumb: View {
    static let tw: CGFloat = 78, th: CGFloat = 56

    @Environment(NotchState.self) private var state
    let snip: Snip
    let copied: Bool
    let onCopy: () -> Void
    @State private var hovering = false

    var body: some View {
        let r = snip.rect
        let k = min(Self.tw / max(1, r.width), Self.th / max(1, r.height))

        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                SnipImage(wallpaper: state.wallpaper)
                    .frame(width: snip.screen.width * k, height: snip.screen.height * k)
                    .offset(x: -r.minX * k, y: -r.minY * k)
                    .frame(width: r.width * k, height: r.height * k, alignment: .topLeading)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .overlay(RoundedRectangle(cornerRadius: 4).strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5))
                    .frame(width: Self.tw, height: Self.th)
                    .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(0.04)))
                    .contentShape(Rectangle())
                    .onTapGesture(perform: onCopy)
                    .help("\(Int(r.width)) × \(Int(r.height))")

                Button { state.deleteSnip(snip.id) } label: { Icon(name: .xmark, size: 10, stroke: 2.4) }
                    .buttonStyle(MiniButtonStyle(size: 18,
                                                 background: Color(red: 60 / 255, green: 60 / 255, blue: 66 / 255).opacity(0.95),
                                                 hoverBackground: Color(red: 80 / 255, green: 80 / 255, blue: 86 / 255)))
                    .help("Delete")
                    .offset(x: 6, y: -6)
                    .opacity(hovering ? 1 : 0)
                    .allowsHitTesting(hovering)
            }
            .scaleEffect(hovering ? 1.03 : 1)
            .onHover { hovering = $0 }
            .animation(.easeOut(duration: 0.15), value: hovering)

            Text(copied ? "Copied" : Fmt.ago(snip.t, state.now))
                .font(NT.font(10.5))
                .foregroundStyle(copied ? NT.green : NT.tertiary)
                .lineLimit(1)
        }
        .frame(width: Self.tw)
    }
}

/// Stand-in snip content until real capture is wired up: the matching crop of the desktop wallpaper.
private struct SnipImage: View {
    let wallpaper: NSImage?

    var body: some View {
        if let wallpaper {
            Image(nsImage: wallpaper)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            ZStack {
                LinearGradient(colors: [Color(red: 0.16, green: 0.18, blue: 0.33),
                                        Color(red: 0.10, green: 0.14, blue: 0.22),
                                        Color(red: 0.17, green: 0.14, blue: 0.30)],
                               startPoint: .topLeading, endPoint: .bottomTrailing)
                RadialGradient(colors: [Color(red: 0.32, green: 0.36, blue: 0.70).opacity(0.9), .clear],
                               center: UnitPoint(x: 0.18, y: 0.3), startRadius: 0, endRadius: 400)
                RadialGradient(colors: [Color(red: 0.22, green: 0.45, blue: 0.62).opacity(0.8), .clear],
                               center: UnitPoint(x: 0.82, y: 0.7), startRadius: 0, endRadius: 380)
            }
        }
    }
}
