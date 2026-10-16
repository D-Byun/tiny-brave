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

enum AppTheme: String, CaseIterable, Identifiable {
    case sunny, dark, ocean, forest, bubblegum

    static let storageKey = "theme"

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
    var isDark: Bool { self == .dark }

    var palette: Palette {
        switch self {
        case .sunny:
            Palette(background: Color(hex: 0xFFF8E7), surface: .white, ink: Color(hex: 0x14213D),
                    sky: Color(hex: 0x8ECAE6), skySoft: Color(hex: 0xD6ECF7),
                    sun: Color(hex: 0xFFC93C), sunSoft: Color(hex: 0xFFE9A8))
        case .dark:
            Palette(background: Color(hex: 0x10162B), surface: Color(hex: 0x1F2847), ink: Color(hex: 0xF3EEDC),
                    sky: Color(hex: 0x2F6F8F), skySoft: Color(hex: 0x2A4A63),
                    sun: Color(hex: 0x8A6B0E), sunSoft: Color(hex: 0x4A4020))
        case .ocean:
            Palette(background: Color(hex: 0xE8F7F5), surface: .white, ink: Color(hex: 0x0B3C49),
                    sky: Color(hex: 0x7FD1E0), skySoft: Color(hex: 0xCFEFF5),
                    sun: Color(hex: 0x3DDBC0), sunSoft: Color(hex: 0xB8F2E6))
        case .forest:
            Palette(background: Color(hex: 0xF1F7E9), surface: .white, ink: Color(hex: 0x1F3D2B),
                    sky: Color(hex: 0x9CCB86), skySoft: Color(hex: 0xD9EBCB),
                    sun: Color(hex: 0xF4A259), sunSoft: Color(hex: 0xFAD9B0))
        case .bubblegum:
            Palette(background: Color(hex: 0xFFF0F5), surface: .white, ink: Color(hex: 0x4A1942),
                    sky: Color(hex: 0xC8A2F0), skySoft: Color(hex: 0xE9D9FA),
                    sun: Color(hex: 0xFF8FB1), sunSoft: Color(hex: 0xFFD0DF))
        }
    }
}

private struct PaletteKey: EnvironmentKey {
    static let defaultValue = AppTheme.sunny.palette
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

extension Level {
    func color(in palette: Palette) -> Color {
        switch self {
        case .warmUp: palette.skySoft
        case .tinyStretch: palette.sky
        case .quietBrave: palette.sunSoft
        case .mediumBrave: palette.sun
        case .boldish: palette.ink.opacity(0.3)
        }
    }
}

extension BraveCategory {
    /// Connect is blue, Speak pink, Try green and Reset lavender. The dark theme gets deeper
    /// shades so its light ink stays readable on top of them.
    func color(in palette: Palette) -> Color {
        let dark = palette == AppTheme.dark.palette
        switch self {
        case .connect: return Color(hex: dark ? 0x2F6F8F : 0xBCE3E9)
        case .speak: return Color(hex: dark ? 0x8F4A5A : 0xF1A7AA)
        case .try: return Color(hex: dark ? 0x4C7A47 : 0xAFD5A2)
        case .reset: return Color(hex: dark ? 0x5E4F8A : 0xC9B9E7)
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

struct Chip: View {
    @Environment(\.palette) private var palette
    let title: String
    let selected: Bool
    var tint: Color?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.font(15, relativeTo: .subheadline))
                .foregroundStyle(palette.ink)
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .roughCard(fill: selected ? (tint ?? palette.sun) : palette.surface)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
