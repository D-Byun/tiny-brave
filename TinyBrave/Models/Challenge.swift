import Foundation

enum Level: String, Codable, CaseIterable, Identifiable {
    case pebble, hill, mountain

    var id: String { rawValue }
    var title: String { rawValue.capitalized }

    var blurb: String {
        switch self {
        case .pebble: "Low-stakes courage"
        case .hill: "Noticeably uncomfortable"
        case .mountain: "A meaningful stretch"
        }
    }

    var symbol: String {
        switch self {
        case .pebble: "•"
        case .hill: "▲"
        case .mountain: "⛰"
        }
    }
}

enum BraveCategory: String, Codable, CaseIterable, Identifiable {
    case speak, begin, connect, repair, beSeen, protect

    var id: String { rawValue }

    var title: String {
        switch self {
        case .beSeen: "Be Seen"
        default: rawValue.capitalized
        }
    }
}

struct Challenge: Codable, Identifiable, Hashable {
    let id: Int
    let category: BraveCategory
    let level: Level
    let text: String
}
