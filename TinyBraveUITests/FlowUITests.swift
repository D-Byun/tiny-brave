import XCTest

final class FlowUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-skipWelcome", "-round", "1", "-localCircles", "-resetArchive"]
        app.launch()
        resetIfNeeded()
    }

    private func shot(_ name: String) {
        try? app.screenshot().pngRepresentation.write(to: URL(fileURLWithPath: "/tmp/tb-\(name).png"))
    }

    private func el(_ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(identifier: id).firstMatch
    }

    private func openTrack() {
        app.buttons["Track"].tap()
        XCTAssertTrue(el("statCompleted").waitForExistence(timeout: 5), "Track did not open")
    }

    private func closeSheet() {
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Track"].waitForExistence(timeout: 5))
    }

    /// The Home count; callers should wait on it.
    private func meter(_ count: Int) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "Brave-o-Meter, \(count) of 30 tiny braves")).firstMatch
    }

    private func resetProgress() {
        el("resetProgress").tap()
        XCTAssertTrue(el("confirmReset").waitForExistence(timeout: 5))
        el("confirmReset").tap()
    }

    /// Always resets through Track so earlier tests' completions never leak between tests.
    /// Resetting closes the Track sheet and returns to Home.
    private func resetIfNeeded() {
        openTrack()
        resetProgress()
        XCTAssertTrue(meter(0).waitForExistence(timeout: 8))
        XCTAssertTrue(app.buttons["Track"].waitForExistence(timeout: 5))
    }

    /// Completes the task Home is showing, then moves to the next one.
    private func completeOne() {
        let done = app.buttons["yep. did brave thing."]
        XCTAssertTrue(done.waitForExistence(timeout: 5), "Home has no task to complete")
        done.tap()
        XCTAssertTrue(el("nextBrave").waitForExistence(timeout: 5), "The reward did not appear")
        el("nextBrave").tap()
        XCTAssertTrue(app.buttons["yep. did brave thing."].waitForExistence(timeout: 5))
    }

    private var taskText: XCUIElement { el("challengeText") }

    private func balloon(stage: Int) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Yellow balloon, stage \(stage) of 30")).firstMatch
    }

    func testCompleteChallengeShowsRewardInPlaceAndUpdatesCount() {
        shot("1-home")
        app.buttons["yep. did brave thing."].tap()
        XCTAssertTrue(el("rewardMessage").waitForExistence(timeout: 5))
        XCTAssertTrue(el("tabDraw").exists)
        XCTAssertTrue(el("tabAudio").exists)
        XCTAssertTrue(app.buttons["Track"].exists, "The reward stays on Home")
        Thread.sleep(forTimeInterval: 1)
        shot("2-reward")
        el("nextBrave").tap()
        XCTAssertTrue(meter(1).waitForExistence(timeout: 8))
        shot("3-home-after")
    }

    func testHomeOffersOneTaskInListOrder() {
        XCTAssertEqual(taskText.label, "Give someone a specific compliment.")
        XCTAssertEqual(el("dayRound").label, "DAY 1 · ROUND 1")
        completeOne()
        XCTAssertEqual(taskText.label, "Ask one question in class.")
        XCTAssertEqual(el("dayRound").label, "DAY 2 · ROUND 1")
    }

    func testSkippedTaskGoesToTheEndAndStaysSkippedAfterRelaunch() {
        app.buttons["not this brave. give other."].tap()
        expectation(for: NSPredicate(format: "label == %@", "Ask one question in class."), evaluatedWith: taskText)
        waitForExpectations(timeout: 5)
        XCTAssertEqual(el("dayRound").label, "DAY 1 · ROUND 1")

        app.terminate()
        app.launch()
        XCTAssertTrue(taskText.waitForExistence(timeout: 5))
        XCTAssertEqual(taskText.label, "Ask one question in class.")
    }

    func testDrawingIsKeptAndShowsUpInTheTrackArchive() {
        app.buttons["yep. did brave thing."].tap()
        XCTAssertTrue(el("tabDraw").waitForExistence(timeout: 5))
        let canvas = el("drawingCanvas")
        XCTAssertTrue(canvas.waitForExistence(timeout: 5))
        let from = canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.3))
        from.press(forDuration: 0.1, thenDragTo: canvas.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.6)))
        let saved = XCTNSPredicateExpectation(predicate: NSPredicate(format: "label == %@", "drawing saved to Track."), object: el("saveStatus"))
        XCTAssertEqual(XCTWaiter().wait(for: [saved], timeout: 5), .completed, "The drawing should be kept as soon as the pen pauses")
        el("nextBrave").tap()
        XCTAssertTrue(meter(1).waitForExistence(timeout: 10))

        openTrack()
        XCTAssertFalse(el("archiveEmpty").exists)
        XCTAssertTrue(app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", "Drawing, R1")).firstMatch.exists)
        shot("4-track")
    }

    func testTrackSheetShowsStatsAndKeepsResponsesAfterReset() {
        completeOne()
        completeOne()
        XCTAssertTrue(meter(2).waitForExistence(timeout: 8))
        openTrack()
        XCTAssertEqual(el("statCompleted").label, "2, completed")
        XCTAssertEqual(el("statStreak").label, "1, day streak")
        XCTAssertTrue(el("archiveEmpty").exists)
        XCTAssertTrue(el("playReel").exists)
        resetProgress()
        XCTAssertTrue(meter(0).waitForExistence(timeout: 8), "Reset should close Track and empty the balloon")
        XCTAssertEqual(taskText.label, "Give someone a specific compliment.", "Reset should restore the original task order")
    }

    func testEachTaskAddsAPuff() {
        completeOne()
        completeOne()
        XCTAssertTrue(balloon(stage: 2).waitForExistence(timeout: 8))
        XCTAssertTrue(meter(2).waitForExistence(timeout: 8))
        XCTAssertEqual(el("puffCaption").label, "Puff 2: slightly less floppy.")
    }

    func testReelPlaysWithNoReceiptsYet() {
        openTrack()
        el("playReel").tap()
        XCTAssertTrue(el("reelCaption").waitForExistence(timeout: 5))
        XCTAssertEqual(el("reelCaption").label, "the archive is empty, but the balloon remembers.")
        XCTAssertTrue(app.staticTexts["no receipts. still brave."].exists)
        el("closeReel").tap()
        XCTAssertTrue(el("statCompleted").waitForExistence(timeout: 5))
    }

    func testCircleCanBeCreatedLocally() {
        app.buttons["Circle"].tap()
        if el("createCircle").waitForExistence(timeout: 5) { el("createCircle").tap() }
        XCTAssertTrue(el("circleCode").waitForExistence(timeout: 5))
        XCTAssertEqual(el("circleCode").label.filter(\.isLetter).count, 6)
        shot("5-circle")
        app.buttons["Close"].tap()
        XCTAssertTrue(app.buttons["Track"].waitForExistence(timeout: 5))
    }

    func testWelcomeScreenOpensHome() {
        app.terminate()
        app.launchArguments = ["-round", "1", "-localCircles", "-resetArchive"]
        app.launch()
        XCTAssertTrue(el("welcomeHeadline").waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["Track"].isHittable)
        app.buttons["open carefully"].tap()
        XCTAssertTrue(app.buttons["Track"].waitForExistence(timeout: 5))
        expectation(for: NSPredicate(format: "exists == false"), evaluatedWith: el("welcomeHeadline"))
        waitForExpectations(timeout: 5)
    }
}
