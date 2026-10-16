import SwiftUI

/// The party at 30: a sky, the hatted balloon flying loops, confetti, and the three ways on.
struct FinaleView: View {
    let round: Int
    var onReel: () -> Void
    var onTrack: () -> Void
    var onNewRound: () -> Void
    var onClose: () -> Void

    @Environment(\.palette) private var palette
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let flight: [(t: Double, x: Double, y: Double, rot: Double)] = [
        (0, 0, 4, -4), (0.2, 43, -10, 8), (0.45, 17, -33, 2), (0.7, -43, -17, -8), (0.86, -18, 2, -5), (1, 0, 4, -4),
    ]

    private func offset(at phase: Double) -> (x: Double, y: Double, rot: Double) {
        let p = phase - floor(phase)
        guard let i = flight.indices.dropLast().last(where: { flight[$0].t <= p }) else { return (0, 4, -4) }
        let a = flight[i], b = flight[i + 1]
        let raw = (p - a.t) / (b.t - a.t)
        let e = raw * raw * (3 - 2 * raw)
        return (a.x + (b.x - a.x) * e, a.y + (b.y - a.y) * e, a.rot + (b.rot - a.rot) * e)
    }

    var body: some View {
        VStack(spacing: 0) {
            sky
            VStack(spacing: 0) {
                Text("ROUND \(round) COMPLETE")
                    .font(Theme.body(10.2, weight: .black))
                    .tracking(1.4)
                Text("thirty. whole. braves.")
                    .font(Theme.font(28, relativeTo: .title))
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .accessibilityIdentifier("finaleTitle")
                Text("The balloon has left the building. Everything you kept is waiting in Track.")
                    .font(Theme.body(14, weight: .regular))
                    .foregroundStyle(palette.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .padding(.top, 8)
                VStack(spacing: 11) {
                    Button(action: onReel) { Text("watch the reel") }
                        .buttonStyle(BigButtonStyle(fill: palette.blue))
                        .accessibilityIdentifier("finaleReel")
                    Button(action: onTrack) { Text("open track") }
                        .buttonStyle(BigButtonStyle(fill: palette.surface))
                        .accessibilityIdentifier("finaleTrack")
                    Button(action: onNewRound) { Text("new round") }
                        .buttonStyle(BigButtonStyle())
                        .accessibilityIdentifier("finaleNewRound")
                }
                .padding(.top, 20)
            }
            .padding(.horizontal, 22)
            .padding(.top, 22)
            .padding(.bottom, 26)
        }
        .overlay(alignment: .topTrailing) {
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .heavy))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.white))
                    .overlay(Circle().strokeBorder(palette.ink, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .padding(12)
            .accessibilityLabel("Close")
            .accessibilityIdentifier("closeFinale")
        }
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private var sky: some View {
        ZStack(alignment: .top) {
            LinearGradient(stops: [
                .init(color: Color(hex: 0x44ACD7), location: 0),
                .init(color: Color(hex: 0xBCEAF2), location: 0.72),
                .init(color: Color(hex: 0xF6D35A), location: 1),
            ], startPoint: .top, endPoint: .bottom)
            TimelineView(.animation(paused: reduceMotion)) { timeline in
                let o = reduceMotion ? (x: 0.0, y: 4.0, rot: -4.0) : offset(at: timeline.date.timeIntervalSinceReferenceDate / 7.2)
                BalloonView(inflation: 1, size: 0.7, hat: true)
                    .rotationEffect(.degrees(o.rot), anchor: UnitPoint(x: 0.5, y: 0.8))
                    .offset(x: o.x, y: o.y)
            }
            .padding(.top, 70)
            ConfettiRain(count: 14, fall: 340, seconds: 3.1)
        }
        .frame(height: 310)
        .clipped()
        .overlay(alignment: .bottom) { Rectangle().fill(palette.ink).frame(height: 2) }
    }
}
