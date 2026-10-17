import SwiftUI
import AVKit

/// Plays the kept drawings and recordings one after another, oldest first, 2.5 seconds each.
struct ReelView: View {
    let responses: [Response]
    var onClose: () -> Void

    @State private var index = 0
    @State private var progress: CGFloat = 0
    @State private var finished = false
    @State private var replay = 0
    @State private var player: AVPlayer?

    @Environment(\.palette) private var palette
    private let dark = Color(hex: 0x171713)

    private var current: Response? { responses.indices.contains(index) ? responses[index] : nil }

    private var caption: String {
        if responses.isEmpty { return "the archive is empty, but the balloon remembers." }
        if finished { return "end. courage was here." }
        return current?.title ?? ""
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            dark.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 0) {
                Text(responses.isEmpty ? "0 / 0" : "\(min(index + 1, responses.count)) / \(responses.count)")
                    .font(Theme.body(10.2, weight: .black))
                    .tracking(1.2)
                    .padding(.bottom, 12)
                media
                Text(caption)
                    .font(Theme.font(16, relativeTo: .body))
                    .frame(minHeight: 39, alignment: .topLeading)
                    .padding(.horizontal, 4)
                    .padding(.top, 15)
                    .padding(.bottom, 10)
                    .accessibilityIdentifier("reelCaption")
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color(hex: 0x56564D))
                        Capsule().fill(palette.sun).frame(width: geo.size.width * progress)
                    }
                }
                .frame(height: 5)
                if finished {
                    Button { replay += 1 } label: {
                        Text("replay")
                            .font(Theme.body(15, weight: .heavy))
                            .frame(maxWidth: .infinity, minHeight: 48)
                            .overlay(Capsule().strokeBorder(.white, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 20)
                    .accessibilityIdentifier("replayReel")
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 18)
            .padding(.top, 62)
            .padding(.bottom, 27)

            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .heavy))
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(dark))
                    .overlay(Circle().strokeBorder(.white, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .padding(13)
            .accessibilityLabel("Close reel")
            .accessibilityIdentifier("closeReel")
        }
        .foregroundStyle(.white)
        .task(id: replay) { await play() }
        .onDisappear { player?.pause() }
    }

    private var media: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return ZStack {
            Color(hex: 0x292922)
            if responses.isEmpty {
                Text("no receipts. still brave.")
                    .font(Theme.font(26, relativeTo: .title2))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 260)
            } else if let current {
                if current.kind == .video, let player {
                    VideoPlayer(player: player).disabled(true)
                } else {
                    ResponseThumbnail(response: current, fit: true)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 360)
        .frame(maxHeight: .infinity)
        .clipShape(shape)
        .overlay(shape.strokeBorder(.white, lineWidth: 2))
    }

    private func play() async {
        finished = false
        index = 0
        progress = 0
        for position in responses.indices {
            index = position
            prepare(responses[position])
            progress = 0
            try? await Task.sleep(for: .milliseconds(40))
            withAnimation(.linear(duration: 2.5)) { progress = 1 }
            do { try await Task.sleep(for: .seconds(2.46)) } catch { return }
        }
        player?.pause()
        finished = true
    }

    private func prepare(_ response: Response) {
        guard response.kind != .drawing else {
            player?.pause()
            player = nil
            return
        }
        let next = AVPlayer(url: ResponseFiles.url(for: response.filename))
        player = next
        next.play()
    }
}
