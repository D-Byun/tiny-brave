import Foundation

/// The balloon has `goal` puffs, one per distinct task completed, and it never deflates.
enum BraveProgress {
    static let goal = 30
    static func done(_ completed: Int) -> Int { min(max(completed, 0), goal) }
    /// UserDefaults key for the stage the home screen last showed; lets it animate from there to the current stage.
    static let lastSeenStageKey = "lastSeenStage"

    static func inflation(completed: Int) -> Double { Double(done(completed)) / Double(goal) }

    /// Every distinct task completed is a puff, however many were done in a day. Replaying a task adds nothing.
    static func stage(_ completions: [Completion], round: Int = 1) -> Int {
        done(Set(completions.filter { $0.round == round }.map(\.challengeID)).count)
    }
}

/// Rounds of 30. Odd rounds use tasks 1-30 and even rounds use the brand-new 31-60; from round 3 on
/// a set is revisited in a fresh surprise order.
enum Rounds {
    static let key = "round"

    static func isAllNew(_ round: Int) -> Bool { round == 2 }

    static func catalog(round: Int, all: [Challenge]) -> [Int] {
        let range = round % 2 == 1 ? 1...30 : 31...60
        return all.map(\.id).filter(range.contains)
    }

    /// The order a round starts in: list order for rounds 1 and 2, shuffled after that.
    static func startingOrder<G: RandomNumberGenerator>(round: Int, all: [Challenge], using generator: inout G) -> [Int] {
        let ids = catalog(round: round, all: all)
        return round >= 3 ? ids.shuffled(using: &generator) : ids
    }
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
