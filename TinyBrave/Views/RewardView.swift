import SwiftUI
import SwiftData

struct RewardView: View {
    @Binding var path: [Route]
    let challengeID: Int

    @Environment(\.palette) private var palette
    @Query(sort: \Completion.date, order: .reverse) private var completions: [Completion]
    @State private var revealed = false
    @State private var puff: CGFloat = 1
    @State private var line = ["Tiny brave acquired.", "That counted."].randomElement()!

    /// The balloon stays at its previous stage here; the home screen animates the change.
    private var balloonInflation: Double {
        BraveProgress.inflation(completed: BraveProgress.stage(Array(completions.dropFirst())))
    }
    private var selectedAwkwardness: Int? { completions.first?.awkwardness }

    var body: some View {
        VStack(spacing: 10) {
            BalloonView(inflation: balloonInflation, happy: revealed, puff: puff, size: 0.62)

            Text(line).font(Theme.font(24, relativeTo: .title2))
            Text("Nobody exploded.")
                .font(Theme.font(15, relativeTo: .subheadline))
                .opacity(0.7)

            awkwardnessCheck

            Spacer(minLength: 0)

            Button("Next brave") { path = [] }
                .buttonStyle(BigButtonStyle())
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
}
