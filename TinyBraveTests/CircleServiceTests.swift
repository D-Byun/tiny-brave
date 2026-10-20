import XCTest
@testable import TinyBrave

@MainActor
final class CircleServiceTests: XCTestCase {
    private var suites: [String] = []
    private var store = LocalCircleStore()

    override func setUp() {
        store = LocalCircleStore()
    }

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

    /// One phone on the shared pretend server, already past the age gate unless `band` says otherwise.
    private func phone(_ name: String, band: AgeBand? = .thirteenToFifteen) async throws -> CircleService {
        let service = CircleService(defaults: try freshDefaults(name), backend: LocalCircleBackend(store: store, userID: name))
        service.setNickname(name.capitalized)
        await service.start()
        if let band { try await service.setAge(band) }
        await settle()
        return service
    }

    private func friends(_ a: CircleService, _ b: CircleService) async throws {
        let outcome = try await b.addFriend(code: XCTUnwrap(a.code))
        XCTAssertEqual(outcome, .sent)
        let request = try XCTUnwrap(a.snapshot.requests.first)
        try await a.respond(to: request, accept: true)
    }

    /// Lets the fire-and-forget profile and device tasks run.
    private func settle() async {
        for _ in 0..<20 { await Task.yield() }
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

    func testAgeBandsErrYounger() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(identifier: "UTC"))
        let june2026 = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 15)))
        XCTAssertEqual(AgeBand(birthMonth: 5, year: 2013, now: june2026, calendar: calendar), .thirteenToFifteen)
        XCTAssertEqual(AgeBand(birthMonth: 6, year: 2013, now: june2026, calendar: calendar), .under13, "This month's birthday may not have happened yet")
        XCTAssertEqual(AgeBand(birthMonth: 1, year: 2010, now: june2026, calendar: calendar), .sixteenPlus)
        XCTAssertEqual(AgeBand(lowerBound: 13, upperBound: 15), .thirteenToFifteen)
        XCTAssertEqual(AgeBand(lowerBound: 16, upperBound: nil), .sixteenPlus)
        XCTAssertEqual(AgeBand(lowerBound: nil, upperBound: 12), .under13)
        XCTAssertNil(AgeBand(lowerBound: nil, upperBound: nil))
    }

    func testNoBackendMeansNoCircles() throws {
        XCTAssertEqual(CircleService(defaults: try freshDefaults("none"), backend: nil).access, .unavailable)
    }

    func testAgeGateComesFirstAndIsRemembered() async throws {
        let defaults = try freshDefaults("teen")
        let service = CircleService(defaults: defaults, backend: LocalCircleBackend(store: store, userID: "teen"))
        XCTAssertEqual(service.access, .needsAge)
        try await service.setAge(.thirteenToFifteen)
        XCTAssertEqual(service.access, .ready)
        XCTAssertNotNil(service.code.flatMap(CircleService.normalize))
        XCTAssertEqual(CircleService(defaults: defaults, backend: LocalCircleBackend(store: store, userID: "teen")).access, .ready)
    }

    func testUnderThirteenWaitsForAGrownUp() async throws {
        let kid = try await phone("kid", band: .under13)
        XCTAssertEqual(kid.access, .needsConsent)
        try await kid.setAge(.sixteenPlus)
        XCTAssertEqual(kid.access, .needsConsent, "Changing the answer doesn't get around the gate")
        XCTAssertNil(kid.code)
        let teen = try await phone("teen")
        do {
            _ = try await kid.addFriend(code: XCTUnwrap(teen.code))
            XCTFail("Under-13s can't add friends yet")
        } catch { XCTAssertEqual(error as? CircleError, .notAllowed) }
    }

    func testFriendsAddEachOtherWithACodeAndAYes() async throws {
        let alice = try await phone("alice")
        let bob = try await phone("bob")
        let outcome = try await bob.addFriend(code: XCTUnwrap(alice.code))
        XCTAssertEqual(outcome, .sent)
        XCTAssertEqual(alice.snapshot.requests.map(\.nickname), ["Bob"])
        XCTAssertTrue(bob.snapshot.friends.isEmpty, "Nothing until they say yes")
        try await alice.respond(to: XCTUnwrap(alice.snapshot.requests.first), accept: true)
        XCTAssertEqual(alice.snapshot.friends.map(\.nickname), ["Bob"])
        XCTAssertEqual(bob.snapshot.friends.map(\.nickname), ["Alice"])
        XCTAssertTrue(alice.snapshot.requests.isEmpty)
        XCTAssertEqual(alice.memberCount, 2)
    }

    func testAddingSomeoneWhoAskedYouIsInstant() async throws {
        let alice = try await phone("alice")
        let bob = try await phone("bob")
        _ = try await bob.addFriend(code: XCTUnwrap(alice.code))
        let outcome = try await alice.addFriend(code: XCTUnwrap(bob.code))
        XCTAssertEqual(outcome, .friends)
        XCTAssertEqual(bob.snapshot.friends.map(\.id), ["alice"])
    }

    func testDecliningLeavesNoTrace() async throws {
        let alice = try await phone("alice")
        let bob = try await phone("bob")
        _ = try await bob.addFriend(code: XCTUnwrap(alice.code))
        try await alice.respond(to: XCTUnwrap(alice.snapshot.requests.first), accept: false)
        XCTAssertTrue(alice.snapshot.requests.isEmpty)
        XCTAssertTrue(alice.snapshot.friends.isEmpty)
    }

    func testBadCodesExplainThemselves() async throws {
        let alice = try await phone("alice")
        let cases: [(String, CircleError)] = [("ABC", .invalidCode), (try XCTUnwrap(alice.code), .ownCode), ("ZZZZZZ", .notFound)]
        for (code, expected) in cases {
            do {
                _ = try await alice.addFriend(code: code)
                XCTFail("\(code) should fail")
            } catch { XCTAssertEqual(error as? CircleError, expected) }
        }
    }

    func testANewCodeRetiresTheOldOne() async throws {
        let alice = try await phone("alice")
        let bob = try await phone("bob")
        let old = try XCTUnwrap(alice.code)
        try await alice.resetCode()
        XCTAssertNotEqual(alice.code, old)
        do {
            _ = try await bob.addFriend(code: old)
            XCTFail("The old code is gone")
        } catch { XCTAssertEqual(error as? CircleError, .notFound) }
    }

    func testCirclesTopOutAtSixFriends() async throws {
        let alice = try await phone("alice")
        for index in 0..<CircleLimits.maxFriends {
            try await friends(alice, try await phone("friend\(index)"))
        }
        XCTAssertTrue(alice.isFull)
        XCTAssertEqual(alice.memberCount, 7)
        let late = try await phone("late")
        do {
            _ = try await late.addFriend(code: XCTUnwrap(alice.code))
            XCTFail("Alice is full")
        } catch { XCTAssertEqual(error as? CircleError, .theyFull) }
        do {
            _ = try await alice.addFriend(code: XCTUnwrap(late.code))
            XCTFail("Alice is full")
        } catch { XCTAssertEqual(error as? CircleError, .youFull) }
    }

    func testFriendsSeeEachOthersProgressAndNames() async throws {
        let alice = try await phone("alice")
        let bob = try await phone("bob")
        try await friends(alice, bob)
        bob.updateYou(count: 4, streak: 2)
        bob.setNickname("Bobby!")
        await settle()
        let seen = try XCTUnwrap(alice.snapshot.friends.first)
        XCTAssertEqual(seen.nickname, "Bobby")
        XCTAssertEqual(seen.count, 4)
        XCTAssertEqual(seen.streak, 2)
    }

    func testBravesReachTheFeedAndBannerOnlyFriends() async throws {
        let alice = try await phone("alice")
        let bob = try await phone("bob")
        try await friends(alice, bob)
        await bob.sendPing(.tinyTask, stage: 1)
        let item = try XCTUnwrap(alice.snapshot.feed.first)
        XCTAssertEqual(item.nickname, "Bob")
        XCTAssertEqual(item.message, .tinyTask)
        XCTAssertEqual(item.stage, 1)
        XCTAssertFalse(item.mine)
        XCTAssertEqual(alice.banner, CirclePing(id: item.id, name: "Bob", message: PingMessage.tinyTask.text))
        XCTAssertEqual(bob.snapshot.feed.first?.mine, true, "Your own braves are on your timeline too")
        XCTAssertNil(bob.banner, "No banner for your own brave")
    }

    func testOldPostsDontBannerWhenYouOpenTheApp() async throws {
        let alice = try await phone("alice")
        let bob = try await phone("bob")
        try await friends(alice, bob)
        await bob.sendPing(.tinyTask, stage: 1)
        let relaunched = CircleService(defaults: try freshDefaults("alice"), backend: LocalCircleBackend(store: store, userID: "alice"))
        await relaunched.start()
        try await relaunched.setAge(.thirteenToFifteen)
        XCTAssertEqual(relaunched.snapshot.feed.count, 1)
        XCTAssertNil(relaunched.banner)
    }

    func testReactionsToggleAndOnlyFriendsCanReact() async throws {
        let alice = try await phone("alice")
        let bob = try await phone("bob")
        let carol = try await phone("carol")
        try await friends(alice, bob)
        await bob.sendPing(.lookAtYou, stage: 2)
        let item = try XCTUnwrap(alice.snapshot.feed.first)
        try await alice.react(.fire, to: item)
        XCTAssertEqual(bob.snapshot.feed.first?.reactions, ["alice": .fire])
        XCTAssertEqual(bob.snapshot.feed.first?.tally.first?.reaction, .fire)
        try await alice.react(.fire, to: XCTUnwrap(alice.snapshot.feed.first))
        XCTAssertEqual(bob.snapshot.feed.first?.reactions, [:], "Tapping the same one takes it back")
        do {
            try await bob.react(.heart, to: XCTUnwrap(bob.snapshot.feed.first))
            XCTFail("No reacting to yourself")
        } catch {}
        do {
            try await carol.react(.heart, to: item)
            XCTFail("Only friends react")
        } catch {}
        XCTAssertEqual(bob.snapshot.feed.first?.reactions, [:])
    }

    func testMutingIsJustForYou() async throws {
        let alice = try await phone("alice")
        let bob = try await phone("bob")
        try await friends(alice, bob)
        try await alice.setMuted(true, friend: XCTUnwrap(alice.snapshot.friends.first))
        XCTAssertEqual(alice.snapshot.friends.first?.muted, true)
        XCTAssertEqual(bob.snapshot.friends.first?.muted, false)
    }

    func testRemovingTakesYouOutOfEachOthersFeeds() async throws {
        let alice = try await phone("alice")
        let bob = try await phone("bob")
        try await friends(alice, bob)
        await bob.sendPing(.tinyTask, stage: 1)
        try await alice.remove(XCTUnwrap(alice.snapshot.friends.first))
        XCTAssertTrue(alice.snapshot.friends.isEmpty)
        XCTAssertTrue(bob.snapshot.friends.isEmpty)
        XCTAssertTrue(alice.snapshot.feed.isEmpty)
        XCTAssertNil(alice.memberCount)
    }

    func testBlockingStopsNewRequests() async throws {
        let alice = try await phone("alice")
        let bob = try await phone("bob")
        try await friends(alice, bob)
        try await alice.block(XCTUnwrap(alice.snapshot.friends.first))
        XCTAssertTrue(bob.snapshot.friends.isEmpty)
        do {
            _ = try await bob.addFriend(code: XCTUnwrap(alice.code))
            XCTFail("A block looks like a missing code")
        } catch { XCTAssertEqual(error as? CircleError, .notFound) }
        do {
            _ = try await alice.addFriend(code: XCTUnwrap(bob.code))
            XCTFail("You blocked them")
        } catch { XCTAssertEqual(error as? CircleError, .youBlocked) }
        XCTAssertTrue(alice.snapshot.requests.isEmpty)
    }

    func testDeletingCircleDataStartsOver() async throws {
        let alice = try await phone("alice")
        let bob = try await phone("bob")
        try await friends(alice, bob)
        await alice.sendPing(.tinyTask, stage: 1)
        try await alice.deleteData()
        XCTAssertEqual(alice.access, .needsAge)
        XCTAssertNil(alice.code)
        XCTAssertTrue(alice.snapshot.feed.isEmpty)
        XCTAssertTrue(bob.snapshot.friends.isEmpty)
        XCTAssertTrue(bob.snapshot.feed.isEmpty)
    }

    func testPingMessagesFollowTheStages() {
        XCTAssertEqual(PingMessage.forStage(1, goal: 30), .tinyTask)
        XCTAssertEqual(PingMessage.forStage(5, goal: 30), .lookAtYou)
        XCTAssertEqual(PingMessage.forStage(30, goal: 30), .allThirty)
    }
}
