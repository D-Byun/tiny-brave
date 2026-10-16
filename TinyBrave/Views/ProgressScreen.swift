import SwiftUI
import SwiftData

struct ProgressScreen: View {
    @Environment(\.palette) private var palette
    @Environment(\.modelContext) private var context
    @AppStorage(AppClock.offsetKey) private var dayOffset = 0
    @Query private var completions: [Completion]
    @State private var confirmReset = false
    private let store = ChallengeStore.shared

    private var completedIDs: Set<Int> { Set(completions.map(\.challengeID)) }
    private var total: Int { BraveProgress.goal }
    private var doneCount: Int { BraveProgress.stage(completions) }
    private var inflation: Double { BraveProgress.inflation(completed: doneCount) }
    private var streak: Int { DailyGoal.streak(completions, now: AppClock.now(offsetDays: dayOffset)) }
    private var foundDebris: Set<String> { Set(completions.map(\.debrisKey)) }

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                VStack(spacing: 2) {
                    BalloonView(inflation: inflation, size: 0.5)
                    Text(BalloonCaption.text(puffs: doneCount))
                        .font(Theme.font(22, relativeTo: .title2))
                }

                meter

                // Only shown once there is one; a missing streak is never pointed out.
                if streak > 0 {
                    Text("🔥 \(DailyGoal.streakText(streak))")
                        .font(Theme.font(16, relativeTo: .body))
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .roughCard(fill: palette.sunSoft)
                        .accessibilityIdentifier("streak")
                }

                section("BRAVERY MUSCLES") {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                        ForEach(BraveCategory.allCases) { category in muscle(category) }
                    }
                }

                section("BRAVE DEBRIS") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                        ForEach(Debris.all) { debris in
                            let found = foundDebris.contains(debris.id)
                            Text(found ? debris.emoji : "?")
                                .font(.system(size: found ? 30 : 20))
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .roughCard(fill: found ? palette.surface : .clear)
                                .opacity(found ? 1 : 0.4)
                                .accessibilityLabel(found ? debris.name : "Not found yet")
                        }
                    }
                }

                section("CERTIFICATES") {
                    let earned = Certificate.all.filter { $0.count <= DailyGoal.activeDays(completions) }
                    if earned.isEmpty {
                        Text("Do one brave thing to earn the first.")
                            .font(.system(.footnote, design: .rounded))
                            .opacity(0.7)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        VStack(spacing: 6) {
                            ForEach(earned) { certificate in
                                Text("🏅 \(certificate.title)")
                                    .font(Theme.font(16, relativeTo: .body))
                                    .padding(.horizontal, 12)
                                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                                    .roughCard(fill: palette.sunSoft)
                            }
                        }
                    }
                }

                Button("Reset progress") { confirmReset = true }
                    .buttonStyle(BigButtonStyle(dashed: true))
                    .padding(.top, 6)
            }
            .padding(20)
        }
        .screenBackground()
        .navigationTitle("Brave-o-Meter")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Reset all progress?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) {
                try? context.delete(model: Completion.self)
                UserDefaults.standard.removeObject(forKey: BraveProgress.lastSeenStageKey)
                TaskQueueStorage.clear()
            }
        } message: {
            Text("The balloon goes back to square one. This can't be undone.")
        }
    }

    private var meter: some View {
        VStack(spacing: 4) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    roughRect().fill(palette.surface)
                    roughRect().fill(palette.sun)
                        .frame(width: max(geo.size.width * inflation, inflation > 0 ? 16 : 0))
                        .animation(.spring, value: inflation)
                }
                .clipShape(roughRect())
                .overlay(roughRect().strokeBorder(palette.ink, lineWidth: 3))
            }
            .frame(height: 26)
            HStack {
                Text("\(doneCount) of \(total)")
                Spacer()
                Text("\(total - doneCount) to go")
            }
            .font(Theme.font(14, relativeTo: .footnote))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Balloon stage \(doneCount) of \(total)")
    }

    private func muscle(_ category: BraveCategory) -> some View {
        let all = store.all.filter { $0.category == category }
        let done = all.filter { completedIDs.contains($0.id) }.count
        return HStack(spacing: 6) {
            Text(category.title).font(Theme.font(13, relativeTo: .footnote))
            Spacer(minLength: 2)
            Capsule().fill(palette.surface)
                .frame(width: 44, height: 10)
                .overlay(alignment: .leading) {
                    Capsule().fill(category.color(in: palette))
                        .frame(width: 44 * Double(done) / Double(max(all.count, 1)), height: 10)
                }
                .overlay(Capsule().stroke(palette.ink, lineWidth: 2))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(category.title), \(done) of \(all.count)")
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Theme.font(15, relativeTo: .subheadline)).tracking(1)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
