import SwiftUI

/// Proportions of the balloon body for a given fullness (0 = limp, 1 = fully inflated).
private enum BalloonShape {
    static func width(_ f: CGFloat) -> CGFloat { 0.78 + 0.22 * f }
    static func height(_ f: CGFloat) -> CGFloat { 0.72 + 0.28 * f }
}

/// Anchored at the knot: a limp balloon is a short, narrow, floppy pear that fills out into a round balloon.
private struct BalloonBody: Shape {
    var fullness: CGFloat
    var animatableData: CGFloat {
        get { fullness }
        set { fullness = newValue }
    }

    func path(in r: CGRect) -> Path {
        let f = fullness, slack = 1 - f
        let w = r.width * BalloonShape.width(f)
        let h = r.height * BalloonShape.height(f)
        let minX = r.midX - w / 2, maxX = r.midX + w / 2
        let top = r.maxY - h
        let widest = top + h * (0.42 + 0.26 * slack)
        let tipX = r.midX + w * 0.22 * slack
        let shoulderY = h * (0.12 + 0.22 * slack)
        let shoulderX = w * (0.25 + 0.2 * slack)
        let lowerY = widest + (r.maxY - widest) * 0.57

        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.maxY))
        p.addCurve(
            to: CGPoint(x: minX, y: widest),
            control1: CGPoint(x: minX + w * 0.15, y: r.maxY - h * 0.05),
            control2: CGPoint(x: minX, y: lowerY))
        p.addCurve(
            to: CGPoint(x: tipX, y: top),
            control1: CGPoint(x: minX, y: top + shoulderY),
            control2: CGPoint(x: minX + shoulderX, y: top))
        p.addCurve(
            to: CGPoint(x: maxX, y: widest),
            control1: CGPoint(x: maxX - shoulderX, y: top),
            control2: CGPoint(x: maxX, y: top + shoulderY))
        p.addCurve(
            to: CGPoint(x: r.midX, y: r.maxY),
            control1: CGPoint(x: maxX, y: lowerY),
            control2: CGPoint(x: maxX - w * 0.15, y: r.maxY - h * 0.05))
        p.closeSubpath()
        return p
    }
}

/// Creases across a limp balloon; fewer of them as it fills up.
private struct WrinkleShape: Shape {
    var count: Int

    func path(in r: CGRect) -> Path {
        var p = Path()
        let rows: [(y: CGFloat, dx: CGFloat, half: CGFloat)] = [(0.17, -0.04, 0.17), (0.25, 0.06, 0.14), (0.33, -0.08, 0.11)]
        for row in rows.prefix(count) {
            let y = r.minY + r.height * row.y
            let cx = r.midX + r.width * row.dx
            let half = r.width * row.half
            p.move(to: CGPoint(x: cx - half, y: y))
            p.addQuadCurve(to: CGPoint(x: cx + half, y: y), control: CGPoint(x: cx, y: y + r.height * 0.035))
        }
        return p
    }
}

private struct MouthShape: Shape {
    /// -1 frown ... 1 smile
    var curve: CGFloat
    var animatableData: CGFloat {
        get { curve }
        set { curve = newValue }
    }

    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.midY))
        p.addQuadCurve(
            to: CGPoint(x: r.maxX, y: r.midY),
            control: CGPoint(x: r.midX, y: r.midY + r.height * curve))
        return p
    }
}

private struct CrownShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + r.height * 0.2))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.25, y: r.minY + r.height * 0.55))
        p.addLine(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX + r.width * 0.75, y: r.minY + r.height * 0.55))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + r.height * 0.2))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct KnotShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

private struct StringShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addCurve(
            to: CGPoint(x: r.midX, y: r.maxY),
            control1: CGPoint(x: r.minX, y: r.height * 0.3),
            control2: CGPoint(x: r.maxX, y: r.height * 0.7))
        return p
    }
}

/// The balloon fill and crown stay the same whatever theme is selected; outline, face and creases follow the theme's ink color.
private enum BalloonColors {
    static let yellow = Color(hex: 0xFFC93C)
    static let sky = Color(hex: 0x8ECAE6)
}

/// `inflation` runs 0...1 in `BraveProgress.goal` steps; the balloon is drawn at a fixed 220x320 and scaled by `size`.
struct BalloonView: View {
    var inflation: Double
    var crown = false
    var happy = false
    var puff: CGFloat = 1
    var size: CGFloat = 1

    @Environment(\.palette) private var palette
    @State private var sway = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var stage: Int { Int((min(max(inflation, 0), 1) * Double(BraveProgress.goal)).rounded()) }
    /// Snapped to one of the discrete stages so each completed task is a visible step.
    private var level: Double { Double(stage) / Double(BraveProgress.goal) }
    private var fullness: CGFloat { CGFloat(level) }
    private var scale: CGFloat { (0.92 + 0.08 * fullness) * puff }
    private var bodyHeight: CGFloat { 240 * scale * BalloonShape.height(fullness) }
    /// Vertical offset from the frame's center to the center of the (bottom-anchored) body.
    private var bodyCenterY: CGFloat { (240 * scale - bodyHeight) / 2 }
    private var wrinkleCount: Int { level >= 0.8 ? 0 : level >= 0.6 ? 1 : level >= 0.3 ? 2 : 3 }

    var body: some View {
        VStack(spacing: 0) {
            balloonBody
            KnotShape()
                .fill(BalloonColors.yellow)
                .overlay(KnotShape().stroke(palette.ink, style: StrokeStyle(lineWidth: 3, lineJoin: .round)))
                .frame(width: 16, height: 12)
            StringShape()
                .stroke(palette.ink, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 24, height: 50)
        }
        .frame(width: 220, height: 320, alignment: .bottom)
        .rotationEffect(.degrees(reduceMotion ? 0 : (sway ? 3 : -3)), anchor: .bottom)
        .scaleEffect(size)
        .frame(width: 220 * size, height: 320 * size)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) { sway = true }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Yellow balloon, stage \(stage) of \(BraveProgress.goal)\(stage == BraveProgress.goal ? ", wearing a crown" : "")")
    }

    private var balloonBody: some View {
        ZStack {
            BalloonBody(fullness: fullness).fill(BalloonColors.yellow)
            BalloonBody(fullness: fullness).stroke(palette.ink, style: StrokeStyle(lineWidth: 4.5, lineJoin: .round))

            WrinkleShape(count: wrinkleCount)
                .stroke(palette.ink, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 200 * scale * BalloonShape.width(fullness), height: bodyHeight)
                .offset(y: bodyCenterY)
                .opacity(wrinkleCount > 0 ? 1 : 0)

            Capsule()
                .fill(Color.white.opacity(0.6))
                .frame(width: 10 * scale, height: 50 * scale * BalloonShape.height(fullness))
                .rotationEffect(.degrees(20))
                .offset(x: -62 * scale * BalloonShape.width(fullness), y: bodyCenterY - 48 * scale * BalloonShape.height(fullness))

            face

            if level < 0.3 && !happy {
                Image(systemName: "drop.fill")
                    .font(.system(size: 18 * scale))
                    .foregroundStyle(BalloonColors.sky)
                    .offset(x: 72 * scale * BalloonShape.width(fullness), y: bodyCenterY - 10 * scale)
            }
        }
        .frame(width: 200 * scale, height: 240 * scale)
        .overlay(alignment: .top) {
            if crown || stage == BraveProgress.goal {
                CrownShape()
                    .fill(BalloonColors.sky)
                    .overlay(CrownShape().stroke(palette.ink, style: StrokeStyle(lineWidth: 3.5, lineJoin: .round)))
                    .frame(width: 70 * scale, height: 36 * scale)
                    .offset(y: -18 * scale)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .rotationEffect(.degrees((1 - level) * -9), anchor: .bottom)
        .animation(.spring(response: 0.7, dampingFraction: 0.5), value: inflation)
        .animation(.spring(response: 0.5, dampingFraction: 0.4), value: puff)
        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: stage == BraveProgress.goal)
        .animation(.easeInOut(duration: 0.3), value: happy)
    }

    private var face: some View {
        VStack(spacing: 14 * scale) {
            HStack(spacing: 40 * scale * BalloonShape.width(fullness)) {
                Circle().fill(palette.ink).frame(width: 13 * scale, height: 13 * scale)
                Circle().fill(palette.ink).frame(width: 13 * scale, height: 13 * scale)
            }
            MouthShape(curve: happy ? 1.0 : -0.5 + 1.5 * level)
                .stroke(palette.ink, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: 44 * scale * BalloonShape.width(fullness), height: 24 * scale)
        }
        .offset(y: bodyCenterY + 12 * scale)
    }
}

#Preview {
    HStack {
        BalloonView(inflation: 0, size: 0.5)
        BalloonView(inflation: 0.5, size: 0.5)
        BalloonView(inflation: 1, crown: true, size: 0.5)
    }
    .padding()
    .screenBackground()
}
