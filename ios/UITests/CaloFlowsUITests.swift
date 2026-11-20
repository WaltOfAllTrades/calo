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
        XCTAssertEqual(app.staticTexts["calo.display.buffer"].value as? String, "250")
        tap("enter")
        let logged = app.otherElements["calo.dash.logged"]
        XCTAssertTrue(logged.waitForLabel("Logged 600 calories", timeout: 5))
        XCTAssertEqual(dash("remaining"), "Remaining 1,400 calories")
        XCTAssertEqual(app.staticTexts["calo.display.buffer"].value as? String, "")
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
        XCTAssertEqual(app.staticTexts["calo.display.buffer"].value as? String, "8080")
        tap("backspace")
        XCTAssertEqual(app.staticTexts["calo.display.buffer"].value as? String, "808")
        tap("clear")
        XCTAssertEqual(app.staticTexts["calo.display.buffer"].value as? String, "")
    }

    @MainActor
    func testSettingsFieldsAndTarget() {
        launch()
        app.buttons["calo.header.settings"].tap()
        let toggle = app.switches["calo.settings.showName"]
        XCTAssertTrue(toggle.waitForExistence(timeout: 5))
        app.swipeUp() // full height: the target row sits below the medium detent's fold
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
        // The control sits in the sheet's bottom inset; inside a sheet it may not be typed as a button.
        let clear = app.descendants(matching: .any)["calo.settings.clear"]
        XCTAssertTrue(clear.waitForExistence(timeout: 5))
        clear.tap()
        // The button carries an identifier, so its label is matched by predicate, not by subscript.
        let armed = app.descendants(matching: .any).matching(NSPredicate(
            format: "label == %@",
            "Tap to confirm removal"
        )).firstMatch
        XCTAssertTrue(armed.waitForExistence(timeout: 3), "the first tap did not arm the button")
        armed.tap()
        // The done label shows for 1.2 s and then the control goes; either proves the second tap landed.
        let done = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "Daily log cleared")).firstMatch
        XCTAssertTrue(done.waitForExistence(timeout: 2) || clear.waitForNonExistence(timeout: 5))
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
        Thread.sleep(forTimeInterval: 1.5) // let the launch animations settle before measuring
        // Contrast is excluded on glass screens (design/liquid-glass.md principle 12; measured values in PROGRESS.md).
        // The keypad labels are capped at the accessibility1 size by the spec (E-C15), which the Dynamic Type
        // rule reads as unsupported; the rule stays on for the settings screen below.
        try app.performAccessibilityAudit(for: .all.subtracting([.contrast, .dynamicType]), logging)
        app.buttons["calo.header.settings"].tap()
        XCTAssertTrue(app.switches["calo.settings.showName"].waitForExistence(timeout: 5))
        // At the medium detent the main screen shows through the sheet and its covered text trips the
        // element-detection rule; the audit runs with the sheet raised to its full height.
        app.swipeUp()
        Thread.sleep(forTimeInterval: 1)
        try app.performAccessibilityAudit(for: .all.subtracting(.contrast), logging)
    }
}

/// Prints every audit issue with the element it names, so a failure in the log says what to fix.
/// Returns false: the issue still counts.
@MainActor
func logging(_ issue: XCUIAccessibilityAuditIssue) -> Bool {
    print("AUDIT \(issue.auditType.rawValue) \(issue.compactDescription): \(issue.element?.debugDescription ?? "?")")
    if issue.element == nil {
        let app = XCUIApplication()
        print("AUDIT texts: \(app.staticTexts.allElementsBoundByIndex.map(\.label))")
        let buttons = app.buttons.allElementsBoundByIndex.map { "\($0.identifier)|\($0.label)" }
        print("AUDIT buttons: \(buttons)")
        let others = app.otherElements.allElementsBoundByIndex.prefix(40).map { "\($0.identifier)|\($0.label)" }
        print("AUDIT others: \(others)")
    }
    return false
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
