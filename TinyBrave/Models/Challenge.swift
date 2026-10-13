import Foundation

enum Level: String, Codable, CaseIterable, Identifiable {
    case warmUp = "warm-up"
    case tinyStretch = "tiny stretch"
    case quietBrave = "quiet brave"
    case mediumBrave = "medium brave"
    case boldish = "bold-ish"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .warmUp: "Warm-up"
        case .tinyStretch: "Tiny stretch"
        case .quietBrave: "Quiet brave"
        case .mediumBrave: "Medium brave"
        case .boldish: "Bold-ish"
        }
    }

    var blurb: String {
        switch self {
        case .warmUp: "Barely a stretch"
        case .tinyStretch: "A small, easy step"
        case .quietBrave: "Brave on the inside"
        case .mediumBrave: "Noticeably uncomfortable"
        case .boldish: "A real leap"
        }
    }

    var symbol: String {
        switch self {
        case .warmUp: "•"
        case .tinyStretch: "▴"
        case .quietBrave: "▲"
        case .mediumBrave: "◆"
        case .boldish: "★"
        }
    }
}

enum BraveCategory: String, Codable, CaseIterable, Identifiable {
    case connect, speak, `try`, reset

    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

struct Challenge: Codable, Identifiable, Hashable {
    let id: Int
    let category: BraveCategory
    let level: Level
    let text: String
    let why: String
}
