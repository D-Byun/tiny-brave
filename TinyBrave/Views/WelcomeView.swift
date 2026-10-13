import SwiftUI

struct WelcomeView: View {
    let onOpen: () -> Void
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack(alignment: .topLeading) {
            Text("TINY BRAVE")
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .tracking(3)
                .padding(.top, 8)

            BalloonView(inflation: 0.9, size: 0.85)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 24)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 14) {
                Spacer()
                VStack(alignment: .leading, spacing: -6) {
                    Text("psst.")
                        .font(Theme.font(18, relativeTo: .headline))
                        .rotationEffect(.degrees(-4), anchor: .bottomLeading)
                    Text("there is one brave thing in here.")
                        .font(Theme.font(44, relativeTo: .largeTitle))
                        .minimumScaleFactor(0.7)
                        .accessibilityIdentifier("welcomeHeadline")
                }

                Button(action: onOpen) {
                    HStack {
                        Text("open carefully")
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                    .font(Theme.font(20, relativeTo: .title3))
                    .padding(.horizontal, 20)
                    .frame(minHeight: 64)
                    .frame(maxWidth: .infinity)
                    .background(roughRect().fill(palette.surface))
                    .overlay(roughRect().strokeBorder(palette.ink, lineWidth: 3))
                    .background(roughRect().fill(palette.ink).offset(x: 5, y: 6))
                }
                .buttonStyle(.plain)
                .padding(.trailing, 6)

                Text("about three minutes. possibly less.")
                    .font(Theme.font(14, relativeTo: .footnote))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.horizontal, 24)
        .padding(.bottom, 20)
        .foregroundStyle(palette.ink)
        .background(palette.sun.ignoresSafeArea())
    }
}

#Preview {
    WelcomeView {}
}
