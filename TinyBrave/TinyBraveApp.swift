import SwiftUI
import SwiftData

enum Route: Hashable {
    case challenge(Int)
    case reward(challengeID: Int, debris: String)
    case library
    case progress
    case settings
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
    @AppStorage(AppTheme.storageKey) private var themeKey = AppTheme.sunny.rawValue
    @State private var path: [Route] = []
    @State private var showWelcome = !ProcessInfo.processInfo.arguments.contains("-skipWelcome")
    private let store = ChallengeStore.shared

    private var theme: AppTheme { AppTheme(rawValue: themeKey) ?? .sunny }

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
        .environment(\.palette, theme.palette)
        .tint(theme.palette.ink)
        .preferredColorScheme(theme.isDark ? .dark : .light)
    }

    private var mainStack: some View {
        NavigationStack(path: $path) {
            HomeView(path: $path)
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .challenge(let id):
                        if let challenge = store.challenge(id: id) {
                            ChallengeView(path: $path, challenge: challenge)
                        }
                    case .reward(let id, let debris):
                        RewardView(path: $path, challengeID: id, debrisKey: debris)
                    case .library:
                        LibraryView(path: $path)
                    case .progress:
                        ProgressScreen()
                    case .settings:
                        SettingsView()
                    }
                }
        }
    }
}
