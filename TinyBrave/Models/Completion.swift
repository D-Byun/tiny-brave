import Foundation
import SwiftData

@Model
final class Completion {
    var challengeID: Int
    var date: Date
    var debrisKey: String
    /// 0 = less awkward than expected, 1 = as expected, 2 = more awkward.
    var awkwardness: Int?

    init(challengeID: Int, debrisKey: String, date: Date = .now) {
        self.challengeID = challengeID
        self.debrisKey = debrisKey
        self.date = date
    }
}
