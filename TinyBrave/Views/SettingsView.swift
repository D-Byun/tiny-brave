import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.palette) private var palette
    @Environment(\.modelContext) private var context
    @AppStorage(AppClock.offsetKey) private var dayOffset = 0
    @State private var confirmReset = false
    @AppStorage(Username.storageKey) private var username = ""
    @AppStorage(AppTheme.storageKey) private var themeKey = AppTheme.sunny.rawValue

    private var theme: AppTheme { AppTheme(rawValue: themeKey) ?? .sunny }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                section("USERNAME") {
                    TextField("Your name", text: $username)
                        .font(Theme.font(18, relativeTo: .body))
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .submitLabel(.done)
                        .padding(.horizontal, 12)
                        .frame(minHeight: 48)
                        .roughCard()
                        .accessibilityIdentifier("usernameField")
                        .onChange(of: username) { _, new in
                            let cleaned = String(new.prefix(Username.maxLength))
                            if cleaned != new { username = cleaned }
                        }
                    Text("Shown on the home screen. Stays on this device.")
                        .font(.system(.footnote, design: .rounded))
                        .opacity(0.7)
                }

                section("THEME") {
                    LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                        ForEach(AppTheme.allCases) { option in themeCard(option) }
                    }
                }

                section("YOUR DATA") {
                    Text("Everything lives only on this device. Nothing is sent anywhere.")
                        .font(.system(.footnote, design: .rounded))
                        .opacity(0.7)
                    Button("Reset all data") { confirmReset = true }
                        .buttonStyle(BigButtonStyle(dashed: true))
                }
            }
            .padding(20)
        }
        .confirmationDialog("Reset all data?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset everything", role: .destructive, action: resetAllData)
        } message: {
            Text("This erases your progress, streak, username and theme. It can't be undone.")
        }
        .scrollDismissesKeyboard(.interactively)
        .screenBackground()
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { username = Username.clean(username) }
    }

    private func resetAllData() {
        // Deleting objects one by one makes every @Query (including ones on screens below this) refresh.
        let all = (try? context.fetch(FetchDescriptor<Completion>())) ?? []
        all.forEach(context.delete)
        try? context.save()
        username = ""
        dayOffset = 0
        UserDefaults.standard.removeObject(forKey: BraveProgress.lastSeenStageKey)
        TaskQueueStorage.clear()
        themeKey = AppTheme.sunny.rawValue
    }

    private func themeCard(_ option: AppTheme) -> some View {
        let colors = option.palette
        let selected = option == theme
        return Button { themeKey = option.rawValue } label: {
            VStack(spacing: 8) {
                HStack(spacing: -6) {
                    ForEach([colors.sun, colors.sky, colors.skySoft], id: \.self) { color in
                        Circle().fill(color)
                            .frame(width: 26, height: 26)
                            .overlay(Circle().stroke(colors.ink, lineWidth: 2.5))
                    }
                }
                Text(option.title)
                    .font(Theme.font(16, relativeTo: .body))
                    .foregroundStyle(colors.ink)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(8)
            .background(roughRect().fill(colors.background))
            .overlay(roughRect().strokeBorder(colors.ink, lineWidth: selected ? 4 : 2))
            .overlay(alignment: .topTrailing) {
                if selected {
                    Text("✓")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(colors.ink)
                        .padding(6)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(option.title) theme")
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func section<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(Theme.font(15, relativeTo: .subheadline)).tracking(1)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
