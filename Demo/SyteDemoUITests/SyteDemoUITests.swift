import XCTest

/// Walks through the demo and keeps a screenshot of every step in the test results.
/// Runs on sample products, or on a real account when SYTE_ACCOUNT_ID and SYTE_API_KEY are set
/// (for xcodebuild, pass them as TEST_RUNNER_SYTE_ACCOUNT_ID and TEST_RUNNER_SYTE_API_KEY).
final class SyteDemoUITests: XCTestCase {

    private var app: XCUIApplication!
    private var query = "shirt"

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        let env = ProcessInfo.processInfo.environment
        for key in ["SYTE_ACCOUNT_ID", "SYTE_API_KEY", "SYTE_LOCALE"] {
            if let value = env[key] { app.launchEnvironment[key] = value }
        }
        query = env["SYTE_TEST_QUERY"] ?? query
        app.launch()
    }

    func testSearchProductPageAndSimilarLooks() {
        let field = app.textFields["syte.search.field"]
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        field.typeText(String(query.prefix(3)))
        sleep(2)
        snapshot("search-suggestions")

        field.typeText(String(query.dropFirst(3)) + "\n")
        let firstResult = app.buttons["syte.product"].firstMatch
        XCTAssertTrue(firstResult.waitForExistence(timeout: 20))
        sleep(2)
        snapshot("search-results")

        firstResult.tap()
        XCTAssertTrue(app.staticTexts["Similar items"].waitForExistence(timeout: 20))
        sleep(2)
        snapshot("product-page")
        app.swipeUp()
        sleep(2)
        snapshot("product-page-rows")

        app.swipeDown()
        app.buttons["Find similar looks"].tap()
        XCTAssertTrue(app.buttons["syte.marker"].firstMatch.waitForExistence(timeout: 30))
        sleep(3)
        snapshot("similar-looks")
    }

    func testPhotoSearchFromLibrary() {
        app.tabBars.buttons["Photo"].tap()
        XCTAssertTrue(app.buttons["Choose photo"].waitForExistence(timeout: 10))
        snapshot("photo-prompt")

        // The photo picker runs outside the app, so its photos can't be queried. Tap where the
        // newest one sits, top left. Add one first with: xcrun simctl addmedia booted photo.jpg
        app.buttons["Choose photo"].tap()
        sleep(12)
        snapshot("photo-picker")
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.16, dy: 0.44)).tap()
        XCTAssertTrue(app.buttons["syte.marker"].firstMatch.waitForExistence(timeout: 30))
        sleep(3)
        snapshot("photo-results")
    }

    func testForYou() {
        app.tabBars.buttons["For you"].tap()
        sleep(5)
        snapshot("for-you")
    }

    private func snapshot(_ name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

}
