import Foundation

struct ChallengeStore {
    static let shared = ChallengeStore()

    let all: [Challenge]

    init(bundle: Bundle = .main) {
        guard let url = bundle.url(forResource: "challenges", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([Challenge].self, from: data)
        else { fatalError("challenges.json is missing or malformed") }
        all = decoded
    }

    func challenge(id: Int) -> Challenge? { all.first { $0.id == id } }

    /// Prefers challenges the student hasn't done yet; falls back to replays.
    func pick(level: Level? = nil, excluding: Int? = nil, completed: Set<Int>) -> Challenge? {
        let pool = all.filter { (level == nil || $0.level == level) && $0.id != excluding }
        let fresh = pool.filter { !completed.contains($0.id) }
        return (fresh.isEmpty ? pool : fresh).randomElement()
    }
}
