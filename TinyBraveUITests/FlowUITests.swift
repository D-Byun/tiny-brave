import XCTest

final class FlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-skipWelcome"]
        app.launch()
        resetIfNeeded()
    }

    private func shot(_ name: String) {
        try? app.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "/tmp/tb-\(name).png"))
    }

    private func pill(_ text: String) -> XCUIElement {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func openProgress() {
        app.buttons["Track"].tap()
        XCTAssertTrue(app.navigationBars["Track"].waitForExistence(timeout: 5), "Track did not open")
    }

    private func closeScreen() {
        app.navigationBars.buttons.firstMatch.tap()
    }

    /// The Home header count; it steps toward the real count, so callers should wait on it.
    private func meter(_ count: Int) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Brave-o-Meter, \(count) of 30 tiny braves")).firstMatch
    }

    private func resetProgress() {
        app.buttons["Reset progress"].tap()
        app.buttons["Reset"].tap()
    }

    /// Always resets through Track so earlier tests' completions never leak between tests.
    private func resetIfNeeded() {
        openProgress()
        resetProgress()
        closeScreen()
        XCTAssertTrue(meter(0).waitForExistence(timeout: 5))
    }

    /// Completes the task Home is showing and comes back to Home.
    private func completeOne() {
        let done = app.buttons["yep. did brave thing."]
        XCTAssertTrue(done.waitForExistence(timeout: 5), "Home has no task to complete")
        done.tap()
        XCTAssertTrue(app.buttons["Next brave"].waitForExistence(timeout: 5), "Reward screen did not appear")
        app.buttons["Next brave"].tap()
        XCTAssertTrue(app.staticTexts["tiny brave"].waitForExistence(timeout: 5))
    }

    private var taskText: XCUIElement { app.staticTexts["challengeText"] }

    private func balloon(stage: Int) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Yellow balloon, stage \(stage) of 30")).firstMatch
    }

    func testCompleteChallengeFlowUpdatesCount() {
        shot("1-home")
        app.buttons["yep. did brave thing."].tap()
        XCTAssertTrue(app.buttons["Next brave"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1.5)
        shot("4-reward")
        app.buttons["Next brave"].tap()
        XCTAssertTrue(meter(1).waitForExistence(timeout: 8))
        shot("5-home-after")
    }

    func testHomeOffersOneTaskInListOrder() {
        XCTAssertFalse(pill("Warm-up").exists, "The level menu should be gone")
        XCTAssertFalse(pill("Surprise me").exists)
        XCTAssertEqual(taskText.label, "Give someone a specific compliment.")
        XCTAssertEqual(app.staticTexts["dayRound"].label, "DAY 1 · ROUND 1")
        completeOne()
        XCTAssertEqual(taskText.label, "Ask one question in class.")
        XCTAssertEqual(app.staticTexts["dayRound"].label, "DAY 2 · ROUND 1")
    }

    func testHomeHasNoExtrasBeyondTheMock() {
        for label in ["Settings", "All 30 braves", "Next day"] {
            XCTAssertFalse(app.buttons[label].exists, "\(label) should be gone")
        }
        XCTAssertFalse(app.staticTexts["greeting"].exists)
        XCTAssertFalse(app.staticTexts["Do it out in the world. Then come back."].exists)
    }

    func testSkippedTaskGoesToTheEndAndStaysSkippedAfterRelaunch() {
        app.buttons["not this brave. give other."].tap()
        expectation(for: NSPredicate(format: "label == %@", "Ask one question in class."), evaluatedWith: taskText)
        waitForExpectations(timeout: 5)
        XCTAssertEqual(app.staticTexts["dayRound"].label, "DAY 1 · ROUND 1")

        app.terminate()
        app.launch()
        XCTAssertTrue(taskText.waitForExistence(timeout: 5))
        XCTAssertEqual(taskText.label, "Ask one question in class.")
    }

    func testHomeNoLongerShowsStreakOrDailyGoal() {
        XCTAssertFalse(app.staticTexts["streak"].exists)
        completeOne()
        XCTAssertFalse(app.staticTexts["streak"].exists)
        XCTAssertFalse(pill("1 of 1").exists)
        XCTAssertFalse(app.staticTexts["Start a streak today"].exists)
    }

    func testMultipleCompletionsAndReset() {
        completeOne()
        completeOne()
        completeOne()
        XCTAssertTrue(meter(3).waitForExistence(timeout: 8))
        shot("8-home-three")

        openProgress()
        shot("7-progress-three")
        XCTAssertFalse(app.staticTexts["BRAVERY MUSCLES"].exists)
        XCTAssertFalse(app.staticTexts["BRAVE DEBRIS"].exists)
        XCTAssertFalse(app.staticTexts["CERTIFICATES"].exists)
        resetProgress()
        XCTAssertTrue(app.staticTexts["0 of 30"].waitForExistence(timeout: 5), "Reset did not clear progress")
        closeScreen()
        XCTAssertTrue(meter(0).waitForExistence(timeout: 8))
        XCTAssertEqual(taskText.label, "Give someone a specific compliment.", "Reset should restore the original task order")
    }

    func testExtraChallengesSameDayAddPuffsButNotStreak() {
        completeOne()
        completeOne()
        XCTAssertTrue(balloon(stage: 2).waitForExistence(timeout: 8), "Each task should add a puff")
        XCTAssertTrue(meter(2).waitForExistence(timeout: 8))
        openProgress()
        XCTAssertEqual(app.staticTexts["streak"].label, "🔥 1 day streak")
    }

    func testWelcomeScreenOpensHome() {
        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.staticTexts["welcomeHeadline"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Track"].isHittable)
        app.buttons["open carefully"].tap()
        XCTAssertTrue(app.buttons["Track"].waitForExistence(timeout: 5))
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.staticTexts["welcomeHeadline"])
        waitForExpectations(timeout: 5)
    }
}
