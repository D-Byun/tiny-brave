import XCTest
@testable import TinyBrave

final class BalloonSceneTests: XCTestCase {
    func testStagesFollowPuffCount() {
        XCTAssertEqual(BalloonScene.stage(puffs: 0), .grounded)
        XCTAssertEqual(BalloonScene.stage(puffs: 1), .sway)
        XCTAssertEqual(BalloonScene.stage(puffs: 8), .sway)
        XCTAssertEqual(BalloonScene.stage(puffs: 9), .lift)
        XCTAssertEqual(BalloonScene.stage(puffs: 18), .lift)
        XCTAssertEqual(BalloonScene.stage(puffs: 19), .dance)
        XCTAssertEqual(BalloonScene.stage(puffs: 25), .dance)
        XCTAssertEqual(BalloonScene.stage(puffs: 26), .zip)
        XCTAssertEqual(BalloonScene.stage(puffs: 29), .zip)
        XCTAssertEqual(BalloonScene.stage(puffs: 30), .final)
    }

    func testPuffCountIsClamped() {
        XCTAssertEqual(BalloonScene.stage(puffs: -3), .grounded)
        XCTAssertEqual(BalloonScene.stage(puffs: 99), .final)
    }

    func testLiftRisesWithEveryPuff() {
        XCTAssertEqual(BalloonScene.motion(puffs: 0).lift, 0)
        XCTAssertEqual(BalloonScene.motion(puffs: 30).lift, 1, accuracy: 0.0001)
        for puffs in 1...30 {
            XCTAssertGreaterThan(BalloonScene.motion(puffs: puffs).lift, BalloonScene.motion(puffs: puffs - 1).lift)
        }
    }

    func testFullBalloonStopsDrifting() {
        XCTAssertEqual(BalloonScene.motion(puffs: 30).drift, 0)
        XCTAssertNotEqual(BalloonScene.motion(puffs: 29).drift, 0)
    }
}
