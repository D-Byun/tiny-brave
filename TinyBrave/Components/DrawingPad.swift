import SwiftUI

struct DrawnStroke: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    var color: Color
    var width: CGFloat
}

/// The marks on a drawing, kept separate from the view so it can be rendered to a PNG as well.
struct StrokesCanvas: View {
    var strokes: [DrawnStroke]
    var background: Color

    var body: some View {
        Canvas { context, _ in
            for stroke in strokes {
                var path = Path()
                guard let first = stroke.points.first else { continue }
                path.move(to: first)
                if stroke.points.count == 1 {
                    path.addLine(to: CGPoint(x: first.x + 0.01, y: first.y))
                }
                for point in stroke.points.dropFirst() { path.addLine(to: point) }
                context.stroke(path, with: .color(stroke.color), style: StrokeStyle(lineWidth: stroke.width, lineCap: .round, lineJoin: .round))
            }
        }
        .background(background)
    }
}

enum DrawingExport {
    /// A PNG of the strokes, drawn at the canvas's own size.
    @MainActor
    static func png(strokes: [DrawnStroke], size: CGSize, background: Color) -> Data? {
        let renderer = ImageRenderer(content: StrokesCanvas(strokes: strokes, background: background).frame(width: size.width, height: size.height))
        renderer.scale = 2
        return renderer.uiImage?.pngData()
    }
}

/// The Draw tab: a 4:3 sheet to scribble on, a few pen colors, an eraser and clear.
/// The drawing is kept in Track a moment after the pen pauses; clearing it removes it.
struct DrawingPad: View {
    /// Called with the PNG of the current drawing, or nil when the sheet was cleared.
    var onSave: (Data?) -> Void

    @Environment(\.palette) private var palette
    @State private var strokes: [DrawnStroke] = []
    @State private var current: DrawnStroke?
    @State private var color = Color(hex: 0x171713)
    @State private var erasing = false
    @State private var size = CGSize(width: 300, height: 225)

    private let swatches: [Color] = [
        Color(hex: 0x171713), Color(hex: 0xE65345), Color(hex: 0xF6CF45), Color(hex: 0x4F9D69), Color(hex: 0x3F8FC7), Color(hex: 0x8B6BC6),
    ]
    private let paper = Color(hex: 0xFFFAF0)
    @State private var hasSaved = false
    @State private var dirty = false

    var body: some View {
        VStack(spacing: 0) {
            canvas
            tools
        }
        .task(id: strokes.count) {
            guard dirty else { return }
            do { try await Task.sleep(for: .milliseconds(800)) } catch { return }
            keep()
        }
        .onDisappear { if dirty { keep() } }
    }

    private func keep() {
        dirty = false
        if strokes.isEmpty {
            guard hasSaved else { return }
            hasSaved = false
            onSave(nil)
        } else if let data = DrawingExport.png(strokes: strokes, size: size, background: paper) {
            hasSaved = true
            onSave(data)
        }
    }

    private var canvas: some View {
        StrokesCanvas(strokes: strokes + (current.map { [$0] } ?? []), background: paper)
            .aspectRatio(4 / 3, contentMode: .fit)
            .overlay {
                if strokes.isEmpty && current == nil {
                    Text("scribble how that felt.")
                        .font(Theme.font(14.5, relativeTo: .footnote))
                        .foregroundStyle(Color(hex: 0x999488))
                        .allowsHitTesting(false)
                }
            }
            .background(GeometryReader { geo in Color.clear.onAppear { size = geo.size }.onChange(of: geo.size) { _, new in size = new } })
            .clipShape(canvasShape)
            .overlay(canvasShape.strokeBorder(palette.ink, lineWidth: 2))
            .background(canvasShape.fill(palette.ink).offset(x: 3, y: 4))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if current == nil {
                            current = DrawnStroke(points: [value.location], color: erasing ? paper : color, width: erasing ? 30 : 9)
                        } else {
                            current?.points.append(value.location)
                        }
                    }
                    .onEnded { _ in
                        if let current {
                            strokes.append(current)
                            dirty = true
                        }
                        current = nil
                    }
            )
            .accessibilityLabel("Drawing canvas")
            .accessibilityIdentifier("drawingCanvas")
    }

    private var canvasShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(topLeadingRadius: 13, bottomLeadingRadius: 22, bottomTrailingRadius: 20, topTrailingRadius: 15, style: .continuous)
    }

    private var tools: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(swatches.indices, id: \.self) { index in
                    let swatch = swatches[index]
                    let selected = !erasing && swatch == color
                    Button {
                        color = swatch
                        erasing = false
                    } label: {
                        Circle().fill(swatch).frame(width: 31, height: 31)
                            .overlay(Circle().strokeBorder(.white, lineWidth: 2))
                            .overlay(Circle().strokeBorder(palette.ink, lineWidth: 1.5).padding(-1.5))
                            .padding(3)
                            .overlay { if selected { Circle().strokeBorder(palette.ink, lineWidth: 2) } }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Pen color \(index + 1)")
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
                toolButton("eraser", selected: erasing) { erasing.toggle() }
                toolButton("clear") {
                    strokes = []
                    current = nil
                    dirty = hasSaved
                }
            }
            .padding(.vertical, 15)
            .padding(.horizontal, 6)
        }
    }

    private func toolButton(_ title: String, selected: Bool = false, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Theme.body(10.7, weight: .heavy))
                .foregroundStyle(selected ? Color.white : palette.ink)
                .padding(.horizontal, 9)
                .frame(minHeight: 44)
                .background(RoundedRectangle(cornerRadius: 8).fill(selected ? palette.ink : Color.white))
                .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(palette.ink, lineWidth: 1.5))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}
