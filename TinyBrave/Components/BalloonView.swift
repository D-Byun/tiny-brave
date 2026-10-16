import SwiftUI

/// A balloon body whose corners get rounder as it fills: a lumpy, squarish blob at 0, a plump round one at 1.
private struct BlobShape: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in r: CGRect) -> Path {
        let w = r.width, h = r.height, k: CGFloat = 0.5523
        let tl = 0.38 + 0.11 * progress, tr = 0.43 + 0.08 * progress, br: CGFloat = 0.48, bl: CGFloat = 0.51
        var p = Path()
        p.move(to: CGPoint(x: r.minX + tl * w, y: r.minY))
        p.addLine(to: CGPoint(x: r.minX + w - tr * w, y: r.minY))
        p.addCurve(
            to: CGPoint(x: r.maxX, y: r.minY + tr * h),
            control1: CGPoint(x: r.minX + w - tr * w + k * tr * w, y: r.minY),
            control2: CGPoint(x: r.maxX, y: r.minY + tr * h - k * tr * h))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + h - br * h))
        p.addCurve(
            to: CGPoint(x: r.minX + w - br * w, y: r.maxY),
            control1: CGPoint(x: r.maxX, y: r.minY + h - br * h + k * br * h),
            control2: CGPoint(x: r.minX + w - br * w + k * br * w, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX + bl * w, y: r.maxY))
        p.addCurve(
            to: CGPoint(x: r.minX, y: r.minY + h - bl * h),
            control1: CGPoint(x: r.minX + bl * w - k * bl * w, y: r.maxY),
            control2: CGPoint(x: r.minX, y: r.minY + h - bl * h + k * bl * h))
        p.addLine(to: CGPoint(x: r.minX, y: r.minY + tl * h))
        p.addCurve(
            to: CGPoint(x: r.minX + tl * w, y: r.minY),
            control1: CGPoint(x: r.minX, y: r.minY + tl * h - k * tl * h),
            control2: CGPoint(x: r.minX + tl * w - k * tl * w, y: r.minY))
        p.closeSubpath()
        return p
    }
}

private struct ArcShine: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.addArc(center: CGPoint(x: r.maxX, y: r.midY), radius: r.height / 2, startAngle: .degrees(270), endAngle: .degrees(90), clockwise: true)
        return p
    }
}

private struct SmileShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY), control: CGPoint(x: r.midX, y: r.maxY * 2 - r.minY))
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
        p.move(to: CGPoint(x: r.maxX, y: r.minY))
        p.addCurve(
            to: CGPoint(x: r.minX + r.width * 0.1, y: r.maxY),
            control1: CGPoint(x: r.maxX + r.width * 0.1, y: r.height * 0.45),
            control2: CGPoint(x: r.width * 0.55, y: r.height * 0.95))
        return p
    }
}

private struct TriangleShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// The striped party hat the balloon earns at 30.
struct PartyHat: View {
    @Environment(\.palette) private var palette
    var width: CGFloat = 64

    private var height: CGFloat { width * 0.95 }

    var body: some View {
        ZStack(alignment: .top) {
            TriangleShape()
                .fill(LinearGradient(stops: [
                    .init(color: Color(hex: 0xE65345), location: 0), .init(color: Color(hex: 0xE65345), location: 0.18),
                    .init(color: palette.surface, location: 0.18), .init(color: palette.surface, location: 0.36),
                    .init(color: Color(hex: 0x6FC7DC), location: 0.36), .init(color: Color(hex: 0x6FC7DC), location: 0.54),
                    .init(color: Color(hex: 0xE65345), location: 0.54), .init(color: Color(hex: 0xE65345), location: 0.72),
                    .init(color: palette.surface, location: 0.72), .init(color: palette.surface, location: 0.9),
                    .init(color: Color(hex: 0x6FC7DC), location: 0.9), .init(color: Color(hex: 0x6FC7DC), location: 1),
                ], startPoint: UnitPoint(x: 0, y: 0.35), endPoint: UnitPoint(x: 1, y: 0.65)))
                .background(TriangleShape().fill(palette.ink).offset(x: 2, y: 2))
                .frame(width: width, height: height)
            Circle()
                .fill(palette.sun)
                .overlay(Circle().strokeBorder(palette.ink, lineWidth: 2))
                .frame(width: width * 0.22, height: width * 0.22)
                .offset(y: -width * 0.1)
        }
        .accessibilityHidden(true)
    }
}

/// `inflation` runs 0...1 in `BraveProgress.goal` steps. The balloon is laid out at 176 by 292 and scaled by `size`.
struct BalloonView: View {
    var inflation: Double
    var puff: CGFloat = 1
    var size: CGFloat = 1
    var hat = false
    /// Flattens a barely inflated balloon the way the Home scene does.
    var squash = false

    @Environment(\.palette) private var palette

    private var stage: Int { Int((min(max(inflation, 0), 1) * Double(BraveProgress.goal)).rounded()) }
    /// Snapped to one of the discrete stages so each completed task is a visible step.
    private var level: CGFloat { CGFloat(stage) / CGFloat(BraveProgress.goal) }
    private var squashScale: CGSize {
        guard squash else { return CGSize(width: 1, height: 1) }
        let eased = 1 - pow(1 - level, 3)
        return CGSize(width: 0.80 + 0.28 * level, height: 0.64 + 0.44 * eased)
    }

    private let yellow = Color(hex: 0xFFD846)

    var body: some View {
        ZStack(alignment: .top) {
            string
            knot
            balloonBody
            if hat {
                PartyHat()
                    .rotationEffect(.degrees(-6), anchor: .bottom)
                    .offset(y: -42)
                    .transition(.scale(scale: 0.75, anchor: .bottom).combined(with: .opacity))
            }
        }
        .frame(width: 176, height: 292, alignment: .top)
        .scaleEffect(x: squashScale.width * puff, y: squashScale.height * puff, anchor: UnitPoint(x: 0.5, y: 0.82))
        .scaleEffect(size, anchor: .topLeading)
        .frame(width: 176 * size, height: 292 * size, alignment: .topLeading)
        .animation(.spring(response: 0.7, dampingFraction: 0.55), value: stage)
        .animation(.spring(response: 0.5, dampingFraction: 0.45), value: puff)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Yellow balloon, stage \(stage) of \(BraveProgress.goal)\(stage == BraveProgress.goal ? ", wearing a party hat" : "")")
    }

    private var balloonBody: some View {
        let blob = BlobShape(progress: level)
        return ZStack(alignment: .topLeading) {
            blob.fill(palette.ink.opacity(0.92)).offset(x: 6, y: 8)
            blob.fill(yellow)
            blob.fill(palette.sunDeep.opacity(0.18))
                .mask {
                    Rectangle().overlay { blob.offset(x: -16, y: -15).blendMode(.destinationOut) }.compositingGroup()
                }
            blob.stroke(palette.ink, lineWidth: 3)

            ArcShine()
                .stroke(Color.white.opacity(0.6), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 22, height: 43)
                .offset(x: 37, y: 38)
                .opacity(0.35 + 0.65 * level)

            face
        }
        .frame(width: 176, height: 232)
    }

    private var face: some View {
        ZStack(alignment: .topLeading) {
            Ellipse().fill(palette.ink).frame(width: 7, height: 9).offset(x: 56, y: 105)
            Ellipse().fill(palette.ink).frame(width: 7, height: 9).offset(x: 113, y: 105)
            SmileShape()
                .stroke(palette.ink, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .frame(width: 14 + 10 * level, height: (5 + 10 * level) * (0.35 + 0.65 * level))
                .offset(x: 88 - (14 + 10 * level) / 2, y: 150)
        }
    }

    private var knot: some View {
        KnotShape()
            .fill(palette.sunDeep)
            .overlay(KnotShape().stroke(palette.ink, style: StrokeStyle(lineWidth: 3, lineJoin: .round)))
            .frame(width: 28, height: 25)
            .offset(y: 220)
    }

    private var string: some View {
        StringShape()
            .stroke(palette.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .frame(width: 38, height: 59)
            .offset(x: 10, y: 242)
    }
}

#Preview {
    HStack {
        BalloonView(inflation: 0, size: 0.5, squash: true)
        BalloonView(inflation: 0.5, size: 0.5)
        BalloonView(inflation: 1, size: 0.5, hat: true)
    }
    .padding()
    .screenBackground()
}
