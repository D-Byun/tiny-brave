import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.palette) private var palette
    @Environment(\.modelContext) private var context
    @AppStorage(BraveProgress.lastSeenStageKey) private var lastSeenStage = -1
    @AppStorage(Rounds.key) private var round = 1
    @Query private var completions: [Completion]
    @Query(sort: \Response.date, order: .reverse) private var responses: [Response]
    @StateObject private var circle = CircleService.shared

    @State private var puff: CGFloat = 1
    /// Order the remaining tasks were left in after skips; completed tasks drop out of it on their own.
    @State private var savedOrder = TaskQueueStorage.load()
    /// The brave just marked done. The card holds still on it while the reward is showing.
    @State private var completing: Completing?
    @State private var status = ""
    /// Responses saved so far for each brave, so a changed drawing or retake replaces its entry instead of adding another.
    @State private var keptResponses: [String: Response] = [:]
    @State private var toastMessage: String?
    @State private var burst = 0
    @State private var finaleToken = 0

    @State private var showTrack = false
    @State private var showCircle = false
    @State private var showFinale = false
    @State private var showRound = false
    @State private var showReel = false

    private let store = ChallengeStore.shared

    struct Completing: Equatable {
        let challenge: Challenge
        let day: Int
        let message: String
    }

    private var roundCompletions: [Completion] { completions.filter { $0.round == round } }
    private var completedIDs: Set<Int> { Set(roundCompletions.map(\.challengeID)) }
    private var stage: Int { BraveProgress.stage(completions, round: round) }
    /// The stage currently drawn; it steps toward `stage` so changes animate.
    private var shownStage: Int { lastSeenStage >= 0 ? lastSeenStage : stage }
    private var streak: Int { DailyGoal.streak(completions) }
    private var queue: TaskQueue {
        TaskQueue(catalog: Rounds.catalog(round: round, all: store.all), completed: completedIDs, saved: savedOrder)
    }
    private var current: Challenge? { queue.current.flatMap(store.challenge(id:)) }
    private var completedTitles: [String] {
        roundCompletions.sorted { $0.date < $1.date }
            .reduce(into: [Int]()) { if !$0.contains($1.challengeID) { $0.append($1.challengeID) } }
            .compactMap { store.challenge(id: $0)?.text }
    }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 0) {
                        BraveMeterView(puffs: shownStage, puff: puff, circleCount: circle.memberCount)
                        challengePanel
                    }
                }
                .onChange(of: completing) { _, new in
                    guard new != nil else { return }
                    withAnimation { proxy.scrollTo("reward", anchor: .top) }
                }
            }
        }
        .background(palette.background.ignoresSafeArea(edges: .bottom))
        .foregroundStyle(palette.ink)
        .overlay { ConfettiBurst(count: stage >= BraveProgress.goal ? 100 : 28, trigger: burst) }
        .overlay(alignment: .top) { pingOverlay }
        .modalDialog(isPresented: $showRound) { roundDialog }
        .modalDialog(isPresented: $showFinale, dismissOnBackdrop: false) {
            FinaleView(
                round: round,
                onReel: { showFinale = false; showReel = true },
                onTrack: { showFinale = false; showTrack = true },
                onNewRound: { showFinale = false; showRound = true },
                onClose: { showFinale = false }
            )
        }
        .toast($toastMessage)
        .sheet(isPresented: $showTrack) {
            TrackSheet(
                round: round, completedTitles: completedTitles, responses: responses, streak: streak,
                onClose: { showTrack = false }, onReset: resetProgress
            )
        }
        .sheet(isPresented: $showCircle) {
            CircleSheet(service: circle, count: stage, streak: streak) { showCircle = false }
        }
        .fullScreenCover(isPresented: $showReel) {
            ReelView(responses: responses.filter { $0.round == round }.sorted { $0.date < $1.date }) { showReel = false }
        }
        .task(id: stage) { await animateBalloon() }
        .task(id: finaleToken) {
            guard finaleToken > 0 else { return }
            try? await Task.sleep(for: .seconds(5))
            if !Task.isCancelled, stage >= BraveProgress.goal, !showRound, !showTrack { showFinale = true }
        }
        .onAppear {
            // UI tests start from an empty archive; nothing else ever clears it.
            if ProcessInfo.processInfo.arguments.contains("-resetArchive") { try? context.delete(model: Response.self) }
            circle.updateYou(count: stage, streak: streak)
        }
        .onChange(of: stage) { _, _ in circle.updateYou(count: stage, streak: streak) }
        .task(id: circle.state?.code) {
            while !Task.isCancelled, circle.state != nil {
                try? await Task.sleep(for: .seconds(15))
                await circle.refresh()
            }
        }
    }

    // MARK: Top bar

    private var topBar: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                BalloonGlyph()
                Text("TINY BRAVE")
                    .font(Theme.body(13, weight: .black))
                    .tracking(2.2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)
            Spacer(minLength: 4)
            Button { showCircle = true } label: {
                HStack(spacing: 6) {
                    OverlappingCircles().accessibilityHidden(true)
                    Text("Circle").font(Theme.body(14, weight: .heavy))
                }
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .background(Capsule().fill(palette.surface))
                .overlay(Capsule().strokeBorder(palette.ink, lineWidth: 1.8))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Circle")
            Button { showTrack = true } label: { PillLabel(title: "Track", symbol: "chart.bar.fill") }
                .buttonStyle(.plain)
                .accessibilityLabel("Track")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(palette.sun.ignoresSafeArea(edges: .top))
    }

    @ViewBuilder
    private var pingOverlay: some View {
        if let ping = circle.banner {
            FriendPingBanner(ping: ping)
                .transition(.move(edge: .top).combined(with: .opacity))
                .task(id: ping.id) {
                    try? await Task.sleep(for: .seconds(4.3))
                    if !Task.isCancelled { withAnimation { circle.banner = nil } }
                }
        }
    }

    // MARK: Challenge panel

    private var challengePanel: some View {
        VStack(spacing: 0) {
            if let completing {
                TaskCardView(challenge: completing.challenge, day: completing.day, round: round)
                rewardCard(completing).id("reward").padding(.top, 25)
            } else if let current {
                TaskCardView(challenge: current, day: min(stage + 1, BraveProgress.goal), round: round)
                actions.padding(.top, 25)
            } else {
                finishedCard
            }
            progressLink
        }
        .padding(.horizontal, 20)
        .padding(.top, 26)
        .padding(.bottom, 34)
        .frame(maxWidth: .infinity)
        .background {
            ZStack {
                palette.background
                DotGrain(color: palette.ink, opacity: 0.11)
            }
        }
        .animation(.easeOut(duration: 0.3), value: completing)
    }

    private var actions: some View {
        VStack(spacing: 17) {
            Button(action: complete) {
                HStack(spacing: 10) {
                    Text("yep. did brave thing.")
                    Image(systemName: "checkmark").font(.system(size: 18, weight: .bold)).accessibilityHidden(true)
                }
            }
            .buttonStyle(BigButtonStyle())
            .accessibilityLabel("yep. did brave thing.")
            Button(action: skip) {
                HStack(spacing: 8) {
                    ShuffleArrow().stroke(palette.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round)).frame(width: 20, height: 10)
                        .accessibilityHidden(true)
                    Text("not this brave. give other.")
                }
                .font(Theme.font(13.2, relativeTo: .footnote))
                .padding(.horizontal, 12)
                .frame(minHeight: 44)
                .overlay(Capsule().strokeBorder(palette.ink, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("not this brave. give other.")
        }
    }

    private func rewardCard(_ completing: Completing) -> some View {
        let isFinal = stage >= BraveProgress.goal || shownStage >= BraveProgress.goal
        return RewardCard(
            kicker: "PUFF \(min(completing.day, BraveProgress.goal)) OF \(BraveProgress.goal)",
            message: completing.message,
            isFinal: isFinal,
            status: status,
            onDrawing: { saveDrawing($0, for: completing) },
            onAudio: { saveAudio($0, for: completing) },
            onNext: nextBrave,
            onFinale: { showFinale = true },
            onNewRound: { showRound = true }
        )
    }

    /// Shown when every brave in the round is done and the reward has been closed.
    private var finishedCard: some View {
        VStack(spacing: 14) {
            Text("thirty. whole. braves.")
                .font(Theme.font(27, relativeTo: .title2))
                .multilineTextAlignment(.center)
            Button { showFinale = true } label: { Text("see the finale") }
                .buttonStyle(BigButtonStyle())
                .accessibilityIdentifier("seeFinale")
            Button { showRound = true } label: { Text("new round") }
                .buttonStyle(BigButtonStyle(fill: palette.surface))
                .accessibilityIdentifier("newRound")
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("allDone")
    }

    private var progressLink: some View {
        Button { showTrack = true } label: {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Track my brave").font(Theme.body(13.6, weight: .heavy))
                    Text("drawings, recordings, streaks, the whole saga")
                        .font(Theme.body(10.7, weight: .semibold))
                        .foregroundStyle(palette.muted)
                }
                Spacer()
                Image(systemName: "arrow.right").font(.system(size: 24, weight: .light)).accessibilityHidden(true)
            }
            .padding(.top, 17)
            .padding(.bottom, 7)
            .frame(maxWidth: .infinity, minHeight: 56, alignment: .leading)
            .overlay(alignment: .top) { Rectangle().fill(palette.line).frame(height: 1.5) }
        }
        .buttonStyle(.plain)
        .padding(.top, 29)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Track my brave")
        .accessibilityAddTraits(.isButton)
    }

    private var roundDialog: some View {
        let next = round + 1
        let allNew = Rounds.isAllNew(next)
        return VStack(spacing: 0) {
            MiniBalloon().padding(.bottom, 8)
            Text(allNew ? "thirty brand-new braves?" : "round \(next)?")
                .font(Theme.font(27, relativeTo: .title2))
                .multilineTextAlignment(.center)
                .padding(.bottom, 8)
            Text(allNew
                 ? "Round 2 has 30 entirely new challenges. Your archive stays exactly where it is."
                 : "Round \(next) revisits a 30-challenge set in a fresh surprise order. Your archive stays put.")
                .font(Theme.body(15, weight: .regular))
                .foregroundStyle(palette.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
            Button(action: startNextRound) { Text("open round \(next)") }
                .buttonStyle(BigButtonStyle())
                .padding(.top, 20)
                .accessibilityIdentifier("openRound")
        }
        .padding(.horizontal, 24)
        .padding(.top, 30)
        .padding(.bottom, 23)
    }

    // MARK: Actions

    /// Steps the balloon one stage at a time from where the user last saw it to where it is now.
    private func animateBalloon() async {
        var shown = shownStage
        lastSeenStage = shown
        while shown != stage {
            let inflating = shown < stage
            do { try await Task.sleep(for: .milliseconds(400)) } catch { puff = 1; return }
            shown += inflating ? 1 : -1
            lastSeenStage = shown
            puff = inflating ? 1.12 : 0.92
            do { try await Task.sleep(for: .milliseconds(250)) } catch { puff = 1; return }
            puff = 1
        }
    }

    private func complete() {
        guard let current else { return }
        let newStage = min(stage + 1, BraveProgress.goal)
        context.insert(Completion(challengeID: current.id, round: round))
        let ping = PingMessage.forStage(newStage, goal: BraveProgress.goal)
        completing = Completing(challenge: current, day: newStage, message: ping.text)
        Task { await circle.sendPing(ping) }
        status = ""
        burst += 1
        if newStage >= BraveProgress.goal { finaleToken += 1 }
    }

    /// Sends today's task to the back of the list so the next one in order comes up.
    private func skip() {
        var next = queue
        next.skip()
        TaskQueueStorage.save(next)
        withAnimation { savedOrder = next.ids }
    }

    private func nextBrave() {
        withAnimation { completing = nil }
        status = ""
    }

    /// Keeps, replaces or (with nil) removes the one drawing or recording for a brave, so Track updates right away.
    private func keepResponse(_ kind: ResponseKind, for completing: Completing, write: (URL) throws -> Void, hasContent: Bool) {
        let key = "\(round)-\(completing.challenge.id)-\(kind.rawValue)"
        let existing = keptResponses[key]
        guard hasContent else {
            guard let existing else { return }
            try? FileManager.default.removeItem(at: ResponseFiles.url(for: existing.filename))
            context.delete(existing)
            keptResponses[key] = nil
            status = ""
            return
        }
        let name = ResponseFiles.newFilename(kind: kind)
        do { try write(ResponseFiles.url(for: name)) } catch {
            status = "couldn't keep that one. try again?"
            return
        }
        if let existing {
            try? FileManager.default.removeItem(at: ResponseFiles.url(for: existing.filename))
            existing.filename = name
            existing.date = .now
        } else {
            let response = Response(challengeID: completing.challenge.id, title: completing.challenge.text, round: round, kind: kind, filename: name)
            context.insert(response)
            keptResponses[key] = response
        }
        status = kind == .drawing ? "drawing saved to Track." : "tiny recording saved to Track."
    }

    private func saveDrawing(_ data: Data?, for completing: Completing) {
        keepResponse(.drawing, for: completing, write: { try data?.write(to: $0) }, hasContent: data != nil)
    }

    private func saveAudio(_ url: URL?, for completing: Completing) {
        keepResponse(.audio, for: completing, write: { destination in
            if let url { try FileManager.default.copyItem(at: url, to: destination) }
        }, hasContent: url != nil)
    }

    private func startNextRound() {
        var generator = SystemRandomNumberGenerator()
        let next = round + 1
        let order = Rounds.startingOrder(round: next, all: store.all, using: &generator)
        TaskQueueStorage.save(TaskQueue(catalog: order, completed: [], saved: order))
        savedOrder = order
        round = next
        lastSeenStage = 0
        completing = nil
        status = ""
        showRound = false
        toastMessage = Rounds.isAllNew(next) ? "30 new braves unlocked." : "round \(next) begins."
    }

    private func resetProgress() {
        for completion in completions where completion.round == round { context.delete(completion) }
        TaskQueueStorage.clear()
        savedOrder = []
        lastSeenStage = 0
        completing = nil
        status = ""
        showTrack = false
        toastMessage = "fresh balloon. archive stayed put."
    }
}

/// The little balloon beside the wordmark.
private struct BalloonGlyph: View {
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            Ellipse().stroke(palette.ink, lineWidth: 2.2).frame(width: 20, height: 24).offset(y: -2)
            Rectangle().fill(palette.surface).frame(width: 7, height: 7).rotationEffect(.degrees(45))
                .overlay(Rectangle().stroke(palette.ink, lineWidth: 1.6).rotationEffect(.degrees(45)))
                .offset(x: 7, y: 11)
        }
        .frame(width: 30, height: 34)
        .rotationEffect(.degrees(-10))
        .accessibilityHidden(true)
    }
}

private struct OverlappingCircles: View {
    @Environment(\.palette) private var palette

    var body: some View {
        ZStack {
            Circle().strokeBorder(palette.ink, lineWidth: 2).background(Circle().fill(palette.sun)).frame(width: 14, height: 14).offset(x: -4)
            Circle().strokeBorder(palette.ink, lineWidth: 2).background(Circle().fill(palette.sun)).frame(width: 14, height: 14).offset(x: 4)
        }
        .frame(width: 24, height: 16)
    }
}

private struct ShuffleArrow: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX - 1, y: r.minY + 1), control: CGPoint(x: r.midX, y: r.minY - 3))
        p.move(to: CGPoint(x: r.maxX - 6, y: r.minY - 3))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + 1))
        p.addLine(to: CGPoint(x: r.maxX - 5, y: r.minY + 6))
        return p
    }
}
