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
        XCTAssertTrue(app.navigationBars["Brave-o-Meter"].waitForExistence(timeout: 5), "Progress did not open")
    }

    private func closeScreen() {
        app.navigationBars.buttons.firstMatch.tap()
    }

    /// The Home header count; it steps toward the real count, so callers should wait on it.
    private func meter(_ count: Int) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Brave-o-Meter, \(count) of 30 tiny braves")).firstMatch
    }

    /// Always resets through Settings so earlier days' completions and the simulated-day offset never leak between tests.
    private func resetIfNeeded() {
        app.buttons["Settings"].tap()
        app.buttons["Reset all data"].tap()
        app.buttons["Reset everything"].tap()
        app.navigationBars.buttons.firstMatch.tap()
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
        app.buttons["Reset progress"].tap()
        app.buttons["Reset"].tap()
        XCTAssertTrue(app.staticTexts["0 of 30"].waitForExistence(timeout: 5), "Reset did not clear progress")
    }

    func testLibraryFiltersAndReplay() {
        app.buttons["All 30 braves"].tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5), "Library did not open")
        app.buttons["Reset"].tap()
        let trusted = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Write down one thing'")).firstMatch
        XCTAssertTrue(trusted.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Ask one question in class'")).firstMatch.exists)
        shot("6-library-reset")

        trusted.tap()
        XCTAssertTrue(app.buttons["yep. did brave thing."].waitForExistence(timeout: 5), "Library row did not open the challenge")
    }

    func testExtraChallengesSameDayAddPuffsButNotStreak() {
        completeOne()
        completeOne()
        XCTAssertTrue(balloon(stage: 2).waitForExistence(timeout: 8), "Each task should add a puff")
        XCTAssertTrue(meter(2).waitForExistence(timeout: 8))
        openProgress()
        XCTAssertEqual(app.staticTexts["streak"].label, "🔥 1 day streak")
    }

    private func balloon(stage: Int) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Yellow balloon, stage \(stage) of 30")).firstMatch
    }

    private func nextDay() {
        app.buttons["Next day"].tap()
    }

    func testNextDayAdvancesStreakAndGapHidesStreakButNeverDeflatesBalloon() {
        completeOne()
        nextDay()
        completeOne()
        XCTAssertTrue(meter(2).waitForExistence(timeout: 8))
        openProgress()
        XCTAssertEqual(app.staticTexts["streak"].label, "🔥 2 day streak")
        closeScreen()

        nextDay()
        nextDay()
        XCTAssertTrue(balloon(stage: 2).waitForExistence(timeout: 8), "A broken streak should not deflate the balloon")
        openProgress()
        XCTAssertFalse(app.staticTexts["streak"].exists, "A broken streak should simply not be shown")
        XCTAssertFalse(app.staticTexts["No streak yet. Do one today!"].exists)
        closeScreen()
        completeOne()
        XCTAssertTrue(balloon(stage: 3).waitForExistence(timeout: 8))
        openProgress()
        XCTAssertEqual(app.staticTexts["streak"].label, "🔥 1 day streak")
        closeScreen()

        app.buttons["Settings"].tap()
        app.buttons["Reset all data"].tap()
        app.buttons["Reset everything"].tap()
    }

    func testSettingsUsernameAndTheme() {
        app.buttons["Settings"].tap()
        let field = app.textFields["usernameField"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.tap()
        field.clearAndType("Sam")
        app.buttons["Dark theme"].tap()
        XCTAssertTrue(app.buttons["Dark theme"].isSelected)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["greeting"].label.hasSuffix(", Sam"))
        app.buttons["Settings"].tap()
        app.buttons["Sunny theme"].tap()
    }

    func testResetAllDataClearsProgressNameAndTheme() {
        completeOne()
        app.buttons["Settings"].tap()
        let field = app.textFields["usernameField"]
        field.tap()
        field.clearAndType("Sam")
        app.buttons["Ocean theme"].tap()
        app.buttons["Reset all data"].tap()
        app.buttons["Reset everything"].tap()
        XCTAssertTrue(app.buttons["Sunny theme"].waitForExistence(timeout: 5))
        expectation(for: NSPredicate(format: "isSelected == true"), evaluatedWith: app.buttons["Sunny theme"])
        waitForExpectations(timeout: 3)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(meter(0).waitForExistence(timeout: 8))
        XCTAssertEqual(taskText.label, "Give someone a specific compliment.", "Reset should restore the original task order")
        XCTAssertEqual(app.staticTexts["greeting"].label.contains(","), false)
    }

    func testThemeCanChangeFromAnyTheme() {
        app.buttons["Settings"].tap()
        for name in ["Dark", "Ocean", "Dark", "Forest", "Bubblegum", "Sunny", "Dark", "Sunny"] {
            let card = app.buttons["\(name) theme"]
            card.tap()
            expectation(for: NSPredicate(format: "isSelected == true"), evaluatedWith: card)
            waitForExpectations(timeout: 3)
        }
    }

    func testGreetingShowsUsername() {
        app.buttons["Settings"].tap()
        let field = app.textFields["usernameField"]
        field.tap()
        field.clearAndType("Sam")
        app.navigationBars.buttons.firstMatch.tap()
        let greeting = app.staticTexts["greeting"]
        XCTAssertTrue(greeting.waitForExistence(timeout: 5))
        XCTAssertTrue(greeting.label.hasPrefix("Good "))
        XCTAssertTrue(greeting.label.hasSuffix(", Sam"))
    }

    func testWelcomeScreenOpensHome() {
        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.staticTexts["welcomeHeadline"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Settings"].isHittable)
        app.buttons["open carefully"].tap()
        XCTAssertTrue(app.buttons["Settings"].waitForExistence(timeout: 5))
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: app.staticTexts["welcomeHeadline"])
        waitForExpectations(timeout: 5)
    }
}

private extension XCUIElement {
    func clearAndType(_ text: String) {
        if let current = value as? String, !current.isEmpty {
            typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        }
        typeText(text)
    }
}
