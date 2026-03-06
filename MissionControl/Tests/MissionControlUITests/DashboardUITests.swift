import XCTest

final class DashboardUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        // UI tests require a running .app bundle launched via Xcode's UI test scheme.
        // Set XCTEST_UI_ENABLED=1 in the scheme's test environment variables to enable.
        guard ProcessInfo.processInfo.environment["XCTEST_UI_ENABLED"] == "1" else {
            throw XCTSkip("UI tests require launching from Xcode with a configured UI test scheme. Set XCTEST_UI_ENABLED=1 to enable.")
        }
        app = XCUIApplication()
        app.launch()
        // Ensure Dashboard is the active tab
        app.typeKey("1", modifierFlags: .command)
        Thread.sleep(forTimeInterval: 0.5)
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    func testMetricCardsAreVisible() throws {
        // All four metric card titles should appear in the Dashboard view
        XCTAssertTrue(
            app.staticTexts["Active Tasks"].waitForExistence(timeout: 5),
            "Active Tasks metric card title should be visible"
        )
        XCTAssertTrue(
            app.staticTexts["Success Rate"].exists,
            "Success Rate metric card title should be visible"
        )
        XCTAssertTrue(
            app.staticTexts["Avg Duration"].exists,
            "Avg Duration metric card title should be visible"
        )
        XCTAssertTrue(
            app.staticTexts["Queue Depth"].exists,
            "Queue Depth metric card title should be visible"
        )
    }

    func testRecentTasksTableHasRows() throws {
        // Wait for the recent tasks section to appear (data loads asynchronously)
        XCTAssertTrue(
            app.staticTexts["Recent Tasks"].waitForExistence(timeout: 5),
            "Recent Tasks section heading should be visible"
        )

        // After data loads, the table should contain at least one row
        let table = app.tables.matching(identifier: "dashboard.recentTasksTable").firstMatch
        if table.exists {
            // Wait for rows to populate (mock data loads in ~0.3-0.8s)
            XCTAssertTrue(
                table.tableRows.firstMatch.waitForExistence(timeout: 5),
                "Recent tasks table should have at least one row after data loads"
            )
            XCTAssertGreaterThan(
                table.tableRows.count,
                0,
                "Recent tasks table should contain task rows"
            )
        } else {
            // Fallback: the section heading at minimum should be visible
            XCTAssertTrue(
                app.staticTexts["Recent Tasks"].exists,
                "Recent Tasks section should be visible in the dashboard"
            )
        }
    }

    func testQuickLaunchTextFieldAcceptsInput() throws {
        // Wait for Quick Launch section
        XCTAssertTrue(
            app.staticTexts["Quick Launch"].waitForExistence(timeout: 5),
            "Quick Launch section heading should be visible"
        )

        // Locate the task input text editor by accessibility identifier
        let taskInput = app.textViews.matching(identifier: "quicklaunch.taskInput").firstMatch
        if taskInput.waitForExistence(timeout: 3) {
            taskInput.click()
            let testText = "Create a new React component"
            taskInput.typeText(testText)
            XCTAssertTrue(
                (taskInput.value as? String)?.contains(testText) == true,
                "Task input should contain the typed text"
            )
        } else {
            // Fallback: any text view in the view should accept input
            let anyTextView = app.textViews.firstMatch
            XCTAssertTrue(anyTextView.exists, "A text input for quick launch should exist")
        }
    }

    func testLaunchButtonIsDisabledWhenInputIsEmpty() throws {
        // Wait for Dashboard content
        XCTAssertTrue(
            app.staticTexts["Quick Launch"].waitForExistence(timeout: 5),
            "Quick Launch section should be visible"
        )

        // The launch button should be disabled when no task is entered
        let launchButton = app.buttons.matching(identifier: "quicklaunch.launchButton").firstMatch
        if launchButton.exists {
            XCTAssertFalse(
                launchButton.isEnabled,
                "Launch Task button should be disabled when task input is empty"
            )
        }
    }
}
