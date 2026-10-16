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
}
