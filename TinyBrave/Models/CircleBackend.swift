import Foundation

/// A live subscription to circle changes; cancel it to stop listening.
@MainActor
protocol CircleObservation: AnyObject {
    func cancel()
}

/// Everything the app needs from wherever circles live. `FirestoreCircleBackend` is the real one;
/// `LocalCircleBackend` keeps a pretend server in memory for tests, previews and UI tests.
@MainActor
protocol CircleBackend: AnyObject {
    /// Signs in (anonymously the first time) and returns this person's ID.
    func signIn() async throws -> String
    /// Records the age band and returns whether circles are now allowed.
    func setAgeBand(_ band: AgeBand) async throws -> Bool
    /// Your personal code. `reset` retires the old one.
    func code(reset: Bool) async throws -> String
    func sendRequest(code: String) async throws -> AddOutcome
    func respond(to userID: String, accept: Bool) async throws
    func removeFriend(_ userID: String) async throws
    func block(_ userID: String) async throws
    func setMuted(_ muted: Bool, friend userID: String) async throws
    func updateProfile(_ profile: CircleProfile, timeZone: String) async throws
    func post(_ message: PingMessage, stage: Int) async throws
    /// `nil` takes your reaction back.
    func react(_ reaction: Reaction?, to item: FeedItem) async throws
    func registerDevice(token: String) async throws
    func deleteAccount() async throws
    func observe(_ onChange: @escaping @MainActor (CircleSnapshot) -> Void) -> CircleObservation
}

/// The pretend server behind `LocalCircleBackend`. Share one between backends to act as several phones.
@MainActor
final class LocalCircleStore {
    static let shared = LocalCircleStore()

    struct Post {
        var id: String
        var owner: String
        var message: PingMessage
        var stage: Int
        var date: Date
        var reactions: [String: Reaction] = [:]
    }

    var ages: [String: AgeBand] = [:]
    var profiles: [String: CircleProfile] = [:]
    var codes: [String: String] = [:]
    var friends: [String: [String]] = [:]
    var muted: [String: Set<String>] = [:]
    var requests: [String: [String]] = [:]
    var blocks: [String: Set<String>] = [:]
    var posts: [Post] = []
    fileprivate var observers: [String: [ObjectIdentifier: (CircleSnapshot) -> Void]] = [:]

    func snapshot(for userID: String) -> CircleSnapshot {
        let mine = friends[userID] ?? []
        let visible = Set(mine + [userID])
        return CircleSnapshot(
            friends: mine.map { id in
                let profile = profiles[id] ?? CircleProfile(nickname: CircleService.defaultNickname, count: 0, streak: 0)
                return CircleFriend(id: id, nickname: profile.nickname, count: profile.count, streak: profile.streak, muted: muted[userID]?.contains(id) == true)
            },
            requests: (requests[userID] ?? []).map { CircleRequest(id: $0, nickname: profiles[$0]?.nickname ?? CircleService.defaultNickname) },
            feed: posts.filter { visible.contains($0.owner) }
                .sorted { $0.date > $1.date }
                .prefix(CircleLimits.feedSize)
                .map { post in
                    FeedItem(id: post.id, ownerID: post.owner, nickname: profiles[post.owner]?.nickname ?? CircleService.defaultNickname,
                             message: post.message, stage: post.stage, date: post.date, mine: post.owner == userID, reactions: post.reactions)
                }
        )
    }

    func notify() {
        for (userID, handlers) in observers {
            let snapshot = snapshot(for: userID)
            for handler in handlers.values { handler(snapshot) }
        }
    }

    fileprivate func unfriend(_ a: String, _ b: String) {
        friends[a]?.removeAll { $0 == b }
        friends[b]?.removeAll { $0 == a }
        for index in posts.indices {
            if posts[index].owner == a { posts[index].reactions[b] = nil }
            if posts[index].owner == b { posts[index].reactions[a] = nil }
        }
    }

    fileprivate func befriend(_ a: String, _ b: String) throws {
        requests[a]?.removeAll { $0 == b }
        requests[b]?.removeAll { $0 == a }
        guard friends[a]?.contains(b) != true else { return }
        guard (friends[a] ?? []).count < CircleLimits.maxFriends else { throw CircleError.youFull }
        guard (friends[b] ?? []).count < CircleLimits.maxFriends else { throw CircleError.theyFull }
        friends[a, default: []].append(b)
        friends[b, default: []].append(a)
    }
}

private final class LocalObservation: CircleObservation {
    let cancelAction: () -> Void
    init(cancel: @escaping () -> Void) { cancelAction = cancel }
    func cancel() { cancelAction() }
}

/// One phone talking to a `LocalCircleStore`. Follows the same rules as the Cloud Functions.
@MainActor
final class LocalCircleBackend: CircleBackend {
    let userID: String
    private let store: LocalCircleStore

    init(store: LocalCircleStore? = nil, userID: String = UUID().uuidString) {
        self.store = store ?? .shared
        self.userID = userID
    }

    private func requireSocial() throws {
        guard let band = store.ages[userID], band != .under13 else { throw CircleError.notAllowed }
    }

    func signIn() async throws -> String { userID }

    func setAgeBand(_ band: AgeBand) async throws -> Bool {
        let recorded = store.ages[userID] == .under13 ? .under13 : band
        store.ages[userID] = recorded
        return recorded != .under13
    }

    func code(reset: Bool) async throws -> String {
        try requireSocial()
        if !reset, let existing = store.codes.first(where: { $0.value == userID })?.key { return existing }
        store.codes = store.codes.filter { $0.value != userID }
        var generator = SystemRandomNumberGenerator()
        var code: String
        repeat { code = CircleService.makeCode(using: &generator) } while store.codes[code] != nil
        store.codes[code] = userID
        return code
    }

    func sendRequest(code: String) async throws -> AddOutcome {
        try requireSocial()
        guard let normalized = CircleService.normalize(code) else { throw CircleError.invalidCode }
        guard let target = store.codes[normalized], store.blocks[target]?.contains(userID) != true else { throw CircleError.notFound }
        guard target != userID else { throw CircleError.ownCode }
        guard store.blocks[userID]?.contains(target) != true else { throw CircleError.youBlocked }
        if store.friends[userID]?.contains(target) == true { return .friends }
        if store.requests[userID]?.contains(target) == true {
            try store.befriend(userID, target)
            store.notify()
            return .friends
        }
        guard (store.friends[userID] ?? []).count < CircleLimits.maxFriends else { throw CircleError.youFull }
        guard (store.friends[target] ?? []).count < CircleLimits.maxFriends else { throw CircleError.theyFull }
        if store.requests[target]?.contains(userID) != true { store.requests[target, default: []].append(userID) }
        store.notify()
        return .sent
    }

    func respond(to other: String, accept: Bool) async throws {
        try requireSocial()
        guard store.requests[userID]?.contains(other) == true else { throw CircleError.noRequest }
        if accept {
            try store.befriend(userID, other)
        } else {
            store.requests[userID]?.removeAll { $0 == other }
        }
        store.notify()
    }

    func removeFriend(_ other: String) async throws {
        store.unfriend(userID, other)
        store.notify()
    }

    func block(_ other: String) async throws {
        store.unfriend(userID, other)
        store.requests[userID]?.removeAll { $0 == other }
        store.requests[other]?.removeAll { $0 == userID }
        store.blocks[userID, default: []].insert(other)
        store.notify()
    }

    func setMuted(_ muted: Bool, friend other: String) async throws {
        if muted { store.muted[userID, default: []].insert(other) } else { store.muted[userID]?.remove(other) }
        store.notify()
    }

    func updateProfile(_ profile: CircleProfile, timeZone: String) async throws {
        try requireSocial()
        store.profiles[userID] = profile
        store.notify()
    }

    func post(_ message: PingMessage, stage: Int) async throws {
        try requireSocial()
        store.posts.append(.init(id: UUID().uuidString, owner: userID, message: message, stage: stage, date: .now))
        store.notify()
    }

    func react(_ reaction: Reaction?, to item: FeedItem) async throws {
        try requireSocial()
        guard item.ownerID != userID, store.friends[item.ownerID]?.contains(userID) == true,
              let index = store.posts.firstIndex(where: { $0.id == item.id }) else { throw CircleError.unavailable }
        store.posts[index].reactions[userID] = reaction
        store.notify()
    }

    func registerDevice(token: String) async throws {}

    func deleteAccount() async throws {
        for friend in store.friends[userID] ?? [] { store.unfriend(userID, friend) }
        for key in store.requests.keys { store.requests[key]?.removeAll { $0 == userID } }
        store.codes = store.codes.filter { $0.value != userID }
        store.posts.removeAll { $0.owner == userID }
        store.profiles[userID] = nil
        store.ages[userID] = nil
        store.notify()
    }

    func observe(_ onChange: @escaping @MainActor (CircleSnapshot) -> Void) -> CircleObservation {
        let token = LocalObservation(cancel: {})
        let key = ObjectIdentifier(token)
        let userID = userID
        store.observers[userID, default: [:]][key] = onChange
        onChange(store.snapshot(for: userID))
        return LocalObservation { [weak store] in store?.observers[userID]?[key] = nil }
    }
}
