import SwiftUI
import SwiftData

struct ProgressScreen: View {
    @Environment(\.palette) private var palette
    @Environment(\.modelContext) private var context
    @Query private var completions: [Completion]
    @State private var confirmReset = false

    private var total: Int { BraveProgress.goal }
    private var doneCount: Int { BraveProgress.stage(completions) }
    private var inflation: Double { BraveProgress.inflation(completed: doneCount) }
    private var streak: Int { DailyGoal.streak(completions) }

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

                Button("Reset progress") { confirmReset = true }
                    .buttonStyle(BigButtonStyle(dashed: true))
                    .padding(.top, 6)
            }
            .padding(20)
        }
        .screenBackground()
        .navigationTitle("Track")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog("Reset all progress?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive, action: resetProgress)
        } message: {
            Text("The balloon goes back to square one. This can't be undone.")
        }
    }

    private func resetProgress() {
        // Deleting objects one by one makes every @Query (including Home's, below this screen) refresh.
        let all = (try? context.fetch(FetchDescriptor<Completion>())) ?? []
        all.forEach(context.delete)
        try? context.save()
        UserDefaults.standard.removeObject(forKey: BraveProgress.lastSeenStageKey)
        TaskQueueStorage.clear()
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
}
