import SwiftUI
import AVFoundation

/// Paper sheet with an eyebrow, a title and a round close button.
struct SheetScaffold<Content: View>: View {
    let eyebrow: String
    let title: String
    var onClose: () -> Void
    @ViewBuilder var content: () -> Content

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 7) {
                    Text(eyebrow.uppercased())
                        .font(Theme.body(10.2, weight: .black))
                        .tracking(1.5)
                    Text(title)
                        .font(Theme.body(22.7, weight: .black))
                        .tracking(-0.9)
                        .accessibilityAddTraits(.isHeader)
                }
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .heavy))
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Color.white))
                        .overlay(Circle().strokeBorder(palette.ink, lineWidth: 2))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            .padding(.horizontal, 20)
            .padding(.top, 23)
            .padding(.bottom, 14)
            .overlay(alignment: .bottom) { Rectangle().fill(palette.line).frame(height: 1.5) }

            ScrollView { content() }
        }
        .foregroundStyle(palette.ink)
        .background(palette.surface.ignoresSafeArea())
        .presentationCornerRadius(26)
    }
}

/// Wraps its children onto new lines like text.
struct FlowLayout: Layout {
    var spacing: CGFloat = 7

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        layout(in: proposal.width ?? .infinity, subviews: subviews).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(in: bounds.width, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func layout(in width: CGFloat, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        var origins: [CGPoint] = []
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, maxX: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > width {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            x += size.width + spacing
            maxX = max(maxX, x - spacing)
            rowHeight = max(rowHeight, size.height)
        }
        return (CGSize(width: maxX, height: y + rowHeight), origins)
    }
}

/// A kept drawing or tiny recording; videos show their first frame and audio shows a waveform.
struct ResponseThumbnail: View {
    let response: Response
    var fit = false
    @State private var image: UIImage?

    var body: some View {
        Group {
            if response.kind == .audio {
                ZStack {
                    Color(hex: 0x25251F)
                    Image(systemName: "waveform")
                        .font(.system(size: fit ? 90 : 34, weight: .bold))
                        .foregroundStyle(.white)
                }
            } else if let image {
                if fit {
                    Image(uiImage: image).resizable().scaledToFit()
                } else {
                    Image(uiImage: image).resizable().scaledToFill()
                }
            } else {
                Color.white
            }
        }
        .task(id: response.filename) { image = await load() }
    }

    private func load() async -> UIImage? {
        let url = ResponseFiles.url(for: response.filename)
        switch response.kind {
        case .drawing:
            return UIImage(contentsOfFile: url.path)
        case .audio:
            return nil
        case .video:
            let generator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
            generator.appliesPreferredTrackTransform = true
            generator.maximumSize = CGSize(width: 600, height: 600)
            guard let cg = try? await generator.image(at: .zero).image else { return nil }
            return UIImage(cgImage: cg)
        }
    }
}

struct TrackSheet: View {
    let round: Int
    let completedTitles: [String]
    let responses: [Response]
    let streak: Int
    var onClose: () -> Void
    var onReset: () -> Void

    @Environment(\.palette) private var palette
    @State private var showReel = false
    @State private var confirmReset = false

    private var roundResponses: [Response] { responses.filter { $0.round == round } }

    var body: some View {
        SheetScaffold(eyebrow: "Track", title: "Your brave so far", onClose: onClose) {
            VStack(alignment: .leading, spacing: 0) {
                stats
                reelButton.padding(.top, 14)
                archive.padding(.top, 28)
                completed.padding(.top, 28)
                Button { confirmReset = true } label: {
                    Text("reset my balloon")
                        .font(Theme.body(10.6, weight: .heavy))
                        .foregroundStyle(Color(hex: 0xB84A40))
                        .padding(6)
                        .overlay(alignment: .bottom) { Rectangle().fill(Color(hex: 0xB84A40)).frame(height: 1) }
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
                .padding(.top, 20)
                .accessibilityIdentifier("resetProgress")
            }
            .padding(.horizontal, 20)
            .padding(.top, 18)
            .padding(.bottom, 36)
        }
        .fullScreenCover(isPresented: $showReel) {
            ReelView(responses: roundResponses.sorted { $0.date < $1.date }) { showReel = false }
        }
        .modalDialog(isPresented: $confirmReset) {
            VStack(spacing: 0) {
                MiniBalloon(sad: true).padding(.bottom, 8)
                Text("deflate the balloon?")
                    .font(Theme.font(27, relativeTo: .title2))
                    .padding(.bottom, 8)
                Text("Your balloon goes back to zero. Your archive stays exactly where it is.")
                    .font(Theme.body(15, weight: .regular))
                    .foregroundStyle(palette.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                VStack(spacing: 12) {
                    Button { confirmReset = false } label: { Text("keep going") }
                        .buttonStyle(BigButtonStyle(fill: palette.surface))
                    Button {
                        confirmReset = false
                        onReset()
                    } label: { Text("reset").foregroundStyle(.white) }
                        .buttonStyle(BigButtonStyle(fill: Color(hex: 0xE65345)))
                        .accessibilityIdentifier("confirmReset")
                }
                .padding(.top, 22)
            }
            .padding(.horizontal, 24)
            .padding(.top, 30)
            .padding(.bottom, 23)
        }
    }

    private var stats: some View {
        HStack(spacing: 0) {
            statColumn("\(completedTitles.count)", "completed", id: "statCompleted")
            Rectangle().fill(palette.ink).frame(width: 1.5)
            statColumn("\(responses.count)", "responses", id: "statResponses")
            Rectangle().fill(palette.ink).frame(width: 1.5)
            statColumn("\(streak)", "day streak", id: "statStreak")
        }
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(palette.sun))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(palette.ink, lineWidth: 2))
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(palette.ink).offset(x: 4, y: 5))
    }

    private func statColumn(_ value: String, _ label: String, id: String) -> some View {
        VStack(spacing: 3) {
            Text(value).font(Theme.body(24, weight: .black))
            Text(label).font(Theme.body(9.3, weight: .heavy))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(id)
    }

    private var reelButton: some View {
        Button { showReel = true } label: {
            HStack(spacing: 12) {
                Image(systemName: "play.fill")
                    .font(.system(size: 14))
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(palette.surface))
                    .overlay(Circle().strokeBorder(palette.ink, lineWidth: 2))
                VStack(alignment: .leading, spacing: 2) {
                    Text("play the reel").font(Theme.font(18, relativeTo: .headline))
                    Text("this round's receipts, oldest first").font(Theme.body(11, weight: .semibold)).foregroundStyle(palette.muted)
                }
                Spacer()
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(roughRect().fill(palette.blue))
            .overlay(roughRect().strokeBorder(palette.ink, lineWidth: 2))
            .background(roughRect().fill(palette.ink).offset(x: 4, y: 5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("play the reel")
        .accessibilityIdentifier("playReel")
    }

    private var archive: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("archive").font(Theme.body(14.7, weight: .black))
            if responses.isEmpty {
                VStack(spacing: 6) {
                    Capsule().frame(width: 42, height: 2).padding(.bottom, 6)
                    Text("no receipts yet").font(Theme.body(13, weight: .black)).foregroundStyle(palette.ink)
                    Text("finish a brave, then draw it or film it. it will live here.")
                        .font(Theme.body(10.9, weight: .regular))
                        .multilineTextAlignment(.center)
                }
                .foregroundStyle(palette.muted)
                .padding(.horizontal, 16)
                .padding(.vertical, 24)
                .frame(maxWidth: .infinity)
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color(hex: 0xAAA497), style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                .accessibilityElement(children: .combine)
                .accessibilityIdentifier("archiveEmpty")
            } else {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                    ForEach(responses.sorted { $0.date > $1.date }) { response in
                        tile(response)
                    }
                }
            }
        }
    }

    private func tile(_ response: Response) -> some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        return Color.white
            .aspectRatio(1, contentMode: .fit)
            .overlay { ResponseThumbnail(response: response) }
            .overlay(alignment: .topLeading) {
                if response.kind != .drawing {
                    Text(response.kind == .audio ? "AUDIO" : "VIDEO")
                        .font(Theme.body(8.5, weight: .black))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color(hex: 0xE65345)))
                        .padding(7)
                }
            }
            .overlay(alignment: .bottom) {
                Text(response.label)
                    .font(Theme.body(9, weight: .heavy))
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 8).fill(palette.surface.opacity(0.93)))
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(palette.ink, lineWidth: 1.5))
                    .padding(6)
            }
            .clipShape(shape)
            .overlay(shape.strokeBorder(palette.ink, lineWidth: 2))
            .background(shape.fill(palette.ink).offset(x: 2, y: 3))
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("\(response.kind == .video ? "Video" : response.kind == .audio ? "Audio" : "Drawing"), \(response.label)")
    }

    private var completed: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("completed").font(Theme.body(14.7, weight: .black))
            if completedTitles.isEmpty {
                Text("your first brave is waiting.")
                    .font(Theme.body(12.5, weight: .regular))
                    .foregroundStyle(palette.muted)
            } else {
                FlowLayout {
                    ForEach(Array(completedTitles.enumerated()), id: \.offset) { _, title in
                        Text("✓ \(title)")
                            .font(Theme.body(10, weight: .bold))
                            .padding(.horizontal, 9)
                            .padding(.vertical, 7)
                            .background(Capsule().fill(Color.white))
                            .overlay(Capsule().strokeBorder(palette.ink, lineWidth: 1.3))
                    }
                }
            }
        }
    }
}
