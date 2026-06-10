import XCTest
@testable import AI_Fitness_Timer

final class SmokeTests: XCTestCase {
    func testAppRouteHashable() {
        XCTAssertEqual(AppRoute.chat, AppRoute.chat)
    }
}
