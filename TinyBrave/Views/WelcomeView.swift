import SwiftUI

struct WelcomeView: View {
    let onOpen: () -> Void
    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(hex: 0xF7D44F).ignoresSafeArea()
            DotGrain(color: palette.ink, opacity: 0.18).ignoresSafeArea()

            Text("TINY BRAVE")
                .font(Theme.body(11.5, weight: .black))
                .tracking(2.1)
                .padding(.top, 23)
                .padding(.leading, 24)

            TimelineView(.animation(paused: reduceMotion)) { timeline in
                let glide = reduceMotion
                    ? BalloonScene.Offset(x: 0, y: 0, tilt: 0)
                    : BalloonScene.sway.glideOffset(phase: timeline.date.timeIntervalSinceReferenceDate / 7.8)
                BalloonView(inflation: 1)
                    .rotationEffect(.degrees(glide.tilt), anchor: UnitPoint(x: 0.5, y: 0.82))
                    .offset(x: glide.x, y: glide.y)
            }
            .shadow(color: palette.ink.opacity(0.2), radius: 0, x: 7, y: 9)
            .rotationEffect(.degrees(7), anchor: UnitPoint(x: 0.5, y: 0.45))
            .scaleEffect(0.9, anchor: UnitPoint(x: 0.5, y: 0.45))
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 28)
            .padding(.top, 35)
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                Text("psst.")
                    .font(Theme.font(16, relativeTo: .headline))
                    .rotationEffect(.degrees(-4), anchor: .bottomLeading)
                    .padding(.bottom, 8)
                Text("there is one brave thing in here.")
                    .font(Theme.font(48, relativeTo: .largeTitle))
                    .tracking(-2.6)
                    .lineSpacing(-14)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 28)
                    .accessibilityIdentifier("welcomeHeadline")

                Button(action: onOpen) {
                    HStack {
                        Text("open carefully")
                        Spacer()
                        SkewedArrow()
                            .stroke(palette.ink, style: StrokeStyle(lineWidth: 3, lineCap: .square, lineJoin: .miter))
                            .frame(width: 36, height: 20)
                            .accessibilityHidden(true)
                    }
                    .font(Theme.font(17, relativeTo: .title3))
                    .padding(.leading, 22)
                    .padding(.trailing, 18)
                    .frame(minHeight: 62)
                    .frame(maxWidth: .infinity)
                    .background(doorShape.fill(palette.surface))
                    .overlay(doorShape.strokeBorder(palette.ink, lineWidth: 2.5))
                    .background(doorShape.fill(palette.ink).offset(x: 7, y: 8))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 7)

                Text("about three minutes. possibly less.")
                    .font(Theme.body(11, weight: .bold))
                    .frame(maxWidth: .infinity)
                    .padding(.top, 17)
            }
            .frame(maxWidth: 460)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .foregroundStyle(palette.ink)
    }

    private var doorShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 28, bottomLeadingRadius: 19, bottomTrailingRadius: 27, topTrailingRadius: 20, style: .continuous)
    }
}

private struct SkewedArrow: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + 4, y: r.maxY - 3))
        p.addLine(to: CGPoint(x: r.maxX - 8, y: r.maxY - 3))
        p.move(to: CGPoint(x: r.maxX - 16, y: r.minY + 2))
        p.addLine(to: CGPoint(x: r.maxX - 6, y: r.maxY - 3))
        p.addLine(to: CGPoint(x: r.maxX - 16, y: r.maxY + 3))
        return p.applying(CGAffineTransform(a: 1, b: 0, c: -0.53, d: 1, tx: 0, ty: 0))
    }
}

#Preview {
    WelcomeView {}
}
