import Foundation

/// The tasks still to do, in the order they'll be offered. The first one is today's task.
struct TaskQueue: Equatable {
    private(set) var ids: [Int]

    /// Rebuilds a queue from a saved order. Unknown and completed ids are dropped, and any
    /// incomplete task that isn't in the saved order goes to the end in catalog order.
    init(catalog: [Int], completed: Set<Int>, saved: [Int] = []) {
        let valid = Set(catalog).subtracting(completed)
        var seen = Set<Int>()
        var ordered = saved.filter { valid.contains($0) && seen.insert($0).inserted }
        ordered += catalog.filter { valid.contains($0) && seen.insert($0).inserted }
        ids = ordered
    }

    var current: Int? { ids.first }
    var isEmpty: Bool { ids.isEmpty }
    var count: Int { ids.count }

    /// Sends the current task to the back so the next one comes up. A lone task stays put.
    mutating func skip() {
        guard ids.count > 1 else { return }
        ids.append(ids.removeFirst())
    }

    mutating func complete(_ id: Int) {
        ids.removeAll { $0 == id }
    }
}

enum TaskQueueStorage {
    static let key = "taskQueue"

    static func load(from defaults: UserDefaults = .standard) -> [Int] {
        defaults.array(forKey: key) as? [Int] ?? []
    }

    static func save(_ queue: TaskQueue, to defaults: UserDefaults = .standard) {
        defaults.set(queue.ids, forKey: key)
    }

    static func clear(from defaults: UserDefaults = .standard) {
        defaults.removeObject(forKey: key)
    }
}
