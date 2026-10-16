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

    func testGlideStartsAndEndsAtRest() {
        for scene in [BalloonScene.sway, .lift, .dance, .zip] {
            XCTAssertEqual(scene.glideOffset(phase: 0), BalloonScene.Offset(x: 0, y: 0, tilt: 0))
            let end = scene.glideOffset(phase: 0.9999)
            XCTAssertEqual(end.x, 0, accuracy: 0.01)
            XCTAssertEqual(end.y, 0, accuracy: 0.01)
            let peak = scene.glideOffset(phase: 0.24)
            XCTAssertEqual(peak.x, scene.glide.right, accuracy: 0.0001)
        }
    }

    func testSkyDarkensAndSaturatesWithPuffs() {
        let empty = BalloonScene.sky(puffs: 0)
        let full = BalloonScene.sky(puffs: 30)
        XCTAssertEqual(empty.top.0, 184, accuracy: 0.001)
        XCTAssertEqual(full.top.0, 57, accuracy: 0.001)
        XCTAssertEqual(full.bottom.2, 238, accuracy: 0.001)
    }

    func testFullBalloonStopsDrifting() {
        XCTAssertEqual(BalloonScene.motion(puffs: 30).drift, 0)
        XCTAssertNotEqual(BalloonScene.motion(puffs: 29).drift, 0)
    }
}
