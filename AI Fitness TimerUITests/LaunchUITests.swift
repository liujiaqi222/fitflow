import XCTest

final class LaunchUITests: XCTestCase {
    func testLaunchShowsHomeTitle() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["AI Fitness Timer"].waitForExistence(timeout: 3))
    }
}
