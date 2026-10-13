import Foundation

struct Debris: Identifiable, Hashable {
    let id: String
    let emoji: String
    let name: String

    static let all: [Debris] = [
        Debris(id: "paperclip", emoji: "📎", name: "a bent paperclip"),
        Debris(id: "star", emoji: "⭐", name: "a gold star"),
        Debris(id: "receipt", emoji: "🧾", name: "a suspicious receipt"),
        Debris(id: "sticker", emoji: "🏷️", name: "a peeling sticker"),
        Debris(id: "pebble", emoji: "🪨", name: "an oddly important pebble"),
    ]

    static func random() -> Debris { all.randomElement()! }
    static func find(_ id: String) -> Debris? { all.first { $0.id == id } }
}

/// The balloon has `goal` stages, one per day of the current streak, so a broken streak deflates it.
enum BraveProgress {
    static let goal = 10

    static func done(_ completed: Int) -> Int { min(max(completed, 0), goal) }
    /// UserDefaults key for the stage the home screen last showed; lets it animate from there to the current stage.
    static let lastSeenStageKey = "lastSeenStage"

    static func inflation(completed: Int) -> Double { Double(done(completed)) / Double(goal) }
}

struct Certificate: Identifiable {
    let count: Int
    let title: String
    var id: Int { count }

    static let all: [Certificate] = [
        Certificate(count: 1, title: "Tiny Brave Acquired"),
        Certificate(count: 3, title: "Survived Mild Awkwardness"),
        Certificate(count: 5, title: "Asked Anyway"),
        Certificate(count: 7, title: "Nobody Exploded"),
        Certificate(count: 10, title: "Fully Inflated"),
    ]
}

enum BalloonCaption {
    static func text(inflation: Double) -> String {
        switch inflation {
        case ..<0.1: "brave-ish."
        case ..<0.4: "getting less floppy."
        case ..<0.7: "suspiciously buoyant."
        case ..<1.0: "probably ready."
        default: "dangerously confident."
        }
    }
}
