import SwiftUI
import SwiftData

@main
struct TinyBraveApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: [Completion.self, Response.self])
    }
}

struct RootView: View {
    @State private var showWelcome = !ProcessInfo.processInfo.arguments.contains("-skipWelcome")

    var body: some View {
        ZStack {
            HomeView()
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
}
