import SwiftUI
import SwiftData

enum Route: Hashable {
    case reward(challengeID: Int)
    case progress
}

@main
struct TinyBraveApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: Completion.self)
    }
}

struct RootView: View {
    @State private var path: [Route] = []
    @State private var showWelcome = !ProcessInfo.processInfo.arguments.contains("-skipWelcome")

    var body: some View {
        ZStack {
            mainStack
                .accessibilityHidden(showWelcome)
            if showWelcome {
                WelcomeView { withAnimation(.easeInOut(duration: 0.35)) { showWelcome = false } }
                    .transition(.opacity)
                    .zIndex(1)
                    .accessibilityAddTraits(.isModal)
            }
        }
        .tint(Palette.standard.ink)
        .preferredColorScheme(.light)
    }

    private var mainStack: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .reward(let id):
                        RewardView(path: $path, challengeID: id)
                    case .progress:
                        ProgressScreen()
                    }
                }
        }
    }
}
