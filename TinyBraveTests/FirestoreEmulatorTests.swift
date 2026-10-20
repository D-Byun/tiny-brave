import XCTest
@testable import TinyBrave

/// The real Firebase backend against the local emulators: Auth, Security Rules, callables and triggers.
/// Skipped unless the emulators are running. From the repo root:
///   (cd functions && npm run build)
///   firebase emulators:exec --project demo-tinybrave --only auth,firestore,functions \
///     "xcodebuild test -project TinyBrave.xcodeproj -scheme TinyBrave -destination '<simulator>' -only-testing:TinyBraveTests/FirestoreEmulatorTests"
@MainActor
final class FirestoreEmulatorTests: XCTestCase {
    private var suites: [String] = []

    override func setUp() async throws {
        let firestore = await Self.reachable("http://127.0.0.1:8080/")
        let auth = await Self.reachable("http://127.0.0.1:9099/")
        try XCTSkipUnless(firestore && auth, "Firebase emulators aren't running")
    }

    override func tearDown() {
        for name in suites { UserDefaults(suiteName: name)?.removePersistentDomain(forName: name) }
        suites = []
    }

    private static func reachable(_ url: String) async -> Bool {
        var request = URLRequest(url: URL(string: url)!)
        request.timeoutInterval = 2
        return (try? await URLSession.shared.data(for: request)) != nil
    }

    private func phone(_ name: String) async throws -> CircleService {
        let id = "\(name)-\(UUID().uuidString.prefix(8))"
        let suite = "FirestoreEmulatorTests.\(id)"
        suites.append(suite)
        let backend = FirestoreCircleBackend(app: FirebaseSetup.emulatorApp(named: id))
        let service = CircleService(defaults: try XCTUnwrap(UserDefaults(suiteName: suite)), backend: backend)
        service.setNickname(name)
        await service.start()
        try await service.setAge(.thirteenToFifteen)
        XCTAssertEqual(service.access, .ready)
        return service
    }

    /// Listeners and triggers are asynchronous; give them a few seconds to land.
    private func eventually(_ what: String, timeout: Duration = .seconds(20), _ condition: () -> Bool) async throws {
        let deadline = ContinuousClock.now + timeout
        while !condition() {
            guard ContinuousClock.now < deadline else { return XCTFail("Timed out waiting for \(what)") }
            try await Task.sleep(for: .milliseconds(150))
        }
    }

    func testTwoPhonesBecomeFriendsPostAndReact() async throws {
        let alice = try await phone("Alice")
        let bob = try await phone("Bob")
        let aliceCode = try XCTUnwrap(alice.code)
        XCTAssertNotNil(CircleService.normalize(aliceCode))

        let outcome = try await bob.addFriend(code: aliceCode)
        XCTAssertEqual(outcome, .sent)
        try await eventually("the request") { !alice.snapshot.requests.isEmpty }
        XCTAssertEqual(alice.snapshot.requests.first?.nickname, "Bob")
        try await alice.respond(to: XCTUnwrap(alice.snapshot.requests.first), accept: true)
        try await eventually("both friend lists") { alice.snapshot.friends.count == 1 && bob.snapshot.friends.count == 1 }
        XCTAssertEqual(bob.snapshot.friends.first?.nickname, "Alice")

        bob.updateYou(count: 3, streak: 2)
        try await eventually("Bob's progress") { alice.snapshot.friends.first?.count == 3 }

        await bob.sendPing(.courageLouder, stage: 3)
        try await eventually("the fan-out") { !alice.snapshot.feed.isEmpty && !bob.snapshot.feed.isEmpty }
        let item = try XCTUnwrap(alice.snapshot.feed.first)
        XCTAssertEqual(item.message, .courageLouder)
        XCTAssertEqual(item.stage, 3)
        XCTAssertFalse(item.mine)
        XCTAssertEqual(bob.snapshot.feed.first?.mine, true)
        try await eventually("the banner") { alice.banner?.id == item.id }

        try await alice.react(.star, to: item)
        try await eventually("the reaction") { bob.snapshot.feed.first?.reactions.values.contains(.star) == true }
        try await alice.react(.star, to: XCTUnwrap(alice.snapshot.feed.first))
        try await eventually("the reaction to go") { bob.snapshot.feed.first?.reactions.isEmpty == true }

        try await alice.setMuted(true, friend: XCTUnwrap(alice.snapshot.friends.first))
        try await eventually("mute") { alice.snapshot.friends.first?.muted == true }

        try await bob.remove(XCTUnwrap(bob.snapshot.friends.first))
        try await eventually("the unfriend") { alice.snapshot.friends.isEmpty && alice.snapshot.feed.isEmpty }
    }

    func testCodesAndBlocksSurfaceTheServerReasons() async throws {
        let alice = try await phone("Alice")
        let bob = try await phone("Bob")
        do {
            _ = try await bob.addFriend(code: "QQQQQQ")
            XCTFail("No such code")
        } catch { XCTAssertEqual(error as? CircleError, .notFound) }

        _ = try await bob.addFriend(code: XCTUnwrap(alice.code))
        let outcome = try await alice.addFriend(code: XCTUnwrap(bob.code))
        XCTAssertEqual(outcome, .friends, "Asking someone who already asked you is a yes")
        try await eventually("friends") { alice.snapshot.friends.count == 1 }

        try await alice.block(XCTUnwrap(alice.snapshot.friends.first))
        try await eventually("the block") { bob.snapshot.friends.isEmpty }
        do {
            _ = try await bob.addFriend(code: XCTUnwrap(alice.code))
            XCTFail("Blocked")
        } catch { XCTAssertEqual(error as? CircleError, .notFound) }
    }

    func testUnderThirteenIsHeldAtTheServer() async throws {
        let id = "kid-\(UUID().uuidString.prefix(8))"
        let suite = "FirestoreEmulatorTests.\(id)"
        suites.append(suite)
        let kid = CircleService(defaults: try XCTUnwrap(UserDefaults(suiteName: suite)),
                                backend: FirestoreCircleBackend(app: FirebaseSetup.emulatorApp(named: id)))
        await kid.start()
        try await kid.setAge(.under13)
        XCTAssertEqual(kid.access, .needsConsent)
        try await kid.setAge(.sixteenPlus)
        XCTAssertEqual(kid.access, .needsConsent)
        do {
            try await kid.loadCode()
            XCTFail("No code without consent")
        } catch { XCTAssertEqual(error as? CircleError, .notAllowed) }
    }

    func testDeletingDataRemovesYouFromFriends() async throws {
        let alice = try await phone("Alice")
        let bob = try await phone("Bob")
        _ = try await bob.addFriend(code: XCTUnwrap(alice.code))
        _ = try await alice.addFriend(code: XCTUnwrap(bob.code))
        try await eventually("friends") { bob.snapshot.friends.count == 1 }
        try await alice.deleteData()
        XCTAssertEqual(alice.access, .needsAge)
        try await eventually("Alice to vanish") { bob.snapshot.friends.isEmpty }
    }
}
