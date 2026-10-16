import SwiftUI

/// What replaces the buttons under the card once a brave is done: a message, an optional drawing or tiny movie, and the way on.
struct RewardCard: View {
    let kicker: String
    let message: String
    let isFinal: Bool
    let status: String
    var onDrawing: (Data) -> Void
    var onVideo: (URL) -> Void
    var onNext: () -> Void
    var onFinale: () -> Void
    var onNewRound: () -> Void

    @Environment(\.palette) private var palette
    @State private var tab = Tab.draw

    enum Tab { case draw, video }

    var body: some View {
        VStack(spacing: 0) {
            Text(kicker)
                .font(Theme.body(10.2, weight: .black))
                .tracking(1.4)
                .padding(.bottom, 7)
                .accessibilityIdentifier("rewardKicker")
            Text(message)
                .font(Theme.font(27, relativeTo: .title2))
                .multilineTextAlignment(.center)
                .accessibilityIdentifier("rewardMessage")
            Text("want to keep a receipt? draw it or film it. totally optional.")
                .font(Theme.body(12.8, weight: .regular))
                .foregroundStyle(palette.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 7)
                .padding(.bottom, 15)

            dock

            Text(status)
                .font(Theme.body(11.4, weight: .heavy))
                .foregroundStyle(Color(hex: 0x337D89))
                .frame(minHeight: 21)
                .padding(.top, 11)
                .accessibilityIdentifier("saveStatus")

            if isFinal {
                VStack(spacing: 12) {
                    Button(action: onFinale) { Text("see the finale") }
                        .buttonStyle(BigButtonStyle())
                        .accessibilityIdentifier("seeFinale")
                    Button(action: onNewRound) { Text("new round") }
                        .buttonStyle(BigButtonStyle(fill: palette.surface))
                        .accessibilityIdentifier("newRound")
                }
                .padding(.top, 6)
            } else {
                Button(action: onNext) {
                    Text("next brave")
                        .font(Theme.font(16, relativeTo: .body))
                        .underline()
                        .frame(minWidth: 120, minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("nextBrave")
            }
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }

    private var dockShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 19, bottomLeadingRadius: 25, bottomTrailingRadius: 17, topTrailingRadius: 27, style: .continuous)
    }

    private var dock: some View {
        VStack(spacing: 0) {
            HStack(spacing: 9) {
                tabButton("Draw", tab: .draw) {
                    Image(systemName: "scribble").font(.system(size: 14, weight: .bold)).accessibilityHidden(true)
                }
                tabButton("Video", tab: .video) {
                    Circle().fill(Color(hex: 0xE65345))
                        .overlay(Circle().strokeBorder(lineWidth: 2))
                        .frame(width: 11, height: 11)
                        .accessibilityHidden(true)
                }
            }
            .padding(.horizontal, 15)
            .padding(.top, 13)

            Group {
                switch tab {
                case .draw: DrawingPad(onSave: onDrawing)
                case .video: VideoPad(onSave: onVideo)
                }
            }
            .padding(.horizontal, 15)
            .padding(.top, 14)
            .padding(.bottom, 5)
        }
        .background(dockShape.fill(palette.dock))
        .clipShape(dockShape)
        .overlay(dockShape.strokeBorder(palette.ink, lineWidth: 2.5))
        .background(dockShape.fill(palette.ink).offset(x: 5, y: 6))
        .rotationEffect(.degrees(0.25))
    }

    private func tabButton<Icon: View>(_ title: String, tab target: Tab, @ViewBuilder icon: () -> Icon) -> some View {
        let selected = tab == target
        let shape = UnevenRoundedRectangle(topLeadingRadius: 18, bottomLeadingRadius: 15, bottomTrailingRadius: 20, topTrailingRadius: 13, style: .continuous)
        return Button { tab = target } label: {
            HStack(spacing: 8) {
                icon()
                Text(title).font(Theme.font(14, relativeTo: .subheadline))
            }
            .foregroundStyle(selected ? Color.white : palette.ink)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(shape.fill(selected ? palette.ink : Color.white))
            .overlay(shape.strokeBorder(palette.ink, lineWidth: 1.7))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("tab\(title)")
    }
}
