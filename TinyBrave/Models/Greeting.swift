import Foundation

enum Greeting {
    static func text(name: String, now: Date = .now, calendar: Calendar = .current) -> String {
        let period = switch calendar.component(.hour, from: now) {
        case 5..<12: "morning"
        case 12..<17: "afternoon"
        default: "evening"
        }
        let name = Username.clean(name)
        return name.isEmpty ? "Good \(period)" : "Good \(period), \(name)"
    }
}
