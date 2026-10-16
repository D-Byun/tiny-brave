import SwiftUI

private let confettiColors: [Color] = [
    Color(hex: 0xEF767A), Palette.standard.sun, .white, Palette.standard.green,
    Palette.standard.lavender, Palette.standard.blue, Palette.standard.pink,
]

private struct ConfettiBit: View {
    var color: Color
    var body: some View {
        Rectangle()
            .fill(color)
            .overlay(Rectangle().strokeBorder(Palette.standard.ink, lineWidth: 1.5))
            .frame(width: 9, height: 17)
    }
}

/// Paper bits drifting down forever; the Home balloon zone at 30 and the finale use it.
struct ConfettiRain: View {
    var count = 12
    var fall: CGFloat = 410
    var seconds: Double = 3

    var body: some View {
        TimelineView(.animation) { timeline in
            GeometryReader { geo in
                let now = timeline.date.timeIntervalSinceReferenceDate
                ForEach(0..<count, id: \.self) { index in
                    let duration = seconds * (0.9 + 0.1 * Double(index % 4))
                    let phase = ((now + Double(index) * 0.37) / duration).truncatingRemainder(dividingBy: 1)
                    let sway = CGFloat(index.isMultiple(of: 2) ? 10 : -12) * CGFloat(phase)
                    ConfettiBit(color: confettiColors[index % confettiColors.count])
                        .rotationEffect(.degrees(560 * phase))
                        .position(x: geo.size.width * (0.04 + 0.92 * CGFloat(index) / CGFloat(max(count - 1, 1))) + sway, y: -28 + fall * CGFloat(phase))
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

/// A one-shot pop of confetti from the middle of the screen when a brave is marked done.
struct ConfettiBurst: View {
    var count: Int
    var trigger: Int

    @State private var flying = false
    @State private var shown = 0

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<count, id: \.self) { index in
                let angle = Double(index) / Double(count) * 2 * .pi + Double(index % 3) * 0.4
                let distance = CGFloat(110 + (index * 37) % 190)
                ConfettiBit(color: confettiColors[index % confettiColors.count])
                    .frame(width: 9, height: 15)
                    .rotationEffect(.degrees(flying ? Double(180 + (index * 53) % 400) : 0))
                    .position(
                        x: geo.size.width / 2 + (flying ? cos(angle) * distance : 0),
                        y: geo.size.height * 0.42 + (flying ? sin(angle) * distance * 0.9 + 60 : 0)
                    )
                    .opacity(flying ? 0 : 1)
            }
        }
        .opacity(shown == 0 ? 0 : 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onChange(of: trigger) { _, newValue in
            guard newValue > 0 else { return }
            shown = newValue
            flying = false
            DispatchQueue.main.async {
                withAnimation(.easeOut(duration: 0.9)) { flying = true }
            }
        }
    }
}
