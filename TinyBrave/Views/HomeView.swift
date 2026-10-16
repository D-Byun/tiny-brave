import SwiftUI
import SwiftData

struct HomeView: View {
    @Binding var path: [Route]
    @Environment(\.palette) private var palette
    @AppStorage(Username.storageKey) private var username = ""
    @AppStorage(AppClock.offsetKey) private var dayOffset = 0
    @AppStorage(BraveProgress.lastSeenStageKey) private var lastSeenStage = -1
    @State private var puff: CGFloat = 1
    @Environment(\.modelContext) private var context
    @Query private var completions: [Completion]
    /// Order the remaining tasks were left in after skips; completed tasks drop out of it on their own.
    /// Reloaded whenever Home appears so a reset from Settings or Track takes effect.
    @State private var savedOrder = TaskQueueStorage.load()
    private let store = ChallengeStore.shared

    private var completedIDs: Set<Int> { Set(completions.map(\.challengeID)) }
    private var now: Date { AppClock.now(offsetDays: dayOffset) }
    private var stage: Int { BraveProgress.stage(completions) }
    /// The stage currently drawn; it steps toward `stage` so changes animate.
    private var shownStage: Int { lastSeenStage >= 0 ? lastSeenStage : stage }
    private var queue: TaskQueue {
        TaskQueue(catalog: store.all.map(\.id), completed: completedIDs, saved: savedOrder)
    }
    private var current: Challenge? { queue.current.flatMap(store.challenge(id:)) }

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
                        HStack(spacing: 6) {
                            Image(systemName: "chart.bar.fill").accessibilityHidden(true)
                            Text("Track")
                        }
                        .font(Theme.font(15, relativeTo: .subheadline))
                        .padding(.horizontal, 12)
                        .frame(minHeight: 44)
                        .roughCard(fill: palette.sun)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Track")
                }

                Text(Greeting.text(name: username))
                    .font(Theme.font(20, relativeTo: .title3))
                    .accessibilityIdentifier("greeting")

                BraveMeterView(puffs: shownStage, puff: puff)

                if let current {
                    TaskCardView(challenge: current, day: min(stage + 1, BraveProgress.goal))
                    Text("Do it out in the world. Then come back.")
                        .font(Theme.font(15, relativeTo: .subheadline))
                        .opacity(0.7)
                    VStack(spacing: 10) {
                        Button(action: complete) {
                            HStack(spacing: 8) {
                                Text("yep. did brave thing.")
                                Image(systemName: "checkmark").font(.system(size: 18, weight: .bold)).accessibilityHidden(true)
                            }
                        }
                        .buttonStyle(BigButtonStyle())
                        .accessibilityLabel("yep. did brave thing.")
                        Button("not this brave. give other.", action: skip)
                            .buttonStyle(BigButtonStyle(dashed: true))
                    }
                } else {
                    allDoneCard
                }

                VStack(spacing: 10) {
                    linkRow("Track my brave", detail: "balloon, debris, certificates, the whole saga", route: .progress)
                    linkRow("All 30 braves", detail: "browse the library and replay any of them", route: .library)
                }
                .padding(.top, 6)

                // Testing aid: pretends a day has passed so streaks and day counts can be checked.
                Button("⏭ Next day (\(now.formatted(.dateTime.month(.abbreviated).day())))") { dayOffset += 1 }
                    .buttonStyle(BigButtonStyle(fill: palette.skySoft))
                    .accessibilityLabel("Next day")
            }
            .padding(20)
        }
        .screenBackground()
        .toolbar(.hidden, for: .navigationBar)
        .task(id: stage) { await animateBalloon() }
        .onAppear { savedOrder = TaskQueueStorage.load() }
    }

    private var allDoneCard: some View {
        VStack(spacing: 6) {
            Text("all 30 done.").font(Theme.font(26, relativeTo: .title))
            Text("The balloon has left the building.")
                .font(.system(.subheadline, design: .rounded))
                .opacity(0.75)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .roughCard()
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("allDone")
    }

    private func linkRow(_ title: String, detail: String, route: Route) -> some View {
        Button { path.append(route) } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(Theme.font(18, relativeTo: .headline))
                    Text(detail).font(.system(.footnote, design: .rounded)).opacity(0.7)
                }
                Spacer()
                Image(systemName: "arrow.right").font(.system(size: 18, weight: .semibold)).accessibilityHidden(true)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .roughCard()
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
        .accessibilityAddTraits(.isButton)
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

    private func complete() {
        guard let current else { return }
        let debris = Debris.random()
        context.insert(Completion(challengeID: current.id, debrisKey: debris.id, date: AppClock.now))
        path.append(.reward(challengeID: current.id, debris: debris.id))
    }

    /// Sends today's task to the back of the list so the next one in order comes up.
    private func skip() {
        var next = queue
        next.skip()
        TaskQueueStorage.save(next)
        withAnimation { savedOrder = next.ids }
    }
}
