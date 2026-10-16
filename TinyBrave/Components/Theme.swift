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
    /// The cream panel behind the task card.
    var background: Color
    /// Paper: cards, buttons and pills.
    var surface: Color
    var ink: Color
    var muted: Color
    var line: Color
    var sun: Color
    var sunDeep: Color
    var blue: Color
    var pink: Color
    var green: Color
    var lavender: Color
    /// The tray behind the draw and video tabs.
    var dock: Color
}

extension Palette {
    static let standard = Palette(
        background: Color(hex: 0xF6F0E3), surface: Color(hex: 0xFFFAF0), ink: Color(hex: 0x181813),
        muted: Color(hex: 0x625F56), line: Color(hex: 0xD9D2C2),
        sun: Color(hex: 0xF6CF45), sunDeep: Color(hex: 0xD9A90B),
        blue: Color(hex: 0xBCE3E9), pink: Color(hex: 0xF1A7AA), green: Color(hex: 0xAFD5A2), lavender: Color(hex: 0xC9B9E7),
        dock: Color(hex: 0xD9EEE8)
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

    static func body(_ size: CGFloat, weight: Font.Weight = .bold, relativeTo style: Font.TextStyle = .body) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }
}

extension BraveCategory {
    /// Connect is blue, Speak pink, Try green and Reset lavender.
    var color: Color {
        switch self {
        case .connect: Palette.standard.blue
        case .speak: Palette.standard.pink
        case .try: Palette.standard.green
        case .reset: Palette.standard.lavender
        }
    }
}

func roughRect(_ radius: CGFloat = 1) -> UnevenRoundedRectangle {
    UnevenRoundedRectangle(
        topLeadingRadius: 16 * radius, bottomLeadingRadius: 22 * radius,
        bottomTrailingRadius: 14 * radius, topTrailingRadius: 20 * radius,
        style: .continuous
    )
}

/// A hand-cut blob; the corners are uneven so no two cards look machine-made.
private struct RoughCard: ViewModifier {
    @Environment(\.palette) private var palette
    let fill: Color?
    let lineWidth: CGFloat
    let shadow: CGSize

    func body(content: Content) -> some View {
        content
            .background(roughRect().fill(fill ?? palette.surface))
            .overlay(roughRect().strokeBorder(palette.ink, lineWidth: lineWidth))
            .background {
                if shadow != .zero { roughRect().fill(palette.ink).offset(x: shadow.width, y: shadow.height) }
            }
    }
}

/// Tiny ink dots on an 8-point grid, like a risograph print.
struct DotGrain: View {
    var color: Color
    var opacity: Double

    var body: some View {
        Canvas { context, size in
            let spacing: CGFloat = 8
            var path = Path()
            var y: CGFloat = 2
            while y < size.height {
                var x: CGFloat = 2
                while x < size.width {
                    path.addEllipse(in: CGRect(x: x, y: y, width: 1.3, height: 1.3))
                    x += spacing
                }
                y += spacing
            }
            context.fill(path, with: .color(color.opacity(opacity)))
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct ScreenBackground: ViewModifier {
    @Environment(\.palette) private var palette
    let grain: Double

    func body(content: Content) -> some View {
        content
            .foregroundStyle(palette.ink)
            .background {
                ZStack {
                    palette.background
                    DotGrain(color: palette.ink, opacity: grain)
                }
                .ignoresSafeArea()
            }
    }
}

extension View {
    /// Uses the theme's paper color when `fill` is nil.
    func roughCard(fill: Color? = nil, lineWidth: CGFloat = 2.5, shadow: CGSize = .zero) -> some View {
        modifier(RoughCard(fill: fill, lineWidth: lineWidth, shadow: shadow))
    }

    /// Cream panel with a dot grain; also sets ink as the default foreground style.
    func screenBackground(grain: Double = 0.11) -> some View { modifier(ScreenBackground(grain: grain)) }
}

struct BigButtonStyle: ButtonStyle {
    @Environment(\.palette) private var palette
    var fill: Color?
    var dashed = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.font(dashed ? 16 : 21, relativeTo: .title3))
            .foregroundStyle(palette.ink)
            .frame(maxWidth: .infinity, minHeight: dashed ? 48 : 58)
            .padding(.horizontal, 12)
            .background(dashed ? AnyShapeStyle(Color.clear) : AnyShapeStyle(fill ?? palette.sun), in: dashed ? AnyShape(Capsule()) : AnyShape(roughRect()))
            .overlay {
                if dashed {
                    Capsule().strokeBorder(palette.ink, style: StrokeStyle(lineWidth: 2, dash: [6, 5]))
                } else {
                    roughRect().strokeBorder(palette.ink, lineWidth: 2.5)
                }
            }
            .background {
                if !dashed { roughRect().fill(palette.ink).offset(x: 4, y: 5) }
            }
            .offset(x: configuration.isPressed ? 2 : 0, y: configuration.isPressed ? 3 : 0)
    }
}

/// The cream pills in the yellow top bar and sheet headers.
struct PillLabel: View {
    @Environment(\.palette) private var palette
    let title: String
    let symbol: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: symbol).font(.system(size: 13, weight: .bold)).accessibilityHidden(true)
            Text(title).font(Theme.body(14, weight: .heavy))
        }
        .foregroundStyle(palette.ink)
        .padding(.horizontal, 12)
        .frame(minHeight: 44)
        .background(Capsule().fill(palette.surface))
        .overlay(Capsule().strokeBorder(palette.ink, lineWidth: 1.8))
        .contentShape(Capsule())
    }
}
