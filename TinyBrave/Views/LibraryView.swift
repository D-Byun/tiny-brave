import SwiftUI
import SwiftData

struct LibraryView: View {
    @Binding var path: [Route]
    @Environment(\.palette) private var palette
    @Query private var completions: [Completion]
    @State private var selected: BraveCategory?
    private let store = ChallengeStore.shared

    private var completedIDs: Set<Int> { Set(completions.map(\.challengeID)) }
    private var visible: [Challenge] {
        store.all.filter { selected == nil || $0.category == selected }
    }

    var body: some View {
        VStack(spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    Chip(title: "All", selected: selected == nil) { selected = nil }
                    ForEach(BraveCategory.allCases) { category in
                        Chip(title: category.title, selected: selected == category) { selected = category }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 3)
            }

            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(visible) { challenge in row(challenge) }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
        .screenBackground()
        .navigationTitle("Library")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func row(_ challenge: Challenge) -> some View {
        let done = completedIDs.contains(challenge.id)
        return Button { path.append(.challenge(challenge.id)) } label: {
            HStack(spacing: 10) {
                Text(challenge.level.symbol)
                    .font(.system(size: 14))
                    .frame(width: 30, height: 30)
                    .background(Circle().fill(challenge.level.color(in: palette)))
                    .overlay(Circle().stroke(palette.ink, lineWidth: 2.5))
                VStack(alignment: .leading, spacing: 2) {
                    Text(challenge.category.title.uppercased())
                        .font(.system(.caption2, design: .rounded))
                        .tracking(1)
                        .opacity(0.55)
                    Text(challenge.text)
                        .font(Theme.font(16, relativeTo: .callout))
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 4)
                if done { Text("✓").font(.system(size: 20, weight: .bold)) }
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .roughCard(fill: done ? palette.sunSoft : palette.surface)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(challenge.category.title), \(challenge.level.title): \(challenge.text)\(done ? ", done" : "")")
    }
}
