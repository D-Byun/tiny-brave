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

/// The balloon has `goal` puffs, one per distinct task completed, and it never deflates.
enum BraveProgress {
    static let goal = 30

    static func done(_ completed: Int) -> Int { min(max(completed, 0), goal) }
    /// UserDefaults key for the stage the home screen last showed; lets it animate from there to the current stage.
    static let lastSeenStageKey = "lastSeenStage"

    static func inflation(completed: Int) -> Double { Double(done(completed)) / Double(goal) }

    /// Every distinct task completed is a puff, however many were done in a day. Replaying a task adds nothing.
    static func stage(_ completions: [Completion]) -> Int {
        done(Set(completions.map(\.challengeID)).count)
    }
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
    /// One caption per puff, from 0 through `BraveProgress.goal`.
    static let all = [
        "still thinking about it.", "one puff. balloon noticed.", "slightly less floppy.", "a cautious wobble.", "standing a little taller.",
        "swaying on purpose.", "testing the air.", "string getting nervous.", "heels off the ground.", "actually floating now.",
        "small lift. big deal.", "airborne and curious.", "learning to steer.", "left turn for no reason.", "right turn. also no reason.",
        "halfway and airborne.", "practicing a tiny dance.", "the wobble has rhythm.", "confidence doing loops.", "sky looking possible.",
        "officially hard to contain.", "balloon has opinions.", "dancing without permission.", "preparing to zoom.", "zoom rehearsal successful.",
        "main-character airspace.", "string barely involved.", "nearly ungovernable.", "one puff from legend.", "warming up the confetti.",
        "maximum puff. balloon has left the building.",
    ]

    static func text(puffs: Int) -> String { all[BraveProgress.done(puffs)] }
}
