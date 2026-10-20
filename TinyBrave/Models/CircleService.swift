import Foundation

/// A circle of up to six friends sharing progress, never media or free text. The service owns this
/// device's view of it: who you are, whether circles are allowed for you, and the live friends,
/// requests and feed coming from a `CircleBackend`.
@MainActor
final class CircleService: ObservableObject {
    static let shared: CircleService = {
        // UI tests start from no circle at all.
        if ProcessInfo.processInfo.arguments.contains("-localCircles") {
            UserDefaults.standard.removeObject(forKey: ageBandKey)
            UserDefaults.standard.removeObject(forKey: nicknameKey)
        }
        return CircleService(backend: defaultBackend(), onReady: PushSetup.requestPermission)
    }()
    static let nicknameKey = "circleNickname"
    static let ageBandKey = "circleAgeBand"
    nonisolated static let defaultNickname = "friend"
    static let maxNicknameLength = 12
    private static let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")

    @Published private(set) var access: CircleAccess
    @Published private(set) var snapshot = CircleSnapshot()
    @Published private(set) var code: String?
    @Published private(set) var nickname: String
    @Published private(set) var userID: String?
    @Published var banner: CirclePing?

    private let defaults: UserDefaults
    private let backend: CircleBackend?
    private let onReady: (() -> Void)?
    private var observation: CircleObservation?
    private var starting = false
    private var hasSnapshot = false
    private var profile = CircleProfile(nickname: defaultNickname, count: 0, streak: 0)
    private var sentProfile: CircleProfile?
    private var deviceToken: String?

    init(defaults: UserDefaults = .standard, backend: CircleBackend?, onReady: (() -> Void)? = nil) {
        self.defaults = defaults
        self.backend = backend
        self.onReady = onReady
        let savedNickname = defaults.string(forKey: Self.nicknameKey) ?? Self.defaultNickname
        nickname = savedNickname
        let band = defaults.string(forKey: Self.ageBandKey).flatMap(AgeBand.init(rawValue:))
        access = backend == nil ? .unavailable : Self.access(for: band)
        profile.nickname = savedNickname
    }

    /// Local circles for UI tests and for debug builds without a Firebase config; Firebase otherwise.
    static func defaultBackend(arguments: [String] = ProcessInfo.processInfo.arguments) -> CircleBackend? {
        if arguments.contains("-localCircles") { return LocalCircleBackend() }
        if FirebaseSetup.configure(arguments: arguments) { return FirestoreCircleBackend() }
        #if DEBUG
        return LocalCircleBackend()
        #else
        return nil
        #endif
    }

    private static func access(for band: AgeBand?) -> CircleAccess {
        switch band {
        case nil: .needsAge
        case .under13: .needsConsent
        default: .ready
        }
    }

    private var storedBand: AgeBand? {
        get { defaults.string(forKey: Self.ageBandKey).flatMap(AgeBand.init(rawValue:)) }
        set { defaults.set(newValue?.rawValue, forKey: Self.ageBandKey) }
    }

    /// Friends plus you, or nil before you have any friends.
    var memberCount: Int? { snapshot.friends.isEmpty ? nil : snapshot.friends.count + 1 }

    var isFull: Bool { snapshot.friends.count >= CircleLimits.maxFriends }

    /// Signs in and rechecks the age band with the server (a grown-up may have said yes since last time).
    func start() async {
        guard let backend, !starting, userID == nil else { return }
        starting = true
        defer { starting = false }
        do {
            userID = try await backend.signIn()
        } catch {
            return
        }
        guard let band = storedBand else { return }
        let social = (try? await backend.setAgeBand(band)) ?? (band != .under13)
        await settle(social: social)
    }

    /// Records the age band. Exact birthdays stay on the phone; the server only gets the band.
    func setAge(_ band: AgeBand) async throws {
        guard let backend else { throw CircleError.unavailable }
        if userID == nil { userID = try await backend.signIn() }
        let social = try await backend.setAgeBand(band)
        storedBand = social ? band : .under13
        await settle(social: social)
    }

    private func settle(social: Bool) async {
        guard social else {
            stopObserving()
            access = .needsConsent
            return
        }
        access = .ready
        guard observation == nil, let backend else { return }
        observation = backend.observe { [weak self] in self?.apply($0) }
        code = try? await backend.code(reset: false)
        pushProfile()
        if let deviceToken { Task { try? await backend.registerDevice(token: deviceToken) } }
        onReady?()
    }

    private func stopObserving() {
        observation?.cancel()
        observation = nil
        hasSnapshot = false
        snapshot = CircleSnapshot()
        code = nil
    }

    /// Takes the latest snapshot and drops a banner for a friend's brave that wasn't there before.
    private func apply(_ next: CircleSnapshot) {
        let known = Set(snapshot.feed.map(\.id))
        if hasSnapshot, let fresh = next.feed.first(where: { !$0.mine && !known.contains($0.id) }) {
            banner = CirclePing(id: fresh.id, name: fresh.nickname, message: fresh.message.text)
        }
        hasSnapshot = true
        snapshot = next
    }

    // MARK: You

    /// Letters, numbers and spaces only, trimmed and short enough to fit a row.
    static func cleanNickname(_ text: String) -> String {
        let kept = text.filter { $0.isLetter || $0.isNumber || $0 == " " }
        let trimmed = String(kept.prefix(maxNicknameLength)).trimmingCharacters(in: .whitespaces)
        return trimmed.isEmpty ? defaultNickname : trimmed
    }

    func setNickname(_ text: String) {
        let clean = Self.cleanNickname(text)
        guard clean != nickname else { return }
        nickname = clean
        defaults.set(clean, forKey: Self.nicknameKey)
        profile.nickname = clean
        pushProfile()
    }

    func updateYou(count: Int, streak: Int) {
        profile.count = count
        profile.streak = streak
        pushProfile()
    }

    private func pushProfile() {
        guard access == .ready, let backend, profile != sentProfile else { return }
        let sending = profile
        sentProfile = sending
        Task {
            do {
                try await backend.updateProfile(sending, timeZone: TimeZone.current.identifier)
            } catch {
                if sentProfile == sending { sentProfile = nil }
            }
        }
    }

    /// Tells your circle you finished a brave. Failures are dropped; a missed post isn't worth a retry.
    func sendPing(_ message: PingMessage, stage: Int) async {
        guard access == .ready, let backend else { return }
        try? await backend.post(message, stage: stage)
    }

    func setDeviceToken(_ token: String) {
        guard token != deviceToken else { return }
        deviceToken = token
        guard access == .ready, let backend else { return }
        Task { try? await backend.registerDevice(token: token) }
    }

    // MARK: Codes

    /// Six letters, upper-cased, or nil if the text doesn't have exactly six.
    static func normalize(_ text: String) -> String? {
        let letters = text.uppercased().filter { $0.isLetter }
        return letters.count == 6 ? letters : nil
    }

    static func makeCode<G: RandomNumberGenerator>(using generator: inout G) -> String {
        String((0..<6).map { _ in letters.randomElement(using: &generator)! })
    }

    func loadCode() async throws {
        guard let backend else { throw CircleError.unavailable }
        code = try await backend.code(reset: false)
    }

    func resetCode() async throws {
        guard let backend else { throw CircleError.unavailable }
        code = try await backend.code(reset: true)
    }

    // MARK: Friends

    func addFriend(code text: String) async throws -> AddOutcome {
        guard let backend else { throw CircleError.unavailable }
        guard let normalized = Self.normalize(text) else { throw CircleError.invalidCode }
        guard normalized != code else { throw CircleError.ownCode }
        return try await backend.sendRequest(code: normalized)
    }

    func respond(to request: CircleRequest, accept: Bool) async throws {
        guard let backend else { throw CircleError.unavailable }
        try await backend.respond(to: request.id, accept: accept)
    }

    func remove(_ friend: CircleFriend) async throws {
        guard let backend else { throw CircleError.unavailable }
        try await backend.removeFriend(friend.id)
    }

    func block(_ friend: CircleFriend) async throws {
        guard let backend else { throw CircleError.unavailable }
        try await backend.block(friend.id)
    }

    func setMuted(_ muted: Bool, friend: CircleFriend) async throws {
        guard let backend else { throw CircleError.unavailable }
        try await backend.setMuted(muted, friend: friend.id)
    }

    /// Picking the reaction you already sent takes it back. Shows the change right away.
    func react(_ reaction: Reaction, to item: FeedItem) async throws {
        guard let backend, let userID, !item.mine else { throw CircleError.unavailable }
        let next: Reaction? = item.reaction(from: userID) == reaction ? nil : reaction
        if let index = snapshot.feed.firstIndex(where: { $0.id == item.id }) {
            snapshot.feed[index].reactions[userID] = next
        }
        do {
            try await backend.react(next, to: item)
        } catch {
            if let index = snapshot.feed.firstIndex(where: { $0.id == item.id }) {
                snapshot.feed[index].reactions[userID] = item.reaction(from: userID)
            }
            throw error
        }
    }

    /// Removes everything circles stored about you, here and on the server. Solo progress stays.
    func deleteData() async throws {
        guard let backend else { throw CircleError.unavailable }
        try await backend.deleteAccount()
        stopObserving()
        storedBand = nil
        userID = nil
        sentProfile = nil
        banner = nil
        access = .needsAge
    }
}
