import SwiftUI

/// The taped-paper card showing one challenge, shared by Home and the challenge screen.
struct TaskCardView: View {
    let challenge: Challenge
    let day: Int

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(challenge.category.title.uppercased())
                    .font(Theme.font(13, relativeTo: .caption))
                    .tracking(1)
                    .padding(.horizontal, 12)
                    .frame(minHeight: 28)
                    .roughCard(fill: challenge.category.color(in: palette))
                Spacer()
                Text(challenge.level.rawValue)
                    .font(Theme.font(15, relativeTo: .subheadline))
                    .opacity(0.6)
            }
            Text("DAY \(day) · ROUND \(BraveProgress.round)")
                .font(Theme.font(12, relativeTo: .caption))
                .tracking(2)
                .opacity(0.6)
                .accessibilityIdentifier("dayRound")
            Text(challenge.text)
                .font(Theme.font(28, relativeTo: .title))
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("challengeText")
            Text(challenge.why)
                .font(.system(.subheadline, design: .rounded))
                .fixedSize(horizontal: false, vertical: true)
                .opacity(0.75)
        }
        .padding(.horizontal, 20)
        .padding(.top, 26)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .topLeading)
        .roughCard()
        .background(roughRect().fill(palette.ink).offset(x: 5, y: 6))
        .overlay(alignment: .top) {
            HStack {
                tape(palette.sky, angle: -7)
                Spacer()
                tape(palette.sunSoft, angle: 8)
            }
            .padding(.horizontal, 26)
            .offset(y: -10)
            .accessibilityHidden(true)
        }
        .rotationEffect(.degrees(-0.35))
        .padding(.top, 8)
        .id(challenge.id)
        .transition(.opacity)
    }

    private func tape(_ color: Color, angle: Double) -> some View {
        Rectangle()
            .fill(color.opacity(0.9))
            .frame(width: 52, height: 18)
            .overlay(Rectangle().stroke(palette.ink.opacity(0.45), lineWidth: 1.5))
            .rotationEffect(.degrees(angle))
    }
}
