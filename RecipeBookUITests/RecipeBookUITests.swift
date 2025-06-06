import XCTest

final class RecipeBookUITests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
    }

    func testExample() throws {
        let app = XCUIApplication()
        app.launch()

        // Example: Assert that the main app view exists or has a certain element.
        // This will depend on the actual UI of RecipeBook.
        // For now, a simple launch and existence check for any element will suffice.
        XCTAssertTrue(app.staticTexts.count > 0 || app.buttons.count > 0, "The app did not launch to a view with interactive elements.")
    }

    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
