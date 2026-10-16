import SwiftUI
import AVFoundation
import AVKit

/// Records one short front-camera clip into a temporary file.
@MainActor
final class CameraRecorder: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    enum State: Equatable {
        case idle, starting, recording, recorded(URL), unavailable
    }

    static let maxSeconds = 15

    @Published var state: State = .idle
    @Published var secondsLeft = CameraRecorder.maxSeconds
    /// The note under the frame when the camera can't be used.
    @Published var unavailableMessage = "Camera permission was declined. Drawing still works."

    let session = AVCaptureSession()
    private let output = AVCaptureMovieFileOutput()
    private var timer: Timer?
    private var configured = false

    func wake() {
        guard state == .idle || state == .unavailable else { return }
        state = .starting
        Task {
            guard await Self.requestAccess() else {
                unavailableMessage = "Camera permission was declined. Drawing still works."
                state = .unavailable
                return
            }
            guard configure() else {
                unavailableMessage = "No camera here. Drawing still works."
                state = .unavailable
                return
            }
            let session = self.session
            await Task.detached { session.startRunning() }.value
            begin()
        }
    }

    func stop() {
        guard state == .recording else { return }
        output.stopRecording()
    }

    func retake() {
        if case .recorded(let url) = state { try? FileManager.default.removeItem(at: url) }
        state = .idle
        secondsLeft = Self.maxSeconds
    }

    func shutDown() {
        timer?.invalidate()
        if output.isRecording { output.stopRecording() }
        let session = self.session
        Task.detached { if session.isRunning { session.stopRunning() } }
    }

    private static func requestAccess() async -> Bool {
        for media in [AVMediaType.video, .audio] {
            switch AVCaptureDevice.authorizationStatus(for: media) {
            case .authorized: continue
            case .notDetermined:
                if await !AVCaptureDevice.requestAccess(for: media) { return media == .audio }
            default:
                return media == .audio
            }
        }
        return true
    }

    private func configure() -> Bool {
        if configured { return true }
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            ?? AVCaptureDevice.default(for: .video),
            let videoInput = try? AVCaptureDeviceInput(device: camera)
        else { return false }
        session.beginConfiguration()
        defer { session.commitConfiguration() }
        guard session.canAddInput(videoInput) else { return false }
        session.addInput(videoInput)
        if let mic = AVCaptureDevice.default(for: .audio), let audioInput = try? AVCaptureDeviceInput(device: mic), session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
        guard session.canAddOutput(output) else { return false }
        session.addOutput(output)
        configured = true
        return true
    }

    private func begin() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).mov")
        secondsLeft = Self.maxSeconds
        output.startRecording(to: url, recordingDelegate: self)
        state = .recording
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.secondsLeft -= 1
                if self.secondsLeft <= 0 { self.stop() }
            }
        }
    }

    nonisolated func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        Task { @MainActor in
            self.timer?.invalidate()
            let session = self.session
            Task.detached { session.stopRunning() }
            self.state = .recorded(outputFileURL)
        }
    }
}

private struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    final class PreviewView: UIView {
        override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
        var previewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
    }

    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.previewLayer.session = session
        view.previewLayer.videoGravity = .resizeAspectFill
        return view
    }

    func updateUIView(_ uiView: PreviewView, context: Context) {}
}

/// The Video tab: wake the camera, get fifteen seconds, then keep the clip or do it over.
struct VideoPad: View {
    var onSave: (URL) -> Void

    @Environment(\.palette) private var palette
    @StateObject private var recorder = CameraRecorder()

    var body: some View {
        VStack(spacing: 0) {
            frame
            Group {
                switch recorder.state {
                case .recorded(let url):
                    HStack(spacing: 10) {
                        Button("retake") { recorder.retake() }
                            .buttonStyle(BigButtonStyle(fill: palette.surface))
                        Button("keep") { onSave(url) }
                            .buttonStyle(BigButtonStyle())
                            .accessibilityIdentifier("keepVideo")
                    }
                case .recording:
                    Button("stop camera") { recorder.stop() }
                        .buttonStyle(BigButtonStyle(fill: Color(hex: 0xE65345)))
                case .starting:
                    Button("waking up…") {}
                        .buttonStyle(BigButtonStyle())
                        .disabled(true)
                case .idle, .unavailable:
                    Button("wake camera") { recorder.wake() }
                        .buttonStyle(BigButtonStyle())
                        .accessibilityIdentifier("wakeCamera")
                }
            }
            .padding(.top, 14)

            Text(note)
                .font(Theme.body(12.3, weight: .regular))
                .foregroundStyle(palette.muted)
                .multilineTextAlignment(.center)
                .padding(.vertical, 14)
                .padding(.horizontal, 4)
        }
        .onDisappear { recorder.shutDown() }
    }

    private var note: String {
        switch recorder.state {
        case .recorded: "tiny movie done. keep or do over."
        case .unavailable: recorder.unavailableMessage
        default: "tell story. make face. fifteen seconds plenty."
        }
    }

    private var frame: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return ZStack {
            Color(hex: 0x25251F)
            switch recorder.state {
            case .recording:
                CameraPreview(session: recorder.session)
            case .recorded(let url):
                VideoPlayer(player: AVPlayer(url: url))
            default:
                VStack(spacing: 7) {
                    Circle().strokeBorder(.white, lineWidth: 2)
                        .background(Circle().fill(RadialGradient(colors: [Color(hex: 0xE65345), .clear], center: .center, startRadius: 7, endRadius: 9)))
                        .frame(width: 48, height: 48)
                        .padding(.bottom, 8)
                    Text("camera sleeping").font(Theme.body(14))
                    Text("nothing is recorded until you say so.")
                        .font(Theme.body(10.7, weight: .regular))
                        .foregroundStyle(Color(hex: 0xD8D5CC))
                }
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(28)
            }
        }
        .aspectRatio(4 / 3, contentMode: .fit)
        .clipShape(shape)
        .overlay(alignment: .topTrailing) {
            if recorder.state == .recording {
                Text("0:\(String(format: "%02d", recorder.secondsLeft))")
                    .font(Theme.body(11.5, weight: .black))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Color(hex: 0xE65345)))
                    .padding(12)
                    .accessibilityIdentifier("recordTimer")
            }
        }
        .overlay(shape.strokeBorder(palette.ink, lineWidth: 2))
        .background(shape.fill(palette.ink).offset(x: 3, y: 4))
    }
}
