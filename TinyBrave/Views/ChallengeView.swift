import SwiftUI
import SwiftData

struct ChallengeView: View {
    @Binding var path: [Route]
    @State private var challenge: Challenge

    @Environment(\.palette) private var palette
    @Environment(\.modelContext) private var context
    @Query private var completions: [Completion]
    private let store = ChallengeStore.shared

    init(path: Binding<[Route]>, challenge: Challenge) {
        _path = path
        _challenge = State(initialValue: challenge)
    }

    private var completedIDs: Set<Int> { Set(completions.map(\.challengeID)) }
    /// The puff this task would earn, so the card reads "Day 6" after five tasks.
    private var day: Int { min(BraveProgress.stage(completions) + 1, BraveProgress.goal) }
    private var inflation: Double { BraveProgress.inflation(completed: BraveProgress.stage(completions)) }

    var body: some View {
        VStack(spacing: 12) {
            BalloonView(inflation: inflation, size: 0.42)

            taskCard

            Text("Do it out in the world. Then come back.")
                .font(Theme.font(15, relativeTo: .subheadline))
                .opacity(0.7)

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Button(action: complete) {
                    HStack(spacing: 8) {
                        Text("yep. did brave thing.")
                        Image(systemName: "checkmark").font(.system(size: 18, weight: .bold)).accessibilityHidden(true)
                    }
                }
                .buttonStyle(BigButtonStyle())
                .accessibilityLabel("yep. did brave thing.")
                Button("not this brave. give other.", action: swap)
                    .buttonStyle(BigButtonStyle(dashed: true))
            }
        }
        .padding(20)
        .screenBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var taskCard: some View {
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

    private func complete() {
        let debris = Debris.random()
        context.insert(Completion(challengeID: challenge.id, debrisKey: debris.id, date: AppClock.now))
        path.append(.reward(challengeID: challenge.id, debris: debris.id))
    }

    private func swap() {
        guard let next = store.pick(level: challenge.level, excluding: challenge.id, completed: completedIDs)
        else { return }
        withAnimation { challenge = next }
    }
}
