import Foundation

/// The app's notion of "now". The offset lets testers simulate later days from Settings.
enum AppClock {
    static let offsetKey = "debugDayOffset"

    static var now: Date { now(offsetDays: UserDefaults.standard.integer(forKey: offsetKey)) }

    static func now(offsetDays: Int) -> Date {
        Calendar.current.date(byAdding: .day, value: offsetDays, to: .now) ?? .now
    }
}

/// One completion a day extends the streak and pumps the balloon up a stage; missing a day deflates it.
/// Extra completions on the same day are allowed but change neither.
enum DailyGoal {
    private static func days(_ completions: [Completion], calendar: Calendar) -> Set<Date> {
        Set(completions.map { calendar.startOfDay(for: $0.date) })
    }

    static func completedToday(_ completions: [Completion], now: Date = AppClock.now, calendar: Calendar = .current) -> Int {
        completions.filter { calendar.isDate($0.date, inSameDayAs: now) }.count
    }

    static func isDoneToday(_ completions: [Completion], now: Date = AppClock.now, calendar: Calendar = .current) -> Bool {
        completedToday(completions, now: now, calendar: calendar) > 0
    }

    /// Number of distinct days with at least one completion, ever; this drives certificates.
    static func activeDays(_ completions: [Completion], calendar: Calendar = .current) -> Int {
        days(completions, calendar: calendar).count
    }

    /// Consecutive days with a completion. Still alive if today isn't done yet but yesterday was.
    static func streak(_ completions: [Completion], now: Date = AppClock.now, calendar: Calendar = .current) -> Int {
        let active = days(completions, calendar: calendar)
        var cursor = calendar.startOfDay(for: now)
        if !active.contains(cursor), let yesterday = calendar.date(byAdding: .day, value: -1, to: cursor) {
            cursor = yesterday
        }
        var count = 0
        while active.contains(cursor) {
            count += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        return count
    }

    /// The balloon's stage is the current streak, capped at the goal.
    static func stage(_ completions: [Completion], now: Date = AppClock.now, calendar: Calendar = .current) -> Int {
        BraveProgress.done(streak(completions, now: now, calendar: calendar))
    }

    static func streakText(_ streak: Int) -> String {
        streak == 1 ? "1 day streak" : "\(streak) day streak"
    }
}
