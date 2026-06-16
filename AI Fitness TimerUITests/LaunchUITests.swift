import XCTest

final class LaunchUITests: XCTestCase {
    func testLaunchShowsWorkoutCheckpointEntry() {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["AI Fitness Timer"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["打开计时器预览"].exists)
    }
}
