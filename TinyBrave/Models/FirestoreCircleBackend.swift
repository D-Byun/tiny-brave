import FirebaseAppCheck
import FirebaseAuth
import FirebaseCore
import FirebaseFirestore
import FirebaseFunctions
import Foundation

/// Starts Firebase once. Uses the local emulators with `-firebaseEmulator`, otherwise needs
/// `GoogleService-Info.plist` in the app. Returns false when neither is available.
enum FirebaseSetup {
    static let emulatorProject = "demo-tinybrave"

    @MainActor static private(set) var isConfigured = false

    @MainActor
    static func configure(arguments: [String] = ProcessInfo.processInfo.arguments) -> Bool {
        if isConfigured { return true }
        AppCheck.setAppCheckProviderFactory(TinyBraveAppCheckFactory())
        if arguments.contains("-firebaseEmulator") {
            FirebaseApp.configure(options: emulatorOptions)
            connectToEmulators(FirebaseApp.app()!)
        } else {
            guard Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil else { return false }
            FirebaseApp.configure()
        }
        isConfigured = true
        return true
    }

    private static var emulatorOptions: FirebaseOptions {
        let options = FirebaseOptions(googleAppID: "1:123456789012:ios:0123456789abcdef", gcmSenderID: "123456789012")
        options.projectID = emulatorProject
        options.apiKey = "AFakeEmulatorOnlyKeyNotARealFirebaseKey"
        return options
    }

    /// A separate app, signed in on its own, talking to the local emulators. Tests use one per pretend phone.
    static func emulatorApp(named name: String) -> FirebaseApp {
        if let existing = FirebaseApp.app(name: name) { return existing }
        AppCheck.setAppCheckProviderFactory(TinyBraveAppCheckFactory())
        FirebaseApp.configure(name: name, options: emulatorOptions)
        let app = FirebaseApp.app(name: name)!
        connectToEmulators(app)
        return app
    }

    private static func connectToEmulators(_ app: FirebaseApp) {
        let host = "127.0.0.1"
        Auth.auth(app: app).useEmulator(withHost: host, port: 9099)
        let firestore = Firestore.firestore(app: app)
        let settings = firestore.settings
        settings.host = "\(host):8080"
        settings.isSSLEnabled = false
        settings.cacheSettings = MemoryCacheSettings()
        firestore.settings = settings
        Functions.functions(app: app, region: FirestoreCircleBackend.region).useEmulator(withHost: host, port: 5001)
    }
}

/// App Attest on devices; the debug provider on the simulator (register its token in the console).
/// None for the emulators, which don't check.
final class TinyBraveAppCheckFactory: NSObject, AppCheckProviderFactory {
    func createProvider(with app: FirebaseApp) -> AppCheckProvider? {
        if app.options.projectID == FirebaseSetup.emulatorProject { return nil }
        #if targetEnvironment(simulator)
        return AppCheckDebugProvider(app: app)
        #else
        return AppAttestProvider(app: app)
        #endif
    }
}

private final class FirestoreObservation: CircleObservation {
    private var registrations: [ListenerRegistration]
    init(_ registrations: [ListenerRegistration]) { self.registrations = registrations }
    func cancel() {
        registrations.forEach { $0.remove() }
        registrations = []
    }
}

/// Circles on Firebase: anonymous Auth, Firestore listeners for your own documents, and callable
/// functions for anything that touches someone else's. See `firestore.rules` and `functions/`.
@MainActor
final class FirestoreCircleBackend: CircleBackend {
    nonisolated static let region = "us-central1"

    private let auth: Auth
    private let db: Firestore
    private let functions: Functions

    /// Uses the default Firebase app unless given another (tests run one per pretend phone).
    init(app: FirebaseApp? = nil) {
        let app = app ?? FirebaseApp.app()!
        auth = Auth.auth(app: app)
        db = Firestore.firestore(app: app)
        functions = Functions.functions(app: app, region: Self.region)
    }

    private func uid() throws -> String {
        guard let uid = auth.currentUser?.uid else { throw CircleError.unavailable }
        return uid
    }

    private func user(_ path: String = "") throws -> DocumentReference {
        let base = db.collection("users").document(try uid())
        return path.isEmpty ? base : base.collection(path).document()
    }

    @discardableResult
    private func call(_ name: String, _ data: [String: Any] = [:]) async throws -> [String: Any] {
        do {
            return try await functions.httpsCallable(name).call(data).data as? [String: Any] ?? [:]
        } catch let error as NSError where error.domain == FunctionsErrorDomain {
            let reason = (error.userInfo[FunctionsErrorDetailsKey] as? [String: Any])?["reason"] as? String
            if reason == nil, error.code == FunctionsErrorCode.permissionDenied.rawValue { throw CircleError.notAllowed }
            throw CircleError(reason: reason)
        }
    }

    func signIn() async throws -> String {
        if let current = auth.currentUser { return current.uid }
        return try await auth.signInAnonymously().user.uid
    }

    func setAgeBand(_ band: AgeBand) async throws -> Bool {
        let result = try await call("setAgeBand", ["band": band.rawValue])
        // The function changed this account's claims; a fresh token makes the rules see them.
        _ = try await auth.currentUser?.getIDTokenResult(forcingRefresh: true)
        return result["social"] as? Bool ?? false
    }

    func code(reset: Bool) async throws -> String {
        let result = try await call(reset ? "resetCode" : "myCode")
        guard let code = result["code"] as? String else { throw CircleError.unavailable }
        return code
    }

    func sendRequest(code: String) async throws -> AddOutcome {
        let result = try await call("sendRequest", ["code": code])
        return result["status"] as? String == "friends" ? .friends : .sent
    }

    func respond(to userID: String, accept: Bool) async throws {
        try await call("respondRequest", ["from": userID, "accept": accept])
    }

    func removeFriend(_ userID: String) async throws {
        try await call("removeFriend", ["uid": userID])
    }

    func block(_ userID: String) async throws {
        try await call("blockUser", ["uid": userID])
    }

    func setMuted(_ muted: Bool, friend userID: String) async throws {
        try await user().collection("friends").document(userID).updateData(["muted": muted])
    }

    func updateProfile(_ profile: CircleProfile, timeZone: String) async throws {
        try await user().setData([
            "nickname": profile.nickname,
            "count": profile.count,
            "streak": profile.streak,
            "tz": timeZone,
            "updatedAt": FieldValue.serverTimestamp(),
        ])
    }

    func post(_ message: PingMessage, stage: Int) async throws {
        let expires = Date.now.addingTimeInterval(TimeInterval(CircleLimits.postDays * 24 * 60 * 60))
        try await user("posts").setData([
            "message": message.rawValue,
            "stage": stage,
            "createdAt": FieldValue.serverTimestamp(),
            "expireAt": Timestamp(date: expires),
        ])
    }

    func react(_ reaction: Reaction?, to item: FeedItem) async throws {
        let ref = db.document("users/\(item.ownerID)/posts/\(item.id)/reactions/\(try uid())")
        if let reaction {
            let expires = item.date.addingTimeInterval(TimeInterval(CircleLimits.postDays * 24 * 60 * 60))
            try await ref.setData(["emoji": reaction.rawValue, "expireAt": Timestamp(date: max(expires, .now.addingTimeInterval(3600)))])
        } else {
            try await ref.delete()
        }
    }

    func registerDevice(token: String) async throws {
        try await user().collection("devices").document(token).setData(["platform": "ios", "updatedAt": FieldValue.serverTimestamp()])
    }

    func deleteAccount() async throws {
        try await call("deleteAccount")
        try? auth.signOut()
    }

    func observe(_ onChange: @escaping @MainActor (CircleSnapshot) -> Void) -> CircleObservation {
        guard let me = try? user() else { return FirestoreObservation([]) }
        var snapshot = CircleSnapshot()
        var loaded = Set<String>()
        // Firestore calls listeners on the main queue. Nothing is published until all three have
        // answered once, so a half-loaded snapshot never looks like a burst of new posts.
        func publish(_ source: String, _ update: (inout CircleSnapshot) -> Void) {
            MainActor.assumeIsolated {
                update(&snapshot)
                loaded.insert(source)
                if loaded.count == 3 { onChange(snapshot) }
            }
        }
        let friends = me.collection("friends").addSnapshotListener { query, _ in
            guard let query else { return }
            publish("friends") { $0.friends = query.documents.map(Self.friend) }
        }
        let requests = me.collection("requests").order(by: "createdAt").addSnapshotListener { query, _ in
            guard let query else { return }
            publish("requests") { $0.requests = query.documents.map { CircleRequest(id: $0.documentID, nickname: $0["nickname"] as? String ?? CircleService.defaultNickname) } }
        }
        let feed = me.collection("feed").order(by: "createdAt", descending: true).limit(to: CircleLimits.feedSize).addSnapshotListener { query, _ in
            guard let query else { return }
            publish("feed") { $0.feed = query.documents.compactMap(Self.feedItem) }
        }
        return FirestoreObservation([friends, requests, feed])
    }

    nonisolated private static func friend(_ doc: QueryDocumentSnapshot) -> CircleFriend {
        CircleFriend(
            id: doc.documentID,
            nickname: doc["nickname"] as? String ?? CircleService.defaultNickname,
            count: doc["count"] as? Int ?? 0,
            streak: doc["streak"] as? Int ?? 0,
            muted: doc["muted"] as? Bool ?? false
        )
    }

    nonisolated private static func feedItem(_ doc: QueryDocumentSnapshot) -> FeedItem? {
        guard let owner = doc["ownerUid"] as? String,
              let message = (doc["message"] as? String).flatMap(PingMessage.init(rawValue:)) else { return nil }
        let reactions = (doc["reactions"] as? [String: String] ?? [:]).compactMapValues(Reaction.init(rawValue:))
        return FeedItem(
            id: doc.documentID,
            ownerID: owner,
            nickname: doc["nickname"] as? String ?? CircleService.defaultNickname,
            message: message,
            stage: doc["stage"] as? Int ?? 0,
            date: (doc["createdAt"] as? Timestamp)?.dateValue() ?? .now,
            mine: doc["mine"] as? Bool ?? false,
            reactions: reactions
        )
    }
}
