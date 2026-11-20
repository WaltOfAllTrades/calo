import XCTest

/// Calo flows (calo/tests.md → UI). The app runs with `-calo.uitest`: memory store seeded with
/// +400 and −50 for today, isolated settings, `now` pinned to 2026-11-20 10:00.
final class CaloFlowsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launch(extra: [String] = []) {
        app = XCUIApplication()
        app.launchArguments = ["-calo.uitest", "-calo.openAs", "calo"] + extra
        app.launch()
        XCTAssertTrue(app.otherElements["calo.keypad"].waitForExistence(timeout: 15))
    }

    @MainActor
    private func tap(_ key: String) {
        let element = app.buttons["calo.key.\(key)"]
        XCTAssertTrue(element.waitForExistence(timeout: 5), "key \(key)")
        element.tap()
    }

    @MainActor
    private func dash(_ id: String) -> String {
        app.otherElements["calo.dash.\(id)"].label
    }

    @MainActor
    func testLogsAnEntry() {
        launch()
        XCTAssertEqual(dash("logged"), "Logged 350 calories")
        XCTAssertEqual(dash("remaining"), "Remaining 1,650 calories")
        tap("2"); tap("5"); tap("0")
        XCTAssertEqual(app.staticTexts["calo.display.buffer"].label, "250")
        tap("enter")
        let logged = app.otherElements["calo.dash.logged"]
        XCTAssertTrue(logged.waitForLabel("Logged 600 calories", timeout: 5))
        XCTAssertEqual(dash("remaining"), "Remaining 1,400 calories")
        XCTAssertEqual(app.staticTexts["calo.display.buffer"].label, "")
        XCTAssertEqual(app.staticTexts["calo.display.intent"].label, "ADD")
    }

    @MainActor
    func testSubtractsAnEntryAndResetsIntent() {
        launch()
        tap("minus")
        XCTAssertEqual(app.staticTexts["calo.display.intent"].label, "SUB")
        tap("1"); tap("0"); tap("0"); tap("enter")
        XCTAssertTrue(app.otherElements["calo.dash.logged"].waitForLabel("Logged 250 calories", timeout: 5))
        XCTAssertEqual(app.staticTexts["calo.display.intent"].label, "ADD")
    }

    @MainActor
    func testBufferCapAndClear() {
        launch()
        tap("80"); tap("80"); tap("80")
        XCTAssertEqual(app.staticTexts["calo.display.buffer"].label, "8080")
        tap("backspace")
        XCTAssertEqual(app.staticTexts["calo.display.buffer"].label, "808")
        tap("clear")
        XCTAssertEqual(app.staticTexts["calo.display.buffer"].label, "")
    }

    @MainActor
    func testSettingsFieldsAndTarget() {
        launch()
        app.buttons["calo.header.settings"].tap()
        let toggle = app.switches["calo.settings.showName"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        toggle.switches.firstMatch.tap()
        let target = app.textFields["calo.settings.target"]
        target.tap()
        target.typeText(XCUIKeyboardKey.delete.rawValue)
        target.doubleTap()
        target.typeText("1500")
        app.buttons["calo.settings.done"].tap()
        XCTAssertTrue(app.textFields["calo.field.name"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["calo.dash.remaining"].waitForLabel("Remaining 1,150 calories", timeout: 5))
    }

    @MainActor
    func testTodayLogEditAndDelete() {
        launch()
        app.buttons["calo.header.settings"].tap()
        let row = app.staticTexts["Today’s Log"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        let first = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'calo.log.row.'")).firstMatch
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        first.tap()
        let calories = app.textFields["calo.edit.calories"]
        XCTAssertTrue(calories.waitForExistence(timeout: 5))
        calories.tap()
        calories.clearAndType("425")
        app.buttons["calo.edit.save"].tap()
        let edited = app.buttons
            .matching(NSPredicate(format: "identifier BEGINSWITH 'calo.log.row.' AND label CONTAINS '+425'")).firstMatch
        XCTAssertTrue(edited.waitForExistence(timeout: 5))
        // Delete both rows → empty state.
        for _ in 0 ..< 2 {
            let target = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'calo.log.row.'")).firstMatch
            XCTAssertTrue(target.waitForExistence(timeout: 5))
            target.swipeLeft()
            let delete = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH 'calo.log.delete.'"))
                .firstMatch
            XCTAssertTrue(delete.waitForExistence(timeout: 5))
            delete.tap()
        }
        XCTAssertTrue(app.staticTexts["calo.log.empty"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testClearDailyLogTwoTap() {
        launch()
        app.buttons["calo.header.settings"].tap()
        let clear = app.buttons["calo.settings.clear"]
        XCTAssertTrue(clear.waitForExistence(timeout: 5))
        clear.tap()
        XCTAssertTrue(app.buttons["Tap to confirm removal"].waitForExistence(timeout: 3))
        app.buttons["Tap to confirm removal"].tap()
        XCTAssertTrue(app.buttons["Daily log cleared"].waitForExistence(timeout: 5))
        app.buttons["calo.settings.done"].tap()
        XCTAssertTrue(app.otherElements["calo.dash.logged"].waitForLabel("Logged 0 calories", timeout: 5))
        XCTAssertEqual(dash("remaining"), "Remaining 2,000 calories")
    }

    @MainActor
    func testAboutPage() {
        launch()
        app.buttons["calo.header.settings"].tap()
        let row = app.staticTexts["About"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.staticTexts["Simplicity is sophistication."].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["And 3-second calorie logging rocks."].exists)
    }

    @MainActor
    func testAccessibilityAudit() throws {
        launch()
        // Contrast is excluded on glass screens (design/liquid-glass.md principle 12; measured values in PROGRESS.md).
        try app.performAccessibilityAudit(for: .all.subtracting(.contrast))
        app.buttons["calo.header.settings"].tap()
        XCTAssertTrue(app.switches["calo.settings.showName"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit(for: .all.subtracting(.contrast))
    }
}

extension XCUIElement {
    /// Polls the label until it matches, because the dash rolls to its value.
    func waitForLabel(_ expected: String, timeout: TimeInterval) -> Bool {
        let predicate = NSPredicate(format: "label == %@", expected)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: self)
        return XCTWaiter().wait(for: [expectation], timeout: timeout) == .completed
    }

    func clearAndType(_ text: String) {
        guard let current = value as? String, !current.isEmpty else {
            typeText(text)
            return
        }
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count + 1))
        typeText(text)
    }
}
