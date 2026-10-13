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
        pill("Brave-o-Meter").tap()
        XCTAssertTrue(app.navigationBars["Brave-o-Meter"].waitForExistence(timeout: 5), "Progress did not open")
    }

    /// Always resets through Settings so earlier days' completions and the simulated-day offset never leak between tests.
    private func resetIfNeeded() {
        app.buttons["Settings"].tap()
        app.buttons["Reset all data"].tap()
        app.buttons["Reset everything"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(pill("0 of 1").waitForExistence(timeout: 5))
    }

    private func completeOne(level: String) {
        let card = pill(level)
        XCTAssertTrue(card.waitForExistence(timeout: 5), "\(level) card missing")
        card.tap()
        let done = app.buttons["I did the brave thing"]
        XCTAssertTrue(done.waitForExistence(timeout: 5), "Challenge screen did not appear")
        done.tap()
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: 5), "Reward screen did not appear")
        app.buttons["Done"].tap()
        XCTAssertTrue(app.staticTexts["tiny brave"].waitForExistence(timeout: 5))
    }

    func testCompleteChallengeFlowUpdatesCount() {
        shot("1-home")
        pill("Pebble").tap()
        shot("2-challenge")
        app.buttons["I did the brave thing"].tap()
        XCTAssertTrue(app.buttons["Another one"].waitForExistence(timeout: 5))
        Thread.sleep(forTimeInterval: 1.5)
        shot("4-reward")
        app.buttons["Done"].tap()
        XCTAssertTrue(pill("1 of 1").waitForExistence(timeout: 5))
        shot("5-home-after")
    }

    func testSwapChangesChallenge() {
        pill("Hill").tap()
        let text = app.staticTexts["challengeText"]
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        let before = text.label
        app.buttons["Not this one"].tap()
        expectation(for: NSPredicate(format: "label != %@", before), evaluatedWith: text)
        waitForExpectations(timeout: 5)
    }

    func testMultipleCompletionsAndReset() {
        completeOne(level: "Pebble")
        completeOne(level: "Hill")
        completeOne(level: "Mountain")
        XCTAssertTrue(pill("1 of 1").exists)
        shot("8-home-three")

        openProgress()
        shot("7-progress-three")
        app.buttons["Reset progress"].tap()
        app.buttons["Reset"].tap()
        XCTAssertTrue(app.staticTexts["0 of 10"].waitForExistence(timeout: 5), "Reset did not clear progress")
    }

    func testLibraryFiltersAndReplay() {
        app.buttons["Library"].tap()
        XCTAssertTrue(app.navigationBars["Library"].waitForExistence(timeout: 5), "Library did not open")
        app.buttons["Repair"].swipeLeft()
        app.buttons["Protect"].tap()
        let trusted = app.buttons.matching(NSPredicate(format: "label CONTAINS 'trusted person'")).firstMatch
        XCTAssertTrue(trusted.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label CONTAINS 'Disagree politely'")).firstMatch.exists)
        shot("6-library-protect")

        trusted.tap()
        XCTAssertTrue(app.buttons["I did the brave thing"].waitForExistence(timeout: 5), "Library row did not open the challenge")
    }

    func testExtraChallengesSameDayDoNotChangeBalloonOrStreak() {
        completeOne(level: "Pebble")
        completeOne(level: "Hill")
        XCTAssertTrue(pill("1 of 1").exists)
        XCTAssertEqual(app.staticTexts["streak"].label, "🔥 1 day streak")
        XCTAssertTrue(pill("Mountain").isEnabled)
    }

    private func balloon(stage: Int) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Yellow balloon, stage \(stage) of 10")).firstMatch
    }

    private func nextDay() {
        app.buttons["Next day"].tap()
    }

    func testNextDayAdvancesStreakAndBalloonAndGapResetsStreak() {
        completeOne(level: "Pebble")
        XCTAssertTrue(pill("1 of 1").exists)
        nextDay()
        XCTAssertEqual(app.staticTexts["streak"].label, "🔥 1 day streak")
        completeOne(level: "Pebble")
        XCTAssertTrue(pill("1 of 1").waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["streak"].label, "🔥 2 day streak")
        XCTAssertTrue(balloon(stage: 2).waitForExistence(timeout: 5))

        nextDay()
        nextDay()
        XCTAssertEqual(app.staticTexts["streak"].label, "Start a streak today")
        XCTAssertTrue(balloon(stage: 0).waitForExistence(timeout: 8), "Broken streak should deflate the balloon")
        completeOne(level: "Hill")
        XCTAssertTrue(pill("1 of 1").waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["streak"].label, "🔥 1 day streak")
        XCTAssertTrue(balloon(stage: 1).waitForExistence(timeout: 8))

        app.buttons["Settings"].tap()
        app.buttons["Reset all data"].tap()
        app.buttons["Reset everything"].tap()
    }

    func testBalloonWearsCrownOnDayTen() {
        for day in 1...10 {
            completeOne(level: "Pebble")
            if day < 10 { nextDay() }
        }
        let crowned = app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Yellow balloon, stage 10 of 10, wearing a crown")).firstMatch
        XCTAssertTrue(crowned.waitForExistence(timeout: 10))
        XCTAssertFalse(balloon(stage: 9).exists)
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
        XCTAssertTrue(app.staticTexts["Pick today's tiny thing, Sam."].waitForExistence(timeout: 5))
        app.buttons["Settings"].tap()
        app.buttons["Sunny theme"].tap()
    }

    func testResetAllDataClearsProgressNameAndTheme() {
        completeOne(level: "Pebble")
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
        XCTAssertTrue(pill("0 of 1").waitForExistence(timeout: 5))
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
