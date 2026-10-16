import SwiftUI

/// The Home sky: the running count, the balloon rising and gliding, a 30-step meter and a caption.
struct BraveMeterView: View {
    /// The puff count being shown; the caller steps it so changes animate.
    var puffs: Int
    var puff: CGFloat = 1
    /// People in the user's circle, when they have one.
    var circleCount: Int?

    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let stageHeight: CGFloat = 350

    private var done: Int { BraveProgress.done(puffs) }
    private var progress: Double { Double(done) / Double(BraveProgress.goal) }
    private var motion: BalloonScene.Motion { BalloonScene.motion(puffs: done) }
    private var scene: BalloonScene { BalloonScene.stage(puffs: done) }
    private var sky: LinearGradient {
        let colors = BalloonScene.sky(puffs: done)
        func color(_ c: (Double, Double, Double)) -> Color { Color(red: c.0 / 255, green: c.1 / 255, blue: c.2 / 255) }
        return LinearGradient(colors: [color(colors.top), color(colors.bottom)], startPoint: .top, endPoint: .bottom)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            balloonStage
                .padding(.top, -6)
            bar
            marks
            Text(done == 0 ? BalloonCaption.text(puffs: 0) : "Puff \(done): \(BalloonCaption.text(puffs: done))")
                .font(Theme.body(12, weight: .heavy))
                .multilineTextAlignment(.center)
                .padding(.top, 8)
                .accessibilityIdentifier("puffCaption")
        }
        .padding(.horizontal, 23)
        .padding(.top, 15)
        .padding(.bottom, 21)
        .frame(maxWidth: .infinity)
        .background(sky.animation(.easeInOut(duration: 1.2), value: done))
        .overlay(alignment: .bottom) { Rectangle().fill(palette.ink).frame(height: 2) }
        .foregroundStyle(palette.ink)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                Text("BRAVE-O-METER")
                    .font(Theme.body(10.5, weight: .black))
                    .tracking(1.6)
                if let circleCount {
                    HStack(spacing: 6) {
                        Circle().fill(Color(hex: 0x3F9C62)).frame(width: 7, height: 7)
                            .overlay(Circle().stroke(Color(hex: 0x3F9C62).opacity(0.18), lineWidth: 2))
                        Text("\(circleCount) in circle").font(Theme.body(10, weight: .heavy))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 5)
                    .background(Capsule().fill(Color.white.opacity(0.55)))
                    .overlay(Capsule().strokeBorder(palette.ink, lineWidth: 1.5))
                    .padding(.top, 8)
                    .accessibilityElement(children: .combine)
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(done)")
                    .font(Theme.body(32, weight: .black))
                    .contentTransition(.numericText())
                Text("/\(BraveProgress.goal) tiny braves")
                    .font(Theme.body(11.2, weight: .heavy))
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Brave-o-Meter, \(done) of \(BraveProgress.goal) tiny braves")
            .accessibilityIdentifier("braveCount")
        }
    }

    private var balloonStage: some View {
        GeometryReader { geo in
            ZStack {
                Ellipse()
                    .fill(palette.ink.opacity(0.16 - 0.08 * progress))
                    .frame(width: 128 - 58 * progress, height: 13)
                    .position(x: geo.size.width / 2, y: geo.size.height - 14)
                    .animation(.easeInOut(duration: 1.3), value: done)

                TimelineView(.animation(paused: reduceMotion)) { timeline in
                    let phase = timeline.date.timeIntervalSinceReferenceDate / 8.8
                    let glide = reduceMotion ? BalloonScene.Offset(x: 0, y: 0, tilt: 0) : scene.glideOffset(phase: phase)
                    BalloonView(inflation: progress, puff: puff, hat: scene == .final, squash: true)
                        .shadow(color: scene == .final ? .white.opacity(0.8) : .clear, radius: 13)
                        .rotationEffect(.degrees(glide.tilt), anchor: UnitPoint(x: 0.5, y: 0.82))
                        .offset(x: glide.x, y: glide.y)
                }
                .offset(x: motion.drift, y: 50 - 82 * motion.lift)
                .animation(reduceMotion ? nil : .timingCurve(0.16, 1, 0.3, 1, duration: 2.2), value: done)
                .position(x: geo.size.width / 2, y: geo.size.height * 0.51)

                if scene == .final {
                    ConfettiRain()
                        .transition(.opacity)
                }
            }
        }
        .frame(height: stageHeight)
        .clipped()
        .animation(.easeInOut(duration: 0.5), value: scene)
    }

    private var bar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.5))
                Rectangle().fill(palette.ink)
                    .frame(width: geo.size.width * progress)
            }
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(palette.ink, lineWidth: 2))
        }
        .frame(height: 10)
        .animation(reduceMotion ? nil : .easeOut(duration: 0.7), value: done)
        .accessibilityHidden(true)
    }

    private var marks: some View {
        HStack(spacing: 2) {
            ForEach(0..<BraveProgress.goal, id: \.self) { index in
                Capsule()
                    .fill(index < done ? palette.ink : palette.ink.opacity(0.2))
                    .frame(height: 4)
                    .offset(y: index < done ? -1 : 0)
            }
        }
        .padding(.top, 8)
        .animation(.easeOut(duration: 0.25), value: done)
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack {
        BraveMeterView(puffs: 5, circleCount: 1)
        BraveMeterView(puffs: 30)
    }
    .screenBackground()
}
