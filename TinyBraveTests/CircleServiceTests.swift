import XCTest
@testable import TinyBrave

@MainActor
final class CircleServiceTests: XCTestCase {
    private var suites: [String] = []

    override func tearDown() {
        for name in suites { UserDefaults(suiteName: name)?.removePersistentDomain(forName: name) }
        suites = []
    }

    private func freshDefaults(_ name: String) throws -> UserDefaults {
        let full = "CircleServiceTests.\(name)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: full))
        defaults.removePersistentDomain(forName: full)
        suites.append(full)
        return defaults
    }

    /// Two phones: separate caches and identities, one shared backend.
    private func twoPhones() throws -> (alice: CircleService, bob: CircleService, backend: LocalCircleBackend) {
        let backend = LocalCircleBackend(defaults: try freshDefaults("shared"))
        let alice = CircleService(defaults: try freshDefaults("alice"), backend: backend, userID: "alice")
        let bob = CircleService(defaults: try freshDefaults("bob"), backend: backend, userID: "bob")
        alice.setNickname("Alice")
        bob.setNickname("Bob")
        return (alice, bob, backend)
    }

    func testNormalizeNeedsSixLetters() {
        XCTAssertEqual(CircleService.normalize("ab-cd ef"), "ABCDEF")
        XCTAssertNil(CircleService.normalize("abcde"))
        XCTAssertNil(CircleService.normalize("abcdefg"))
    }

    func testNicknamesAreShortAndPlain() {
        XCTAssertEqual(CircleService.cleanNickname("  Sam<3!  "), "Sam3")
        XCTAssertEqual(CircleService.cleanNickname("abcdefghijklmnop"), "abcdefghijkl")
        XCTAssertEqual(CircleService.cleanNickname("   "), "friend")
    }

    func testCreateMakesACodeWithYouAsTheOnlyMember() async throws {
        let defaults = try freshDefaults("create")
        let service = CircleService(defaults: defaults)
        try await service.create(count: 4, streak: 2)
        let state = try XCTUnwrap(service.state)
        XCTAssertEqual(CircleService.normalize(state.code), state.code)
        XCTAssertEqual(service.memberCount, 1)
        XCTAssertEqual(state.members.first?.count, 4)
        XCTAssertEqual(state.members.first?.id, service.userID)
        XCTAssertEqual(CircleService(defaults: defaults).state, state, "It survives a relaunch")
    }

    func testIdentityIsStableAcrossRelaunches() throws {
        let defaults = try freshDefaults("identity")
        let first = CircleService(defaults: defaults)
        first.setNickname("Pip")
        let second = CircleService(defaults: defaults)
        XCTAssertEqual(second.userID, first.userID)
        XCTAssertEqual(second.nickname, "Pip")
    }

    func testJoinFindsACircleMadeOnAnotherPhone() async throws {
        let (alice, bob, _) = try twoPhones()
        try await alice.create(count: 3, streak: 1)
        let code = try XCTUnwrap(alice.state?.code)
        try await bob.join(code: code.lowercased(), count: 5, streak: 2)
        XCTAssertEqual(bob.memberCount, 2)
        XCTAssertEqual(bob.state?.members.first?.name, "Bob", "You come first")
        XCTAssertEqual(bob.state?.members.last?.name, "Alice")
        XCTAssertEqual(bob.state?.members.last?.isYou, false)

        await alice.refresh()
        XCTAssertEqual(alice.memberCount, 2)
    }

    func testJoinRejectsBadMissingAndFullCircles() async throws {
        let (alice, bob, backend) = try twoPhones()
        do {
            try await bob.join(code: "abc", count: 0, streak: 0)
            XCTFail("A short code should be rejected")
        } catch { XCTAssertEqual(error as? CircleError, .invalidCode) }
        do {
            try await bob.join(code: "ZZZZZZ", count: 0, streak: 0)
            XCTFail("An unknown code should be rejected")
        } catch { XCTAssertEqual(error as? CircleError, .notFound) }

        try await alice.create(count: 0, streak: 0)
        let code = try XCTUnwrap(alice.state?.code)
        for i in 1..<CircleLimits.maxMembers {
            _ = try await backend.join(code: code, me: CircleMember(id: "p\(i)", name: "p\(i)", count: 0, streak: 0, isYou: false))
        }
        do {
            try await bob.join(code: code, count: 0, streak: 0)
            XCTFail("A full circle should be rejected")
        } catch { XCTAssertEqual(error as? CircleError, .full) }
    }

    func testFriendsSeeEachOthersProgress() async throws {
        let (alice, bob, _) = try twoPhones()
        try await alice.create(count: 0, streak: 0)
        try await bob.join(code: try XCTUnwrap(alice.state?.code), count: 0, streak: 0)
        alice.updateYou(count: 7, streak: 3)
        try await Task.sleep(for: .milliseconds(100))
        await bob.refresh()
        let seen = try XCTUnwrap(bob.state?.members.first { $0.name == "Alice" })
        XCTAssertEqual(seen.count, 7)
        XCTAssertEqual(seen.streak, 3)
    }

    func testPingsReachFriendsButNotTheSender() async throws {
        let (alice, bob, _) = try twoPhones()
        try await alice.create(count: 0, streak: 0)
        try await bob.join(code: try XCTUnwrap(alice.state?.code), count: 0, streak: 0)
        XCTAssertNil(bob.banner, "Joining doesn't announce old news")

        await alice.sendPing(.tinyTask)
        await alice.refresh()
        XCTAssertEqual(alice.state?.pings, [], "You don't get your own ping")
        XCTAssertNil(alice.banner)

        await bob.refresh()
        XCTAssertEqual(bob.banner?.name, "Alice")
        XCTAssertEqual(bob.banner?.message, PingMessage.tinyTask.text)
        XCTAssertEqual(bob.state?.pings.count, 1)

        bob.banner = nil
        await bob.refresh()
        XCTAssertNil(bob.banner, "The same ping isn't announced twice")
    }

    func testPingsKeepTheLatestSixAndShowABanner() async throws {
        let service = CircleService(defaults: try freshDefaults("pings"))
        try await service.create(count: 0, streak: 0)
        for i in 0..<8 { service.receive(CirclePing(name: "friend", message: "ping \(i)")) }
        XCTAssertEqual(service.state?.pings.count, 6)
        XCTAssertEqual(service.state?.pings.first?.message, "ping 7")
        XCTAssertEqual(service.banner?.message, "ping 7")
    }

    func testRenamingUpdatesYourRowForFriends() async throws {
        let (alice, bob, _) = try twoPhones()
        try await alice.create(count: 0, streak: 0)
        try await bob.join(code: try XCTUnwrap(alice.state?.code), count: 0, streak: 0)
        alice.setNickname("Ally")
        try await Task.sleep(for: .milliseconds(100))
        await bob.refresh()
        XCTAssertTrue(bob.state?.members.contains { $0.name == "Ally" } ?? false)
    }

    func testLeaveClearsTheCircleEverywhere() async throws {
        let (alice, bob, _) = try twoPhones()
        try await alice.create(count: 0, streak: 0)
        let code = try XCTUnwrap(alice.state?.code)
        try await bob.join(code: code, count: 0, streak: 0)
        bob.leave()
        XCTAssertNil(bob.state)
        try await Task.sleep(for: .milliseconds(100))
        await alice.refresh()
        XCTAssertEqual(alice.memberCount, 1)

        alice.leave()
        try await Task.sleep(for: .milliseconds(100))
        do {
            try await bob.join(code: code, count: 0, streak: 0)
            XCTFail("An empty circle is gone")
        } catch { XCTAssertEqual(error as? CircleError, .notFound) }
    }

    func testPingMessagesFollowTheStages() {
        XCTAssertEqual(PingMessage.forStage(1, goal: 30), .tinyTask)
        XCTAssertEqual(PingMessage.forStage(5, goal: 30), .lookAtYou)
        XCTAssertEqual(PingMessage.forStage(30, goal: 30), .allThirty)
    }
}
