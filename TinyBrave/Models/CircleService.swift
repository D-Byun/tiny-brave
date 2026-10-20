import Foundation

struct CircleMember: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var count: Int
    var streak: Int
    var isYou: Bool
}

struct CirclePing: Codable, Identifiable, Equatable {
    var id = UUID()
    var name: String
    var message: String
    var date = Date()
    /// Who sent it; nil for pings saved before circles had identities.
    var fromID: String?
}

struct CircleState: Codable, Equatable {
    var code: String
    var members: [CircleMember]
    var pings: [CirclePing]
}

/// Who you are in a circle: a random ID that never leaves the app's control, and a nickname instead of a real name.
struct CircleIdentity: Codable, Equatable {
    var userID: String
    var nickname: String
}

/// A circle of friends sharing progress, never media. The service owns this device's view of the circle
/// (cached so it opens instantly) and talks to a `CircleBackend` for everything shared.
@MainActor
final class CircleService: ObservableObject {
    static let shared = CircleService()
    static let storageKey = "circle"
    static let identityKey = "circleIdentity"
    static let defaultNickname = "friend"
    static let maxNicknameLength = 12
    private static let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")

    @Published private(set) var state: CircleState?
    @Published private(set) var nickname: String
    @Published var banner: CirclePing?

    let userID: String
    private let defaults: UserDefaults
    private let backend: CircleBackend

    init(defaults: UserDefaults = .standard, backend: CircleBackend? = nil, userID: String? = nil) {
        self.defaults = defaults
        self.backend = backend ?? LocalCircleBackend(defaults: defaults)

        var identity = defaults.data(forKey: Self.identityKey).flatMap { try? JSONDecoder().decode(CircleIdentity.self, from: $0) }
            ?? CircleIdentity(userID: UUID().uuidString, nickname: Self.defaultNickname)
        if let userID { identity.userID = userID }
        if let data = try? JSONEncoder().encode(identity) { defaults.set(data, forKey: Self.identityKey) }
        self.userID = identity.userID
        self.nickname = identity.nickname

        if let data = defaults.data(forKey: Self.storageKey), var cached = try? JSONDecoder().decode(CircleState.self, from: data) {
            for index in cached.members.indices where cached.members[index].isYou {
                cached.members[index].id = identity.userID
                cached.members[index].name = identity.nickname
            }
            state = cached
        }
    }

    var memberCount: Int? { state?.members.count }

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
        if let data = try? JSONEncoder().encode(CircleIdentity(userID: userID, nickname: clean)) {
            defaults.set(data, forKey: Self.identityKey)
        }
        guard var current = state, let index = current.members.firstIndex(where: \.isYou) else { return }
        current.members[index].name = clean
        save(current)
        push(current.members[index], code: current.code)
    }

    /// Six letters, upper-cased, or nil if the text doesn't have exactly six.
    static func normalize(_ text: String) -> String? {
        let letters = text.uppercased().filter { $0.isLetter }
        return letters.count == 6 ? letters : nil
    }

    static func makeCode<G: RandomNumberGenerator>(using generator: inout G) -> String {
        String((0..<6).map { _ in letters.randomElement(using: &generator)! })
    }

    private var me: CircleMember? { state?.members.first(where: \.isYou) }

    private func member(count: Int, streak: Int) -> CircleMember {
        CircleMember(id: userID, name: nickname, count: count, streak: streak, isYou: true)
    }

    /// Starts a new circle with a fresh code, retrying if the backend says the code is taken.
    func create(count: Int, streak: Int) async throws {
        let you = member(count: count, streak: streak)
        var generator = SystemRandomNumberGenerator()
        for _ in 0..<5 {
            do {
                let circle = try await backend.create(code: Self.makeCode(using: &generator), me: you)
                apply(circle, announce: false)
                return
            } catch CircleError.codeTaken {
                continue
            }
        }
        throw CircleError.unavailable
    }

    func join(code: String, count: Int, streak: Int) async throws {
        guard let normalized = Self.normalize(code) else { throw CircleError.invalidCode }
        let circle = try await backend.join(code: normalized, me: member(count: count, streak: streak))
        apply(circle, announce: false)
    }

    func leave() {
        guard let code = state?.code else { return }
        save(nil)
        banner = nil
        let userID = self.userID
        Task { try? await backend.leave(code: code, userID: userID) }
    }

    func updateYou(count: Int, streak: Int) {
        guard var current = state, let index = current.members.firstIndex(where: \.isYou) else { return }
        guard current.members[index].count != count || current.members[index].streak != streak else { return }
        current.members[index].count = count
        current.members[index].streak = streak
        save(current)
        push(current.members[index], code: current.code)
    }

    /// Tells the circle you finished a brave. Failures are dropped; a missed ping isn't worth a retry.
    func sendPing(_ message: PingMessage) async {
        guard let code = state?.code, let you = me else { return }
        try? await backend.send(message, code: code, from: you)
    }

    /// Pulls the latest members and pings once, and drops a banner for anything new from a friend.
    func refresh() async {
        guard let code = state?.code else { return }
        do {
            apply(try await backend.fetch(code: code), announce: true)
        } catch CircleError.notFound {
            save(nil)
        } catch {
            return
        }
    }

    /// Shows a friend's ping and keeps the latest six in the feed. Also the entry point for a pushed ping.
    func receive(_ ping: CirclePing) {
        guard var current = state else { return }
        current.pings = Array(([ping] + current.pings).prefix(CircleLimits.maxPings))
        save(current)
        banner = ping
    }

    private func push(_ you: CircleMember, code: String) {
        Task { try? await backend.update(code: code, me: you) }
    }

    /// Takes the backend's view of the circle, but trusts this device for your own row and hides your own pings.
    private func apply(_ circle: CircleState, announce: Bool) {
        var next = circle
        let local = me
        next.members = circle.members.map { member in
            if member.id == userID { return local ?? CircleMember(id: userID, name: member.name, count: member.count, streak: member.streak, isYou: true) }
            var friend = member
            friend.isYou = false
            return friend
        }
        next.members.sort { $0.isYou && !$1.isYou }
        next.pings = circle.pings.filter { $0.fromID != userID }

        let known = Set(state?.pings.map(\.id) ?? [])
        let fresh = announce && state?.code == next.code ? next.pings.filter { !known.contains($0.id) } : []
        if next != state { save(next) }
        if let latest = fresh.first { banner = latest }
    }

    private func save(_ new: CircleState?) {
        state = new
        if let new, let data = try? JSONEncoder().encode(new) {
            defaults.set(data, forKey: Self.storageKey)
        } else {
            defaults.removeObject(forKey: Self.storageKey)
        }
    }
}
