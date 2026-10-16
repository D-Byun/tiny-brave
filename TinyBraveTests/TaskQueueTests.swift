import XCTest
@testable import TinyBrave

final class TaskQueueTests: XCTestCase {
    private let catalog = [1, 2, 3, 4, 5]

    func testStartsInCatalogOrder() {
        let queue = TaskQueue(catalog: catalog, completed: [])
        XCTAssertEqual(queue.ids, [1, 2, 3, 4, 5])
        XCTAssertEqual(queue.current, 1)
    }

    func testSkipMovesCurrentToTheEnd() {
        var queue = TaskQueue(catalog: catalog, completed: [])
        queue.skip()
        XCTAssertEqual(queue.ids, [2, 3, 4, 5, 1])
        XCTAssertEqual(queue.current, 2)
        queue.skip()
        XCTAssertEqual(queue.ids, [3, 4, 5, 1, 2])
    }

    func testSkippedTaskComesBackAfterEveryOtherOne() {
        var queue = TaskQueue(catalog: [1, 2, 3], completed: [])
        queue.skip()
        queue.complete(2)
        queue.complete(3)
        XCTAssertEqual(queue.current, 1)
    }

    func testSkipWithOneTaskLeftKeepsIt() {
        var queue = TaskQueue(catalog: [1], completed: [])
        queue.skip()
        XCTAssertEqual(queue.ids, [1])
    }

    func testSkipOnEmptyQueueDoesNothing() {
        var queue = TaskQueue(catalog: [1], completed: [1])
        queue.skip()
        XCTAssertTrue(queue.isEmpty)
        XCTAssertNil(queue.current)
    }

    func testCompleteRemovesTheTaskAndAdvances() {
        var queue = TaskQueue(catalog: catalog, completed: [])
        queue.complete(1)
        XCTAssertEqual(queue.ids, [2, 3, 4, 5])
        XCTAssertEqual(queue.current, 2)
    }

    func testCompleteRemovesATaskThatIsNotCurrent() {
        var queue = TaskQueue(catalog: catalog, completed: [])
        queue.complete(4)
        XCTAssertEqual(queue.ids, [1, 2, 3, 5])
    }

    func testCompletingEverythingEmptiesTheQueue() {
        var queue = TaskQueue(catalog: [1, 2], completed: [])
        queue.complete(1)
        queue.complete(2)
        XCTAssertTrue(queue.isEmpty)
        XCTAssertNil(queue.current)
    }

    func testRestoreKeepsSavedOrderAndDropsCompletedAndUnknown() {
        let queue = TaskQueue(catalog: catalog, completed: [2], saved: [4, 2, 99, 1])
        XCTAssertEqual(queue.ids, [4, 1, 3, 5])
    }

    func testRestoreAppendsTasksMissingFromTheSavedOrder() {
        let queue = TaskQueue(catalog: catalog, completed: [], saved: [3, 1])
        XCTAssertEqual(queue.ids, [3, 1, 2, 4, 5])
    }

    func testRestoreIgnoresDuplicates() {
        let queue = TaskQueue(catalog: catalog, completed: [], saved: [2, 2, 1, 2])
        XCTAssertEqual(queue.ids, [2, 1, 3, 4, 5])
    }

    func testRealCatalogQueuesAllThirtyTasks() {
        let ids = Rounds.catalog(round: 1, all: ChallengeStore.shared.all)
        let queue = TaskQueue(catalog: ids, completed: [])
        XCTAssertEqual(queue.ids, ids)
        XCTAssertEqual(queue.count, 30)
    }

    func testStorageRoundTripsAndClears() throws {
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "TaskQueueTests"))
        defer { defaults.removePersistentDomain(forName: "TaskQueueTests") }
        XCTAssertEqual(TaskQueueStorage.load(from: defaults), [])

        var queue = TaskQueue(catalog: catalog, completed: [])
        queue.skip()
        queue.complete(3)
        TaskQueueStorage.save(queue, to: defaults)
        XCTAssertEqual(TaskQueueStorage.load(from: defaults), [2, 4, 5, 1])

        let restored = TaskQueue(catalog: catalog, completed: [3], saved: TaskQueueStorage.load(from: defaults))
        XCTAssertEqual(restored, queue)

        TaskQueueStorage.clear(from: defaults)
        XCTAssertEqual(TaskQueueStorage.load(from: defaults), [])
    }
}
