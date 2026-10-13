import XCTest
@testable import TinyBrave

final class ChallengeStoreTests: XCTestCase {
    func testThirtyChallengesAcrossFourCategories() {
        let all = ChallengeStore.shared.all
        XCTAssertEqual(all.count, 30)
        XCTAssertEqual(BraveCategory.allCases.count, 4)
        let counts = Dictionary(grouping: all, by: \.category).mapValues(\.count)
        XCTAssertEqual(counts, [.connect: 8, .speak: 8, .try: 7, .reset: 7])
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

    func testPickPrefersUncompleted() {
        let store = ChallengeStore.shared
        let pebbles = store.all.filter { $0.level == .tinyStretch }.map(\.id)
        let doneExceptOne = Set(pebbles.dropFirst())
        let picked = store.pick(level: .tinyStretch, completed: doneExceptOne)
        XCTAssertEqual(picked?.id, pebbles.first)
    }

    func testPickExcludesCurrentAndFallsBackToReplay() {
        let store = ChallengeStore.shared
        let all = Set(store.all.map(\.id))
        let picked = store.pick(level: .mediumBrave, excluding: 6, completed: all)
        XCTAssertNotNil(picked)
        XCTAssertNotEqual(picked?.id, 6)
        XCTAssertEqual(picked?.level, .mediumBrave)
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
        Completion(challengeID: 1, debrisKey: "star", date: Calendar.current.date(byAdding: .day, value: -daysAgo, to: now)!)
    }

    func testExtraCompletionsSameDayDoNotAddDaysOrStreak() {
        let now = Date()
        let completions = [completion(daysAgo: 0, from: now), completion(daysAgo: 0, from: now), completion(daysAgo: 0, from: now)]
        XCTAssertEqual(DailyGoal.completedToday(completions, now: now), 3)
        XCTAssertTrue(DailyGoal.isDoneToday(completions, now: now))
        XCTAssertEqual(DailyGoal.activeDays(completions), 1)
        XCTAssertEqual(DailyGoal.streak(completions, now: now), 1)
    }

    func testStreakCountsConsecutiveDaysAndBreaksOnGap() {
        let now = Date()
        let run = [0, 1, 2].map { completion(daysAgo: $0, from: now) }
        XCTAssertEqual(DailyGoal.streak(run, now: now), 3)
        let gap = [0, 1, 3].map { completion(daysAgo: $0, from: now) }
        XCTAssertEqual(DailyGoal.streak(gap, now: now), 2)
        XCTAssertEqual(DailyGoal.activeDays(gap), 3)
    }

    func testStreakSurvivesUntilEndOfDayThenResets() {
        let now = Date()
        let yesterdayOnly = [completion(daysAgo: 1, from: now)]
        XCTAssertFalse(DailyGoal.isDoneToday(yesterdayOnly, now: now))
        XCTAssertEqual(DailyGoal.streak(yesterdayOnly, now: now), 1)
        let twoDaysLater = Calendar.current.date(byAdding: .day, value: 1, to: now)!
        XCTAssertEqual(DailyGoal.streak(yesterdayOnly, now: twoDaysLater), 0)
        XCTAssertEqual(DailyGoal.streak([], now: now), 0)
    }

    func testUsernameIsTrimmedAndCapped() {
        XCTAssertEqual(Username.clean("  Sam \n"), "Sam")
        XCTAssertEqual(Username.clean(String(repeating: "a", count: 50)).count, Username.maxLength)
    }

    func testGreetingByTimeOfDay() {
        func date(_ hour: Int) -> Date {
            Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date())!
        }
        XCTAssertEqual(Greeting.text(name: "Sam", now: date(8)), "Good morning, Sam")
        XCTAssertEqual(Greeting.text(name: "Sam", now: date(13)), "Good afternoon, Sam")
        XCTAssertEqual(Greeting.text(name: "Sam", now: date(20)), "Good evening, Sam")
        XCTAssertEqual(Greeting.text(name: "Sam", now: date(2)), "Good evening, Sam")
        XCTAssertEqual(Greeting.text(name: "  ", now: date(8)), "Good morning")
    }

    func testBalloonHasThirtyStagesAndCapsAtGoal() {
        XCTAssertEqual(BraveProgress.goal, 30)
        XCTAssertEqual(BraveProgress.inflation(completed: 0), 0)
        XCTAssertEqual(BraveProgress.inflation(completed: 15), 0.5)
        XCTAssertEqual(BraveProgress.inflation(completed: 30), 1)
        XCTAssertEqual(BraveProgress.inflation(completed: 45), 1)
        XCTAssertTrue(Certificate.all.allSatisfy { $0.count <= BraveProgress.goal })
    }

    func testEveryDistinctTaskIsAPuffEvenOnTheSameDay() {
        let now = Date()
        let sameDay = [1, 2, 3].map { Completion(challengeID: $0, debrisKey: "star", date: now) }
        XCTAssertEqual(BraveProgress.stage(sameDay), 3)
        XCTAssertEqual(BraveProgress.stage([]), 0)
    }

    func testReplayingATaskDoesNotAddAPuff() {
        let now = Date()
        let replays = [1, 1, 2].map { Completion(challengeID: $0, debrisKey: "star", date: now) }
        XCTAssertEqual(BraveProgress.stage(replays), 2)
    }

    func testBalloonNeverDeflatesWhenDaysAreMissed() {
        let now = Date()
        let cal = Calendar.current
        let old = (1...4).map { Completion(challengeID: $0, debrisKey: "star", date: cal.date(byAdding: .day, value: -($0 + 10), to: now)!) }
        XCTAssertEqual(BraveProgress.stage(old), 4)
        XCTAssertEqual(DailyGoal.streak(old, now: now), 0, "The streak still breaks")
    }

    func testBalloonStageCapsAtGoal() {
        let many = (1...40).map { Completion(challengeID: $0, debrisKey: "star", date: Date()) }
        XCTAssertEqual(BraveProgress.stage(many), BraveProgress.goal)
    }
}
