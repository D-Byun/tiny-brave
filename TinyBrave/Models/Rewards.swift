import Foundation

/// The balloon has `goal` puffs, one per distinct task completed, and it never deflates.
enum BraveProgress {
    static let goal = 30
    /// Only the first set of 30 tasks exists so far.
    static let round = 1

    static func done(_ completed: Int) -> Int { min(max(completed, 0), goal) }
    /// UserDefaults key for the stage the home screen last showed; lets it animate from there to the current stage.
    static let lastSeenStageKey = "lastSeenStage"

    static func inflation(completed: Int) -> Double { Double(done(completed)) / Double(goal) }

    /// Every distinct task completed is a puff, however many were done in a day. Replaying a task adds nothing.
    static func stage(_ completions: [Completion]) -> Int {
        done(Set(completions.map(\.challengeID)).count)
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
