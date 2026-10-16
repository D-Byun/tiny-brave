import SwiftUI

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

struct Palette: Equatable {
    var background: Color
    var surface: Color
    var ink: Color
    var sky: Color
    var skySoft: Color
    var sun: Color
    var sunSoft: Color
}

extension Palette {
    static let standard = Palette(
        background: Color(hex: 0xFFF8E7), surface: .white, ink: Color(hex: 0x14213D),
        sky: Color(hex: 0x8ECAE6), skySoft: Color(hex: 0xD6ECF7),
        sun: Color(hex: 0xFFC93C), sunSoft: Color(hex: 0xFFE9A8)
    )
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = Palette.standard
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}

enum Theme {
    static func font(_ size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom("MarkerFelt-Wide", size: size, relativeTo: style)
    }
}

extension BraveCategory {
    /// Connect is blue, Speak pink, Try green and Reset lavender.
    var color: Color {
        switch self {
        case .connect: Color(hex: 0xBCE3E9)
        case .speak: Color(hex: 0xF1A7AA)
        case .try: Color(hex: 0xAFD5A2)
        case .reset: Color(hex: 0xC9B9E7)
        }
    }
}

func roughRect() -> UnevenRoundedRectangle {
    UnevenRoundedRectangle(
        topLeadingRadius: 16, bottomLeadingRadius: 22,
        bottomTrailingRadius: 14, topTrailingRadius: 20,
        style: .continuous
    )
}

private struct RoughCard: ViewModifier {
    @Environment(\.palette) private var palette
    let fill: Color?

    func body(content: Content) -> some View {
        content
            .background(roughRect().fill(fill ?? palette.surface))
            .overlay(roughRect().strokeBorder(palette.ink, lineWidth: 3))
    }
}

private struct ScreenBackground: ViewModifier {
    @Environment(\.palette) private var palette

    func body(content: Content) -> some View {
        content
            .foregroundStyle(palette.ink)
            .background(palette.background.ignoresSafeArea())
    }
}

extension View {
    /// Uses the theme's surface color when `fill` is nil.
    func roughCard(fill: Color? = nil) -> some View { modifier(RoughCard(fill: fill)) }

    /// Also sets the theme's ink color as the default foreground style.
    func screenBackground() -> some View { modifier(ScreenBackground()) }
}

struct BigButtonStyle: ButtonStyle {
    @Environment(\.palette) private var palette
    var fill: Color?
    var dashed = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(dashed ? 17 : 22, relativeTo: .title3))
            .foregroundStyle(palette.ink)
            .frame(maxWidth: .infinity, minHeight: 56)
            .padding(.horizontal, 12)
            .background(roughRect().fill(dashed ? Color.clear : (fill ?? palette.sun)))
            .overlay(
                roughRect().strokeBorder(
                    palette.ink,
                    style: StrokeStyle(lineWidth: 3, dash: dashed ? [7, 5] : [])
                )
            )
            .background {
                if !dashed { roughRect().fill(palette.ink).offset(x: 3, y: 4) }
            }
            .offset(x: configuration.isPressed ? 2 : 0, y: configuration.isPressed ? 3 : 0)
    }
}
