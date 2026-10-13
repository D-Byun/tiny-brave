import Foundation

enum Username {
    static let storageKey = "username"
    static let maxLength = 20

    static func clean(_ raw: String) -> String {
        String(raw.trimmingCharacters(in: .whitespacesAndNewlines).prefix(maxLength))
    }
}
