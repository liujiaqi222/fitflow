import XCTest
@testable import AI_Fitness_Timer

final class MockClockTests: XCTestCase {
    func testSleepCompletesAfterAdvance() async throws {
        let clock = MockAppClock()
        let task = Task { try await clock.sleep(seconds: 3) }
        await Task.yield()
        await clock.advance(seconds: 2)
        XCTAssertFalse(task.isCancelled)
        await clock.advance(seconds: 1)
        try await task.value
    }
}
