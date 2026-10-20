import SwiftUI
import AVFoundation

/// Records one short voice clip into a temporary file and plays it back for review.
@MainActor
final class AudioRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate, AVAudioPlayerDelegate {
    enum State: Equatable {
        case idle, starting, recording, recorded(URL), unavailable
    }

    static let maxSeconds = 15

    @Published var state: State = .idle
    @Published var secondsLeft = AudioRecorder.maxSeconds
    /// 0...1, how loud the room is right now.
    @Published var level: Float = 0
    @Published var isPlaying = false
    /// The note under the frame when recording can't start.
    @Published var unavailableMessage = "Microphone permission was declined. Drawing still works."

    private var recorder: AVAudioRecorder?
    private var player: AVAudioPlayer?
    private var timer: Timer?

    func start() {
        guard state == .idle || state == .unavailable else { return }
        state = .starting
        Task {
            guard await Self.requestAccess() else {
                unavailableMessage = "Microphone permission was declined. Drawing still works."
                state = .unavailable
                return
            }
            guard begin() else {
                unavailableMessage = "No microphone here. Drawing still works."
                state = .unavailable
                return
            }
        }
    }

    func stop() {
        guard state == .recording else { return }
        finish()
    }

    func retake() {
        stopPlayback()
        if case .recorded(let url) = state { try? FileManager.default.removeItem(at: url) }
        state = .idle
        secondsLeft = Self.maxSeconds
        level = 0
    }

    func togglePlayback() {
        if isPlaying {
            stopPlayback()
            return
        }
        guard case .recorded(let url) = state, let player = try? AVAudioPlayer(contentsOf: url) else { return }
        try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        player.delegate = self
        self.player = player
        isPlaying = player.play()
    }

    func shutDown() {
        timer?.invalidate()
        recorder?.stop()
        recorder = nil
        stopPlayback()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private static func requestAccess() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return true
        case .undetermined: return await AVAudioApplication.requestRecordPermission()
        default: return false
        }
    }

    private func begin() -> Bool {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
            try session.setActive(true)
        } catch { return false }
        guard session.isInputAvailable else { return false }

        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        guard let recorder = try? AVAudioRecorder(url: url, settings: settings) else { return false }
        recorder.delegate = self
        recorder.isMeteringEnabled = true
        guard recorder.record(forDuration: TimeInterval(Self.maxSeconds)) else { return false }
        self.recorder = recorder

        secondsLeft = Self.maxSeconds
        state = .recording
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.tick() }
        }
        return true
    }

    private func tick() {
        guard let recorder, state == .recording else { return }
        recorder.updateMeters()
        // -50 dB is quiet, 0 dB is as loud as it gets.
        level = max(0, min(1, (recorder.averagePower(forChannel: 0) + 50) / 50))
        secondsLeft = max(0, Self.maxSeconds - Int(recorder.currentTime))
        if !recorder.isRecording { finish() }
    }

    private func finish() {
        guard state == .recording, let recorder else { return }
        timer?.invalidate()
        let url = recorder.url
        let seconds = recorder.currentTime
        recorder.stop()
        self.recorder = nil
        level = 0
        if seconds < 0.3 || !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
            state = .idle
            secondsLeft = Self.maxSeconds
        } else {
            state = .recorded(url)
        }
    }

    private func stopPlayback() {
        player?.stop()
        player = nil
        isPlaying = false
    }

    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        Task { @MainActor in self.finish() }
    }

    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in self.isPlaying = false }
    }
}

/// The Audio tab: wake the microphone, get fifteen seconds. The clip is kept as soon as recording ends; retaking removes it.
struct AudioPad: View {
    /// Called with the finished clip, or nil when the clip was thrown away to retake.
    var onSave: (URL?) -> Void

    @Environment(\.palette) private var palette
    @StateObject private var recorder = AudioRecorder()

    var body: some View {
        VStack(spacing: 0) {
            frame
            Group {
                switch recorder.state {
                case .recorded:
                    HStack(spacing: 10) {
                        Button("retake") {
                            recorder.retake()
                            onSave(nil)
                        }
                        .buttonStyle(BigButtonStyle())
                        .accessibilityIdentifier("retakeAudio")
                    }
                case .recording:
                    Button("stop recording") { recorder.stop() }
                        .buttonStyle(BigButtonStyle(fill: Color(hex: 0xE65345)))
                        .accessibilityIdentifier("stopRecording")
                case .starting:
                    Button("waking up…") {}
                        .buttonStyle(BigButtonStyle())
                        .disabled(true)
                case .idle, .unavailable:
                    Button("start recording") { recorder.start() }
                        .buttonStyle(BigButtonStyle())
                        .accessibilityIdentifier("startRecording")
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
        .onChange(of: recorder.state) { _, new in
            if case .recorded(let url) = new { onSave(url) }
        }
        .onDisappear {
            if recorder.state == .recording {
                recorder.stop()
                if case .recorded(let url) = recorder.state { onSave(url) }
            }
            recorder.shutDown()
        }
    }

    private var note: String {
        switch recorder.state {
        case .recorded: "tiny recording saved to Track. listen, or do it over."
        case .unavailable: recorder.unavailableMessage
        default: "tell story. say it loud. fifteen seconds plenty."
        }
    }

    private var frame: some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return ZStack {
            Color(hex: 0x25251F)
            switch recorder.state {
            case .recording:
                VStack(spacing: 12) {
                    Image(systemName: "mic.fill").font(.system(size: 34))
                        .scaleEffect(1 + CGFloat(recorder.level) * 0.35)
                        .animation(.easeOut(duration: 0.1), value: recorder.level)
                    Text("listening…").font(Theme.body(14))
                }
                .foregroundStyle(.white)
            case .recorded:
                Button { recorder.togglePlayback() } label: {
                    VStack(spacing: 10) {
                        Image(systemName: recorder.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 54))
                        Text(recorder.isPlaying ? "tap to pause" : "tap to listen").font(Theme.body(13))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("playAudio")
            default:
                VStack(spacing: 7) {
                    Circle().strokeBorder(.white, lineWidth: 2)
                        .background(Circle().fill(RadialGradient(colors: [Color(hex: 0xE65345), .clear], center: .center, startRadius: 7, endRadius: 9)))
                        .frame(width: 48, height: 48)
                        .padding(.bottom, 8)
                    Text("microphone sleeping").font(Theme.body(14))
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
