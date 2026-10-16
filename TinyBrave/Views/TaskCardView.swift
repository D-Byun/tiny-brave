import SwiftUI

/// The taped-paper card showing the current challenge.
struct TaskCardView: View {
    let challenge: Challenge
    let day: Int
    let round: Int

    @Environment(\.palette) private var palette

    private var kicker: String {
        "DAY \(day) · ROUND \(round)" + (Rounds.isAllNew(round) ? " · ALL NEW" : "")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(challenge.category.title.uppercased())
                    .font(Theme.font(11.5, relativeTo: .caption))
                    .tracking(0.7)
                    .padding(.horizontal, 10)
                    .padding(.top, 7)
                    .padding(.bottom, 6)
                    .background(pill.fill(challenge.category.color))
                    .overlay(pill.strokeBorder(palette.ink, lineWidth: 2))
                    .rotationEffect(.degrees(-2))
                Spacer()
                Text(challenge.level.rawValue)
                    .font(Theme.font(12.5, relativeTo: .caption))
                    .foregroundStyle(palette.muted)
            }
            Text(kicker)
                .font(Theme.font(10, relativeTo: .caption))
                .tracking(1.3)
                .padding(.top, 17)
                .accessibilityIdentifier("dayRound")
            Text(challenge.text)
                .font(Theme.font(34, relativeTo: .title))
                .lineSpacing(-2)
                .tracking(-0.8)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)
                .padding(.bottom, 10)
                .accessibilityIdentifier("challengeText")
            Text(challenge.why)
                .font(Theme.body(14, weight: .regular))
                .lineSpacing(4)
                .foregroundStyle(Color(hex: 0x59564E))
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: 38, alignment: .topLeading)
        }
        .padding(.horizontal, 21)
        .padding(.top, 24)
        .padding(.bottom, 22)
        .frame(maxWidth: .infinity, minHeight: 205, alignment: .topLeading)
        .background(card.fill(palette.surface))
        .overlay(card.strokeBorder(palette.ink, lineWidth: 2.5))
        .overlay(alignment: .bottomTrailing) { scribble }
        .background(card.fill(palette.ink).offset(x: 6, y: 7))
        .overlay(alignment: .top) {
            HStack {
                tape(palette.blue.opacity(0.9), angle: -7)
                Spacer()
                tape(palette.pink.opacity(0.82), angle: 8)
            }
            .padding(.horizontal, 26)
            .offset(y: -10)
            .accessibilityHidden(true)
        }
        .rotationEffect(.degrees(-0.35))
        .id(challenge.id)
        .transition(.opacity)
    }

    private var card: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 25, bottomLeadingRadius: 20, bottomTrailingRadius: 28, topTrailingRadius: 17, style: .continuous)
    }

    private var pill: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 15, bottomLeadingRadius: 13, bottomTrailingRadius: 16, topTrailingRadius: 13, style: .continuous)
    }

    private var scribble: some View {
        Circle()
            .trim(from: 0.55, to: 0.95)
            .stroke(Color(hex: 0x8B867B), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            .frame(width: 39, height: 39)
            .frame(width: 39, height: 13, alignment: .top)
            .rotationEffect(.degrees(-9))
            .padding(.trailing, 22)
            .padding(.bottom, 15)
            .accessibilityHidden(true)
    }

    private func tape(_ color: Color, angle: Double) -> some View {
        Rectangle()
            .fill(color)
            .frame(width: 52, height: 18)
            .overlay(Rectangle().stroke(palette.ink.opacity(0.45), lineWidth: 1.5))
            .rotationEffect(.degrees(angle))
    }
}
