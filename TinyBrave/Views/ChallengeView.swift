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
    private var inflation: Double { BraveProgress.inflation(completed: BraveProgress.stage(completions)) }

    var body: some View {
        VStack(spacing: 12) {
            BalloonView(inflation: inflation, size: 0.42)

            Text(challenge.category.title.uppercased())
                .font(Theme.font(13, relativeTo: .caption))
                .tracking(1)
                .padding(.horizontal, 12)
                .frame(minHeight: 28)
                .roughCard(fill: palette.sky)

            VStack(spacing: 8) {
                Text("TODAY'S \(challenge.level.title.uppercased())")
                    .font(Theme.font(13, relativeTo: .caption))
                    .tracking(2)
                    .opacity(0.6)
                Text(challenge.text)
                    .font(Theme.font(24, relativeTo: .title2))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("challengeText")
                Text(challenge.why)
                    .font(.system(.subheadline, design: .rounded))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .opacity(0.75)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .roughCard()
            .id(challenge.id)
            .transition(.opacity)

            Text("Do it out in the world. Then come back.")
                .font(Theme.font(15, relativeTo: .subheadline))
                .opacity(0.7)

            Spacer(minLength: 0)

            VStack(spacing: 10) {
                Button("I did the brave thing", action: complete)
                    .buttonStyle(BigButtonStyle())
                Button("Not this one", action: swap)
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
