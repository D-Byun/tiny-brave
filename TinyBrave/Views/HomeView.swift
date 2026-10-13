import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var path: [Route]
    @Environment(\.palette) private var palette
    @AppStorage(Username.storageKey) private var username = ""
    @AppStorage(AppClock.offsetKey) private var dayOffset = 0
    @AppStorage(BraveProgress.lastSeenStageKey) private var lastSeenStage = -1
    @State private var puff: CGFloat = 1
    @Query private var completions: [Completion]
    private let store = ChallengeStore.shared

    private var completedIDs: Set<Int> { Set(completions.map(\.challengeID)) }
    private var now: Date { AppClock.now(offsetDays: dayOffset) }
    private var doneToday: Bool { DailyGoal.isDoneToday(completions, now: now) }
    private var streak: Int { DailyGoal.streak(completions, now: now) }
    private var stage: Int { BraveProgress.stage(completions) }
    /// The stage currently drawn; it steps toward `stage` so changes animate.
    private var shownStage: Int { lastSeenStage >= 0 ? lastSeenStage : stage }
    private var name: String { Username.clean(username) }
    private var inflation: Double { BraveProgress.inflation(completed: shownStage) }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                HStack {
                    Text("tiny brave").font(Theme.font(24, relativeTo: .title2))
                    Spacer()
                    Button { path.append(.settings) } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                            .frame(width: 44, height: 44)
                            .roughCard()
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Settings")
                    Button { path.append(.progress) } label: {
                        Text("🎈 \(doneToday ? 1 : 0) / 1")
                            .font(Theme.font(15, relativeTo: .subheadline))
                            .padding(.horizontal, 12)
                            .frame(minHeight: 44)
                            .roughCard(fill: palette.sun)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Brave-o-Meter, \(doneToday ? 1 : 0) of 1 done today")
                }

                VStack(spacing: 2) {
                    Text(Greeting.text(name: username))
                        .font(Theme.font(20, relativeTo: .title3))
                        .accessibilityIdentifier("greeting")
                    BalloonView(inflation: inflation, puff: puff, size: 0.6)
                    Text(BalloonCaption.text(puffs: shownStage))
                        .font(Theme.font(24, relativeTo: .title2))
                    Text(subtitle)
                        .font(Theme.font(15, relativeTo: .subheadline))
                        .opacity(0.7)
                    Text(streak > 0 ? "🔥 \(DailyGoal.streakText(streak))" : "Start a streak today")
                        .font(Theme.font(15, relativeTo: .subheadline))
                        .padding(.horizontal, 12)
                        .frame(minHeight: 32)
                        .roughCard(fill: streak > 0 ? palette.sunSoft : nil)
                        .padding(.top, 6)
                        .accessibilityIdentifier("streak")
                }

                VStack(spacing: 10) {
                    ForEach(Level.allCases) { level in levelCard(level) }
                }

                HStack(spacing: 10) {
                    Button("🎲 Surprise me") { start(nil) }
                        .buttonStyle(BigButtonStyle(fill: palette.skySoft))
                    Button("Library") { path.append(.library) }
                        .buttonStyle(BigButtonStyle(dashed: true))
                }

                // Testing aid: pretends a day has passed so streaks and balloon stages can be checked.
                Button("⏭ Next day (\(now.formatted(.dateTime.month(.abbreviated).day())))") { dayOffset += 1 }
                    .buttonStyle(BigButtonStyle(fill: palette.skySoft))
                    .accessibilityLabel("Next day")
            }
            .padding(20)
        }
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .task(id: stage) { await animateBalloon() }
    }

    /// Steps the balloon one stage at a time from where the user last saw it to where it is now.
    private func animateBalloon() async {
        var current = shownStage
        lastSeenStage = current
        while current != stage {
            let inflating = current < stage
            do { try await Task.sleep(for: .milliseconds(400)) } catch { puff = 1; return }
            current += inflating ? 1 : -1
            lastSeenStage = current
            puff = inflating ? 1.12 : 0.92
            do { try await Task.sleep(for: .milliseconds(250)) } catch { puff = 1; return }
            puff = 1
        }
    }

    private var subtitle: String {
        if doneToday { return "Today's goal is done. Extra ones still add a puff." }
        return name.isEmpty ? "Pick today's tiny thing." : "Pick today's tiny thing, \(name)."
    }

    private func levelCard(_ level: Level) -> some View {
        Button { start(level) } label: {
            HStack(spacing: 12) {
                Text(level.symbol)
                    .font(.system(size: 20))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(level.color(in: palette)))
                    .overlay(Circle().stroke(palette.ink, lineWidth: 3))
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.title).font(Theme.font(20, relativeTo: .title3))
                    Text(level.blurb).font(.system(.footnote, design: .rounded)).opacity(0.75)
                }
                Spacer()
            }
            .padding(12)
            .frame(minHeight: 64)
            .roughCard()
        }
        .buttonStyle(.plain)
    }

    private func start(_ level: Level?) {
        if let challenge = store.pick(level: level, completed: completedIDs) {
            path.append(.challenge(challenge.id))
        }
    }
}
