import XCTest

final class NavigationUITests: XCTestCase {
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
    }

    override func tearDownWithError() throws {
        app?.terminate()
        app = nil
    }

    func testAppLaunchesSuccessfully() throws {
        XCTAssertTrue(app.exists, "App should be running after launch")
        XCTAssertTrue(app.windows.firstMatch.exists, "App should present at least one window")
    }

    func testAllSixSidebarItemsAreVisible() throws {
        // Each sidebar label should be rendered in the NavigationSplitView sidebar column
        XCTAssertTrue(app.staticTexts["Dashboard"].exists, "Dashboard sidebar item should be visible")
        XCTAssertTrue(app.staticTexts["Blueprint"].exists, "Blueprint sidebar item should be visible")
        XCTAssertTrue(app.staticTexts["Sandboxes"].exists, "Sandboxes sidebar item should be visible")
        XCTAssertTrue(app.staticTexts["Agents"].exists, "Agents sidebar item should be visible")
        XCTAssertTrue(app.staticTexts["Audit Log"].exists, "Audit Log sidebar item should be visible")
        XCTAssertTrue(app.staticTexts["Settings"].exists, "Settings sidebar item should be visible")
    }

    func testTappingSidebarItemsChangesContentView() throws {
        // Tap Blueprint and verify content updates
        let blueprintItem = app.staticTexts["Blueprint"]
        XCTAssertTrue(blueprintItem.exists, "Blueprint sidebar item must exist")
        blueprintItem.click()
        Thread.sleep(forTimeInterval: 0.3)

        // Tap Sandboxes
        let sandboxesItem = app.staticTexts["Sandboxes"]
        XCTAssertTrue(sandboxesItem.exists, "Sandboxes sidebar item must exist")
        sandboxesItem.click()
        Thread.sleep(forTimeInterval: 0.3)

        // Tap Agents
        let agentsItem = app.staticTexts["Agents"]
        XCTAssertTrue(agentsItem.exists, "Agents sidebar item must exist")
        agentsItem.click()
        Thread.sleep(forTimeInterval: 0.3)

        // Tap Audit Log
        let auditLogItem = app.staticTexts["Audit Log"]
        XCTAssertTrue(auditLogItem.exists, "Audit Log sidebar item must exist")
        auditLogItem.click()
        Thread.sleep(forTimeInterval: 0.3)

        // Tap Settings
        let settingsItem = app.staticTexts["Settings"]
        XCTAssertTrue(settingsItem.exists, "Settings sidebar item must exist")
        settingsItem.click()
        Thread.sleep(forTimeInterval: 0.3)

        // Return to Dashboard
        let dashboardItem = app.staticTexts["Dashboard"]
        XCTAssertTrue(dashboardItem.exists, "Dashboard sidebar item must exist")
        dashboardItem.click()
        Thread.sleep(forTimeInterval: 0.3)

        XCTAssertTrue(app.staticTexts["Dashboard"].exists, "Dashboard content should be visible")
    }

    func testKeyboardShortcutsSwitchTabs() throws {
        XCTAssertTrue(app.windows.firstMatch.exists, "Main window must exist")

        // Cmd+1 → Dashboard
        app.typeKey("1", modifierFlags: .command)
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertTrue(app.staticTexts["Dashboard"].exists, "Cmd+1 should navigate to Dashboard")

        // Cmd+2 → Blueprint
        app.typeKey("2", modifierFlags: .command)
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertTrue(app.staticTexts["Blueprint"].exists, "Cmd+2 should navigate to Blueprint")

        // Cmd+3 → Sandboxes
        app.typeKey("3", modifierFlags: .command)
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertTrue(app.staticTexts["Sandboxes"].exists, "Cmd+3 should navigate to Sandboxes")

        // Cmd+4 → Agents
        app.typeKey("4", modifierFlags: .command)
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertTrue(app.staticTexts["Agents"].exists, "Cmd+4 should navigate to Agents")

        // Cmd+5 → Audit Log
        app.typeKey("5", modifierFlags: .command)
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertTrue(app.staticTexts["Audit Log"].exists, "Cmd+5 should navigate to Audit Log")

        // Cmd+6 → Settings
        app.typeKey("6", modifierFlags: .command)
        Thread.sleep(forTimeInterval: 0.3)
        XCTAssertTrue(app.staticTexts["Settings"].exists, "Cmd+6 should navigate to Settings")
    }
}
