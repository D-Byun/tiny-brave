import Foundation

enum CircleError: Error, Equatable {
    case invalidCode, notFound, ownCode, youFull, theyFull, youBlocked, tooMany, noRequest, notAllowed, unavailable

    /// Maps the `reason` a Cloud Function sends back.
    init(reason: String?) {
        self = switch reason {
        case "invalidCode": .invalidCode
        case "notFound": .notFound
        case "ownCode": .ownCode
        case "youFull": .youFull
        case "theyFull": .theyFull
        case "youBlocked": .youBlocked
        case "tooMany": .tooMany
        case "noRequest": .noRequest
        default: .unavailable
        }
    }

    var message: String {
        switch self {
        case .invalidCode: "that code needs six letters."
        case .notFound: "couldn't find that circle."
        case .ownCode: "that's your own code. share it with a friend."
        case .youFull: "your circle is full. six friends, tops."
        case .theyFull: "their circle is full."
        case .youBlocked: "you blocked this person."
        case .tooMany: "that's a lot of tries. try again tomorrow."
        case .noRequest: "that request is gone."
        case .notAllowed: "circles aren't on for this account yet."
        case .unavailable: "couldn't reach the circle. try again?"
        }
    }
}

enum CircleLimits {
    /// Friends per person, not counting you.
    static let maxFriends = 6
    static let feedSize = 50
    static let postDays = 30
}

/// The only reactions there are. Positive on purpose: nobody gets a thumbs-down on a brave thing.
enum Reaction: String, Codable, CaseIterable, Identifiable {
    case balloon, clap, strong, fire, heart, star

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .balloon: "🎈"
        case .clap: "👏"
        case .strong: "💪"
        case .fire: "🔥"
        case .heart: "🫶"
        case .star: "⭐"
        }
    }
}

/// What the server needs to know about age. Exact birthdays never leave the phone.
enum AgeBand: String, Codable {
    case under13
    case thirteenToFifteen = "13to15"
    case sixteenPlus = "16plus"

    init(age: Int) {
        self = age < 13 ? .under13 : age < 16 ? .thirteenToFifteen : .sixteenPlus
    }

    /// From a birth month and year. Someone born this month counts as not having had the birthday yet,
    /// so a guess always errs younger.
    init(birthMonth: Int, year: Int, now: Date = .now, calendar: Calendar = .current) {
        let today = calendar.dateComponents([.year, .month], from: now)
        let age = (today.year ?? year) - year - ((today.month ?? 1) <= birthMonth ? 1 : 0)
        self.init(age: age)
    }

    /// From the bounds Apple's Declared Age Range shares for gates at 13 and 16. Nil when it can't tell.
    init?(lowerBound: Int?, upperBound: Int?) {
        if let lowerBound, lowerBound >= 13 {
            self.init(age: lowerBound)
        } else if let upperBound, upperBound < 13 {
            self = .under13
        } else {
            return nil
        }
    }
}

enum CircleAccess: Equatable {
    /// No backend configured, or it couldn't be reached on the first try.
    case unavailable
    case needsAge
    /// Under 13: a grown-up has to say yes first.
    case needsConsent
    case ready
}

struct CircleProfile: Codable, Equatable {
    var nickname: String
    var count: Int
    var streak: Int
}

struct CircleFriend: Codable, Identifiable, Equatable {
    var id: String
    var nickname: String
    var count: Int
    var streak: Int
    var muted = false
}

struct CircleRequest: Codable, Identifiable, Equatable {
    var id: String
    var nickname: String
}

/// One brave in someone's feed: yours or a friend's. Reactions are keyed by who sent them.
struct FeedItem: Codable, Identifiable, Equatable {
    var id: String
    var ownerID: String
    var nickname: String
    var message: PingMessage
    var stage: Int
    var date: Date
    var mine: Bool
    var reactions: [String: Reaction] = [:]

    func reaction(from userID: String) -> Reaction? { reactions[userID] }

    /// Each emoji with how many people sent it, most popular first.
    var tally: [(reaction: Reaction, count: Int)] {
        let counts = Dictionary(grouping: reactions.values, by: { $0 }).mapValues(\.count)
        return Reaction.allCases.compactMap { reaction in counts[reaction].map { (reaction, $0) } }
            .sorted { $0.count > $1.count }
    }
}

struct CircleSnapshot: Codable, Equatable {
    var friends: [CircleFriend] = []
    var requests: [CircleRequest] = []
    var feed: [FeedItem] = []
}

enum AddOutcome: Equatable {
    case sent, friends
}

/// What the drop-in banner shows when a friend finishes a brave.
struct CirclePing: Identifiable, Equatable {
    var id: String
    var name: String
    var message: String
}
