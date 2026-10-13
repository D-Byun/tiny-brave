import SwiftUI
import SwiftData

struct RewardView: View {
    @Binding var path: [Route]
    let challengeID: Int
    let debrisKey: String

    @Environment(\.palette) private var palette
    @Query(sort: \Completion.date, order: .reverse) private var completions: [Completion]
    @State private var revealed = false
    @State private var puff: CGFloat = 1
    @AppStorage(Username.storageKey) private var username = ""
    @State private var line = ["Tiny brave acquired.", "That counted."].randomElement()!
    private let store = ChallengeStore.shared

    private var completedIDs: Set<Int> { Set(completions.map(\.challengeID)) }
    /// True when this completion is the day's first, the only one that extends the streak.
    private var isFirstToday: Bool { DailyGoal.completedToday(completions) == 1 }
    private var activeDays: Int { DailyGoal.activeDays(completions) }
    /// The balloon stays at its previous stage here; the home screen animates the change.
    private var balloonInflation: Double {
        BraveProgress.inflation(completed: BraveProgress.stage(Array(completions.dropFirst())))
    }
    private var milestone: Certificate? {
        isFirstToday ? Certificate.all.first { $0.count == activeDays } : nil
    }
    private var selectedAwkwardness: Int? { completions.first?.awkwardness }

    var body: some View {
        VStack(spacing: 10) {
            BalloonView(inflation: balloonInflation, happy: revealed, puff: puff, size: 0.62)

            Text(line).font(Theme.font(24, relativeTo: .title2))
            Text(Username.clean(username).isEmpty ? "Nobody exploded." : "Nobody exploded, \(Username.clean(username)).")
                .font(Theme.font(15, relativeTo: .subheadline))
                .opacity(0.7)

            if let debris = Debris.find(debrisKey) {
                VStack(spacing: 4) {
                    Text(debris.emoji)
                        .font(.system(size: 30))
                        .frame(width: 60, height: 60)
                        .roughCard()
                        .rotationEffect(.degrees(-4))
                    Text("You found \(debris.name).")
                        .font(.system(.footnote, design: .rounded))
                        .opacity(0.75)
                }
            }

            if let milestone {
                Text("🏅 \(milestone.title)")
                    .font(Theme.font(16, relativeTo: .body))
                    .padding(.horizontal, 12)
                    .frame(minHeight: 40)
                    .roughCard(fill: palette.sunSoft)
            }

            Text(isFirstToday
                 ? "🔥 \(DailyGoal.streakText(DailyGoal.streak(completions)))"
                 : "Bonus brave! Your balloon and streak already counted today.")
                .font(Theme.font(15, relativeTo: .subheadline))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("rewardStreak")

            awkwardnessCheck

            Spacer(minLength: 0)

            HStack(spacing: 10) {
                Button("Another one", action: another)
                    .buttonStyle(BigButtonStyle())
                Button("Done") { path = [] }
                    .buttonStyle(BigButtonStyle(dashed: true))
            }
        }
        .padding(20)
        .screenBackground()
        .navigationBarBackButtonHidden(true)
        .sensoryFeedback(.success, trigger: revealed)
        .task {
            try? await Task.sleep(for: .milliseconds(350))
            revealed = true
            puff = 1.25
            try? await Task.sleep(for: .milliseconds(450))
            puff = 1
        }
    }

    private var awkwardnessCheck: some View {
        VStack(spacing: 6) {
            Text("Optional · private · one tap")
                .font(.system(.caption2, design: .rounded))
                .opacity(0.65)
            HStack {
                ForEach(Array(["😌", "😬", "🫠"].enumerated()), id: \.offset) { index, face in
                    Button {
                        completions.first?.awkwardness = index
                    } label: {
                        Text(face)
                            .font(.system(size: 26))
                            .frame(width: 56, height: 48)
                            .background(roughRect().fill(selectedAwkwardness == index ? palette.sunSoft : .clear))
                            .overlay(roughRect().strokeBorder(selectedAwkwardness == index ? palette.ink : .clear, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(["Less awkward than expected", "About as awkward as expected", "More awkward than expected"][index])
                    if index < 2 { Spacer() }
                }
            }
        }
        .padding(10)
        .roughCard()
    }

    private func another() {
        let level = store.challenge(id: challengeID)?.level
        if let next = store.pick(level: level, excluding: challengeID, completed: completedIDs) {
            path = [.challenge(next.id)]
        } else {
            path = []
        }
    }
}
