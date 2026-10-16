import XCTest
@testable import TinyBrave

@MainActor
final class CircleServiceTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUpWithError() throws {
        defaults = try XCTUnwrap(UserDefaults(suiteName: "CircleServiceTests"))
        defaults.removePersistentDomain(forName: "CircleServiceTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "CircleServiceTests")
    }

    func testNormalizeNeedsSixLetters() {
        XCTAssertEqual(CircleService.normalize("ab-cd ef"), "ABCDEF")
        XCTAssertNil(CircleService.normalize("abcde"))
        XCTAssertNil(CircleService.normalize("abcdefg"))
    }

    func testCreateMakesACodeWithYouAsTheOnlyMember() throws {
        let service = CircleService(defaults: defaults)
        service.create(count: 4, streak: 2)
        let state = try XCTUnwrap(service.state)
        XCTAssertEqual(CircleService.normalize(state.code), state.code)
        XCTAssertEqual(service.memberCount, 1)
        XCTAssertEqual(state.members.first?.count, 4)
        XCTAssertEqual(CircleService(defaults: defaults).state, state, "It survives a relaunch")
    }

    func testJoinOnlyWorksForTheKnownCode() throws {
        let service = CircleService(defaults: defaults)
        XCTAssertFalse(service.join(code: "ABCDEF"))
        service.create(count: 0, streak: 0)
        let code = try XCTUnwrap(service.state?.code)
        XCTAssertTrue(service.join(code: code.lowercased()))
        XCTAssertFalse(service.join(code: "ZZZZZZ"))
    }

    func testPingsKeepTheLatestSixAndShowABanner() {
        let service = CircleService(defaults: defaults)
        service.create(count: 0, streak: 0)
        for i in 0..<8 { service.receive(CirclePing(name: "friend", message: "ping \(i)")) }
        XCTAssertEqual(service.state?.pings.count, 6)
        XCTAssertEqual(service.state?.pings.first?.message, "ping 7")
        XCTAssertEqual(service.banner?.message, "ping 7")
    }

    func testLeaveClearsTheCircle() {
        let service = CircleService(defaults: defaults)
        service.create(count: 0, streak: 0)
        service.leave()
        XCTAssertNil(service.state)
        XCTAssertNil(CircleService(defaults: defaults).state)
    }
}
