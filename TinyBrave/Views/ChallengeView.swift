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

            TaskCardView(challenge: challenge, day: day)

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
