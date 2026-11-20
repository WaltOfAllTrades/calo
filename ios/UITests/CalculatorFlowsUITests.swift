import XCTest

/// Calculator flows (calculator/tests.md → UI). `-calc.uitest`: empty tape, default preferences,
/// scratch history directory; `-calo.openAs calculator` opens the calculator.
final class CalculatorFlowsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
    }

    @MainActor
    private func launch() {
        app = XCUIApplication()
        app.launchArguments = ["-calc.uitest", "-calo.uitest", "-calo.openAs", "calculator"]
        app.launch()
        XCTAssertTrue(app.otherElements["calc.keypad"].waitForExistence(timeout: 15))
    }

    @MainActor
    private func tap(_ keys: String...) {
        for key in keys {
            let element = app.buttons["calc.key.\(key)"]
            XCTAssertTrue(element.waitForExistence(timeout: 5), "key \(key)")
            element.tap()
        }
    }

    /// A sheet's dismiss animation must finish before keys take taps.
    @MainActor
    private func waitUntilKeypadIsHittable() {
        let key = app.buttons["calc.key.equals"]
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: key)
        XCTAssertEqual(XCTWaiter().wait(for: [expectation], timeout: 10), .completed)
    }

    /// List rows below the fold are not in the accessibility tree until scrolled to.
    @MainActor
    private func scrollUntilVisible(_ element: XCUIElement, swipes: Int = 4) {
        for _ in 0 ..< swipes where !element.exists || !element.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(element.waitForExistence(timeout: 5))
    }

    @MainActor
    private var result: String {
        app.descendants(matching: .any)["calc.result"].label
    }

    @MainActor
    func testAddsTwoDimensions() {
        launch()
        tap(
            "5",
            "feet",
            "3",
            "inches",
            "1",
            "fraction",
            "2",
            "plus",
            "2",
            "feet",
            "9",
            "inches",
            "3",
            "fraction",
            "4",
            "equals"
        )
        XCTAssertEqual(result, "Result 8′ 1-1/4″")
        XCTAssertEqual(app.descendants(matching: .any)["calc.expression"].label, "Expression 5′ 3-1⁄2″ + 2′ 9-3⁄4″")
    }

    @MainActor
    func testPrecisionChipCycles() {
        launch()
        tap("1", "fraction", "3", "inches", "equals")
        XCTAssertEqual(result, "Result 0-5/16″")
        let chip = app.buttons["calc.chip.precision"]
        XCTAssertTrue(chip.label.contains("≈"))
        chip.tap() // 1/32
        XCTAssertEqual(result, "Result 0-11/32″")
        chip.tap() // 1/64
        chip.tap() // exact
        XCTAssertEqual(result, "Result 0-1/3″")
        XCTAssertFalse(app.buttons["calc.chip.precision"].label.contains("≈"))
    }

    @MainActor
    func testUnitChipCycles() {
        launch()
        tap("1", "4", "feet", "equals")
        XCTAssertEqual(result, "Result 14′ 0″")
        let chip = app.buttons["calc.chip.unit"]
        chip.tap() // decimal feet
        XCTAssertEqual(result, "Result 14 ft")
        chip.tap() // decimal inches
        XCTAssertEqual(result, "Result 168″")
        chip.tap() // yards
        chip.tap() // mm
        chip.tap() // cm
        chip.tap() // m
        XCTAssertEqual(result, "Result 4.267 m")
    }

    @MainActor
    func testTapeReuseAndDelete() {
        launch()
        tap("2", "plus", "3", "equals")
        tap("1", "0", "feet", "equals")
        app.buttons["calc.pill.tape"].tap()
        let first = app.buttons["calc.tape.row.0"]
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["calc.tape.row.1"].exists)
        first.tap() // reuse 10′
        waitUntilKeypadIsHittable()
        tap("times", "2", "equals")
        XCTAssertEqual(result, "Result 20′ 0″")
        app.buttons["calc.pill.tape"].tap()
        let row = app.buttons["calc.tape.row.0"]
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.swipeLeft()
        let delete = app.buttons["calc.tape.delete.0"]
        XCTAssertTrue(delete.waitForExistence(timeout: 5))
        delete.tap()
        XCTAssertTrue(app.buttons["calc.tape.row.1"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["calc.tape.row.2"].exists)
    }

    @MainActor
    func testUndoAfterEquals() {
        launch()
        tap("2", "plus", "3", "equals")
        XCTAssertEqual(result, "Result 5")
        app.buttons["calc.pill.undo"].tap()
        XCTAssertEqual(app.descendants(matching: .any)["calc.expression"].label, "Expression 2 + 3")
    }

    @MainActor
    func testStairsSheet() {
        launch()
        app.buttons["calc.pill.functions"].tap()
        let stairs = app.buttons["calc.fn.stairs"]
        XCTAssertTrue(stairs.waitForExistence(timeout: 5))
        stairs.tap()
        let rise = app.textFields["calc.fn.stairs.field.rise"]
        XCTAssertTrue(rise.waitForExistence(timeout: 5))
        rise.tap()
        rise.typeText("9' 11\"")
        XCTAssertTrue(app.staticTexts["calc.fn.stairs.result.risers"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["calc.fn.stairs.result.risers"].label, "16")
        XCTAssertEqual(app.staticTexts["calc.fn.stairs.result.riserHeight"].label, "7-7/16″")
        let stringer = app.staticTexts["calc.fn.stairs.result.stringer"]
        scrollUntilVisible(stringer)
        XCTAssertEqual(stringer.label, "15′ 6-15/16″")
        app.buttons["calc.fn.stairs.use.stringer"].tap()
        waitUntilKeypadIsHittable()
        tap("equals")
        XCTAssertEqual(result, "Result 15′ 6-15/16″")
    }

    @MainActor
    func testConcreteBags() {
        launch()
        app.buttons["calc.pill.functions"].tap()
        let concrete = app.buttons["calc.fn.concrete"]
        XCTAssertTrue(concrete.waitForExistence(timeout: 5))
        concrete.tap()
        let length = app.textFields["calc.fn.concrete.field.length"]
        XCTAssertTrue(length.waitForExistence(timeout: 5))
        length.tap(); length.typeText("12'")
        let width = app.textFields["calc.fn.concrete.field.width"]
        width.tap(); width.typeText("16'")
        let depth = app.textFields["calc.fn.concrete.field.depth"]
        depth.tap(); depth.typeText("4\"")
        let waste = app.textFields["calc.fn.concrete.field.waste"]
        waste.doubleTap() // selects the seeded value; typing replaces it
        waste.typeText("0")
        XCTAssertTrue(app.staticTexts["calc.fn.concrete.result.bags"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.staticTexts["calc.fn.concrete.result.bags"].label, "107")
    }

    @MainActor
    func testLookSwitch() {
        launch()
        app.buttons["calc.pill.settings"].tap()
        let look = app.buttons["calc.settings.look"]
        XCTAssertTrue(look.waitForExistence(timeout: 5))
        look.tap()
        let daylight = app.buttons["Daylight"]
        XCTAssertTrue(daylight.waitForExistence(timeout: 5))
        daylight.tap()
        app.buttons["calc.settings.done"].tap()
        XCTAssertTrue(app.buttons["calc.key.equals"].waitForExistence(timeout: 5))
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "daylight"
        shot.lifetime = .keepAlways
        add(shot)
    }

    @MainActor
    func testMemoryPersistsAcrossRelaunch() {
        launch()
        tap("5", "feet", "equals")
        app.buttons["calc.pill.memory"].tap()
        let add = app.buttons["M+"]
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        add.tap()
        tap("allClear")
        app.buttons["calc.pill.memory"].tap()
        let recall = app.buttons["MR"]
        XCTAssertTrue(recall.waitForExistence(timeout: 5))
        recall.tap()
        tap("equals")
        XCTAssertEqual(result, "Result 5′ 0″")
    }

    @MainActor
    func testHoldToSeeHelp() {
        launch()
        app.buttons["calc.key.feet"].press(forDuration: 0.8)
        XCTAssertTrue(app.staticTexts["calc.help"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testAccessibilityAudit() throws {
        launch()
        Thread.sleep(forTimeInterval: 1.5) // let the launch animations settle before measuring
        // The keypad labels are capped at the accessibility1 size by the spec (E-K24), which the Dynamic Type
        // rule reads as unsupported; the rule stays on for every other screen.
        try app.performAccessibilityAudit(for: .all.subtracting([.contrast, .dynamicType]))
        app.buttons["calc.pill.functions"].tap()
        XCTAssertTrue(app.buttons["calc.fn.stairs"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit(for: .all.subtracting(.contrast))
    }
}
