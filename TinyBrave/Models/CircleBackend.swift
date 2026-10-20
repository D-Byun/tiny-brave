import Foundation

enum CircleError: Error, Equatable {
    case invalidCode, notFound, full, codeTaken, unavailable

    var message: String {
        switch self {
        case .invalidCode: "that code needs six letters."
        case .notFound: "couldn't find that circle."
        case .full: "that circle is full."
        case .codeTaken, .unavailable: "couldn't reach the circle. try again?"
        }
    }
}

enum CircleLimits {
    static let maxMembers = 6
    static let maxPings = 6
}

/// Everything the app needs from wherever circles are stored. `LocalCircleBackend` keeps them on this device.
@MainActor
protocol CircleBackend {
    /// Throws `.codeTaken` if the code already belongs to another circle.
    func create(code: String, me: CircleMember) async throws -> CircleState
    /// Throws `.notFound` or `.full`. Joining a circle you're already in just returns it.
    func join(code: String, me: CircleMember) async throws -> CircleState
    func leave(code: String, userID: String) async throws
    func update(code: String, me: CircleMember) async throws
    func send(_ message: PingMessage, code: String, from: CircleMember) async throws
    /// Throws `.notFound` once the circle is gone.
    func fetch(code: String) async throws -> CircleState
}

/// Circles stored in `UserDefaults`, shared by every `CircleService` built on the same defaults.
@MainActor
final class LocalCircleBackend: CircleBackend {
    static let storageKey = "localCircles"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func create(code: String, me: CircleMember) async throws -> CircleState {
        var circles = load()
        guard circles[code] == nil else { throw CircleError.codeTaken }
        let circle = CircleState(code: code, members: [me], pings: [])
        circles[code] = circle
        save(circles)
        return circle
    }

    func join(code: String, me: CircleMember) async throws -> CircleState {
        var circles = load()
        guard var circle = circles[code] else { throw CircleError.notFound }
        if let index = circle.members.firstIndex(where: { $0.id == me.id }) {
            circle.members[index] = me
        } else {
            guard circle.members.count < CircleLimits.maxMembers else { throw CircleError.full }
            circle.members.append(me)
        }
        circles[code] = circle
        save(circles)
        return circle
    }

    func leave(code: String, userID: String) async throws {
        var circles = load()
        guard var circle = circles[code] else { return }
        circle.members.removeAll { $0.id == userID }
        circles[code] = circle.members.isEmpty ? nil : circle
        save(circles)
    }

    func update(code: String, me: CircleMember) async throws {
        var circles = load()
        guard var circle = circles[code], let index = circle.members.firstIndex(where: { $0.id == me.id }) else { throw CircleError.notFound }
        circle.members[index] = me
        circles[code] = circle
        save(circles)
    }

    func send(_ message: PingMessage, code: String, from: CircleMember) async throws {
        var circles = load()
        guard var circle = circles[code] else { throw CircleError.notFound }
        let ping = CirclePing(name: from.name, message: message.text, fromID: from.id)
        circle.pings = Array(([ping] + circle.pings).prefix(CircleLimits.maxPings))
        circles[code] = circle
        save(circles)
    }

    func fetch(code: String) async throws -> CircleState {
        guard let circle = load()[code] else { throw CircleError.notFound }
        return circle
    }

    private func load() -> [String: CircleState] {
        guard let data = defaults.data(forKey: Self.storageKey) else { return [:] }
        return (try? JSONDecoder().decode([String: CircleState].self, from: data)) ?? [:]
    }

    private func save(_ circles: [String: CircleState]) {
        if let data = try? JSONEncoder().encode(circles) { defaults.set(data, forKey: Self.storageKey) }
    }
}
