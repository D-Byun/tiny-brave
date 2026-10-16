import SwiftUI

/// The Home header: the running count, the balloon rising through a sky scene, and a 30-step track.
struct BraveMeterView: View {
    /// The puff count being shown; the caller steps it so changes animate.
    var puffs: Int
    var puff: CGFloat = 1

    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let sceneHeight: CGFloat = 290
    private let balloonSize: CGFloat = 0.6
    private let maxRise: CGFloat = 70

    private var done: Int { BraveProgress.done(puffs) }
    private var motion: BalloonScene.Motion { BalloonScene.motion(puffs: done) }

    var body: some View {
        VStack(spacing: 10) {
            header
            scene
            bar
            track
            Text(done == 0 ? BalloonCaption.text(puffs: 0) : "Puff \(done): \(BalloonCaption.text(puffs: done))")
                .font(Theme.font(17, relativeTo: .body))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("puffCaption")
        }
        .padding(14)
        .roughCard(fill: palette.skySoft)
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            Text("BRAVE-O-METER")
                .font(Theme.font(14, relativeTo: .footnote))
                .tracking(2)
            Spacer()
            Text("\(done)")
                .font(Theme.font(40, relativeTo: .largeTitle))
                .contentTransition(.numericText())
            Text("/\(BraveProgress.goal) tiny braves")
                .font(Theme.font(14, relativeTo: .footnote))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Brave-o-Meter, \(done) of \(BraveProgress.goal) tiny braves")
        .accessibilityIdentifier("braveCount")
    }

    private var scene: some View {
        ZStack(alignment: .bottom) {
            Ellipse()
                .fill(palette.ink.opacity(0.15))
                .frame(width: 150 - 60 * motion.lift, height: 16)
            BalloonView(inflation: BraveProgress.inflation(completed: done), puff: puff, size: balloonSize)
                .offset(x: motion.drift, y: -maxRise * motion.lift)
                .padding(.bottom, 12)
        }
        .frame(maxWidth: .infinity)
        .frame(height: sceneHeight - 100)
        .animation(reduceMotion ? nil : .spring(response: 0.9, dampingFraction: 0.65), value: done)
    }

    private var bar: some View {
        GeometryReader { geo in
            let fraction = BraveProgress.inflation(completed: done)
            ZStack(alignment: .leading) {
                Capsule().fill(palette.surface)
                Capsule().fill(palette.ink)
                    .frame(width: max(geo.size.width * fraction, fraction > 0 ? 14 : 0))
            }
            .overlay(Capsule().stroke(palette.ink, lineWidth: 3))
        }
        .frame(height: 16)
        .animation(reduceMotion ? nil : .spring, value: done)
        .accessibilityHidden(true)
    }

    private var track: some View {
        HStack(spacing: 3) {
            ForEach(0..<BraveProgress.goal, id: \.self) { index in
                Capsule()
                    .fill(index < done ? palette.ink : palette.ink.opacity(0.2))
                    .frame(height: 5)
            }
        }
        .accessibilityHidden(true)
    }
}

#Preview {
    VStack {
        BraveMeterView(puffs: 0)
        BraveMeterView(puffs: 15)
    }
    .padding()
    .screenBackground()
}
