import XCTest

/// The floor under every other UI test: the app launches and stays up. Also the iPad compatibility
/// smoke when run on an iPad simulator (architecture §6).
final class LaunchSmokeUITests: XCTestCase {
    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    func testAppLaunchesAndStaysInTheForeground() {
        let app = XCUIApplication()
        app.launchArguments = ["-calo.uitest"]
        app.launch()
        XCTAssertTrue(app.wait(for: .runningForeground, timeout: 30))
        XCTAssertTrue(app.windows.firstMatch.waitForExistence(timeout: 15))
        XCTAssertEqual(app.state, .runningForeground)
    }
}
