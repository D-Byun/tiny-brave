import XCTest
@testable import TinyBrave

final class ChallengeStoreTests: XCTestCase {
    func testSixtyChallengesAcrossFourCategories() {
        let all = ChallengeStore.shared.all
        XCTAssertEqual(all.count, 60)
        XCTAssertEqual(BraveCategory.allCases.count, 4)
        let counts = Dictionary(grouping: all, by: \.category).mapValues(\.count)
        XCTAssertEqual(counts, [.connect: 16, .speak: 16, .try: 14, .reset: 14])
        XCTAssertTrue(all.allSatisfy { !$0.text.isEmpty && !$0.why.isEmpty })
    }

    func testEveryLevelHasAtLeastOneChallenge() {
        for level in Level.allCases {
            XCTAssertTrue(ChallengeStore.shared.all.contains { $0.level == level }, "\(level)")
        }
    }

    func testIDsAreUnique() {
        let ids = ChallengeStore.shared.all.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testThereIsACaptionForEveryPuff() {
        XCTAssertEqual(BalloonCaption.all.count, BraveProgress.goal + 1)
        XCTAssertEqual(BalloonCaption.text(puffs: 0), "still thinking about it.")
        XCTAssertEqual(BalloonCaption.text(puffs: 5), "swaying on purpose.")
        XCTAssertEqual(BalloonCaption.text(puffs: 30), "maximum puff. balloon has left the building.")
        XCTAssertEqual(BalloonCaption.text(puffs: 99), BalloonCaption.text(puffs: 30))
        XCTAssertEqual(BalloonCaption.text(puffs: -1), BalloonCaption.text(puffs: 0))
    }

    private func completion(daysAgo: Int, from now: Date) -> Completion {
        Completion(challengeID: 1, date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: now)!)
    }

    func testExtraCompletionsSameDayDoNotAddToStreak() {
        let now = Date()
        let completions = [completion(daysAgo: 0, from: now), completion(daysAgo: 0, from: now), completion(daysAgo: 0, from: now)]
        XCTAssertEqual(DailyGoal.streak(completions, now: now), 1)
    }

    func testStreakCountsConsecutiveDaysAndBreaksOnGap() {
        let now = Date()
        let run = [0, 1, 2].map { completion(daysAgo: $0, from: now) }
        XCTAssertEqual(DailyGoal.streak(run, now: now), 3)
        let gap = [0, 1, 3].map { completion(daysAgo: $0, from: now) }
        XCTAssertEqual(DailyGoal.streak(gap, now: now), 2)
    }

    func testStreakSurvivesUntilEndOfDayThenResets() {
        let now = Date()
        let yesterdayOnly = [completion(daysAgo: 1, from: now)]
        XCTAssertEqual(DailyGoal.streak(yesterdayOnly, now: now), 1)
        let twoDaysLater = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        XCTAssertEqual(DailyGoal.streak(yesterdayOnly, now: twoDaysLater), 0)
        XCTAssertEqual(DailyGoal.streak([], now: now), 0)
    }

    func testBalloonHasThirtyStagesAndCapsAtGoal() {
        XCTAssertEqual(BraveProgress.goal, 30)
        XCTAssertEqual(BraveProgress.inflation(completed: 0), 0)
        XCTAssertEqual(BraveProgress.inflation(completed: 15), 0.5)
        XCTAssertEqual(BraveProgress.inflation(completed: 30), 1)
        XCTAssertEqual(BraveProgress.inflation(completed: 45), 1)
    }

    func testEveryDistinctTaskIsAPuffEvenOnTheSameDay() {
        let now = Date()
        let sameDay = [1, 2, 3].map { Completion(challengeID: $0, date: now) }
        XCTAssertEqual(BraveProgress.stage(sameDay), 3)
        XCTAssertEqual(BraveProgress.stage([]), 0)
    }

    func testReplayingATaskDoesNotAddAPuff() {
        let now = Date()
        let replays = [1, 1, 2].map { Completion(challengeID: $0, date: now) }
        XCTAssertEqual(BraveProgress.stage(replays), 2)
    }

    func testBalloonNeverDeflatesWhenDaysAreMissed() {
        let now = Date()
        let cal = Calendar.current
        let old = (1...4).map { Completion(challengeID: $0, date: cal.date(byAdding: .day, value: -($0 + 10), to: now)!) }
        XCTAssertEqual(BraveProgress.stage(old), 4)
        XCTAssertEqual(DailyGoal.streak(old, now: now), 0, "The streak still breaks")
    }

    func testStageOnlyCountsTheCurrentRound() {
        let now = Date()
        let mixed = [Completion(challengeID: 1, date: now, round: 1), Completion(challengeID: 31, date: now, round: 2), Completion(challengeID: 32, date: now, round: 2)]
        XCTAssertEqual(BraveProgress.stage(mixed, round: 1), 1)
        XCTAssertEqual(BraveProgress.stage(mixed, round: 2), 2)
    }

    func testRoundsUseTheirOwnThirtyChallenges() {
        let all = ChallengeStore.shared.all
        XCTAssertEqual(Rounds.catalog(round: 1, all: all), Array(1...30))
        XCTAssertEqual(Rounds.catalog(round: 2, all: all), Array(31...60))
        XCTAssertEqual(Rounds.catalog(round: 3, all: all), Array(1...30))
        XCTAssertTrue(Rounds.isAllNew(2))
        XCTAssertFalse(Rounds.isAllNew(1))
    }

    func testOnlyLaterRoundsStartShuffled() {
        let all = ChallengeStore.shared.all
        var rng = SystemRandomNumberGenerator()
        XCTAssertEqual(Rounds.startingOrder(round: 1, all: all, using: &rng), Array(1...30))
        XCTAssertEqual(Rounds.startingOrder(round: 2, all: all, using: &rng), Array(31...60))
        let third = Rounds.startingOrder(round: 3, all: all, using: &rng)
        XCTAssertEqual(Set(third), Set(1...30))
    }

    func testBalloonStageCapsAtGoal() {
        let many = (1...40).map { Completion(challengeID: $0, date: Date()) }
        XCTAssertEqual(BraveProgress.stage(many), BraveProgress.goal)
    }
}
