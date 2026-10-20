import Foundation

/// The only things a ping can say. Circles never carry free text, so a server only ever stores one of these IDs.
enum PingMessage: String, Codable, CaseIterable {
    case lookAtYou, tinyTask, courageLouder, balloonSaw, fearInconvenienced, allThirty

    var text: String {
        switch self {
        case .lookAtYou: "look at you."
        case .tinyTask: "tiny task. real puff."
        case .courageLouder: "courage got louder."
        case .balloonSaw: "balloon definitely saw that."
        case .fearInconvenienced: "fear found this inconvenient."
        case .allThirty: "thirty. whole. braves."
        }
    }

    private static let everyday: [PingMessage] = [.lookAtYou, .tinyTask, .courageLouder, .balloonSaw, .fearInconvenienced]

    /// The message for the brave that just brought the balloon to `stage`.
    static func forStage(_ stage: Int, goal: Int) -> PingMessage {
        stage >= goal ? .allThirty : everyday[stage % everyday.count]
    }
}
