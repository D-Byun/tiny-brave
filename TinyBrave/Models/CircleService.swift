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
}

struct CircleState: Codable, Equatable {
    var code: String
    var members: [CircleMember]
    var pings: [CirclePing]
}

/// A circle of friends sharing progress, never media. There's no server in this project yet, so circles
/// live on this device: you can make one, and a join only succeeds for a code this device already knows.
@MainActor
final class CircleService: ObservableObject {
    static let shared = CircleService()
    static let storageKey = "circle"
    private static let letters = Array("ABCDEFGHJKLMNPQRSTUVWXYZ")

    @Published private(set) var state: CircleState?
    @Published var banner: CirclePing?

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let data = defaults.data(forKey: Self.storageKey) {
            state = try? JSONDecoder().decode(CircleState.self, from: data)
        }
    }

    var memberCount: Int? { state?.members.count }

    /// Six letters, upper-cased, or nil if the text doesn't have exactly six.
    static func normalize(_ text: String) -> String? {
        let letters = text.uppercased().filter { $0.isLetter }
        return letters.count == 6 ? letters : nil
    }

    static func makeCode<G: RandomNumberGenerator>(using generator: inout G) -> String {
        String((0..<6).map { _ in letters.randomElement(using: &generator)! })
    }

    func create(count: Int, streak: Int) {
        var generator = SystemRandomNumberGenerator()
        let you = CircleMember(id: "you", name: "you", count: count, streak: streak, isYou: true)
        save(CircleState(code: Self.makeCode(using: &generator), members: [you], pings: []))
    }

    /// Returns false when the code doesn't match any circle this device knows about.
    func join(code: String) -> Bool {
        guard let normalized = Self.normalize(code), state?.code == normalized else { return false }
        return true
    }

    func leave() { save(nil) }

    func updateYou(count: Int, streak: Int) {
        guard var current = state, let index = current.members.firstIndex(where: \.isYou) else { return }
        guard current.members[index].count != count || current.members[index].streak != streak else { return }
        current.members[index].count = count
        current.members[index].streak = streak
        save(current)
    }

    /// Shows a friend's ping and keeps the latest six in the feed.
    func receive(_ ping: CirclePing) {
        guard var current = state else { return }
        current.pings = Array(([ping] + current.pings).prefix(6))
        save(current)
        banner = ping
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
