import Foundation
import SwiftData

@Model
final class Completion {
    var challengeID: Int
    var date: Date
    var round: Int = 1

    init(challengeID: Int, date: Date = .now, round: Int = 1) {
        self.challengeID = challengeID
        self.date = date
        self.round = round
    }
}

/// A drawing or tiny recording kept as the receipt for a completed brave. It outlives resets and rounds.
@Model
final class Response {
    var challengeID: Int
    var title: String
    var round: Int
    var kindRaw: String
    var filename: String
    var date: Date

    init(challengeID: Int, title: String, round: Int, kind: ResponseKind, filename: String, date: Date = .now) {
        self.challengeID = challengeID
        self.title = title
        self.round = round
        self.kindRaw = kind.rawValue
        self.filename = filename
        self.date = date
    }

    var kind: ResponseKind { ResponseKind(rawValue: kindRaw) ?? .drawing }
    var label: String { "R\(round) · #\(challengeID) · \(title)" }
}

enum ResponseKind: String {
    case drawing, audio
    /// Recorded by earlier versions; still kept and playable.
    case video
}

/// Where response media lives on disk.
enum ResponseFiles {
    static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("Responses", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    static func url(for filename: String) -> URL { directory.appendingPathComponent(filename) }

    static func newFilename(kind: ResponseKind) -> String {
        let ext = switch kind {
        case .drawing: "png"
        case .audio: "m4a"
        case .video: "mov"
        }
        return "\(UUID().uuidString).\(ext)"
    }
}
