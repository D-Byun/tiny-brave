import Foundation
import SwiftData

@Model
final class Completion {
    var challengeID: Int
    var date: Date
    /// 0 = less awkward than expected, 1 = as expected, 2 = more awkward.
    var awkwardness: Int?

    init(challengeID: Int, date: Date = .now) {
        self.challengeID = challengeID
        self.date = date
    }
}
