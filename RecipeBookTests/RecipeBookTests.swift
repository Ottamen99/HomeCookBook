import XCTest
@testable import RecipeBook
import CoreData

class RecipeBookTests: XCTestCase {
    var mockContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        try super.setUpWithError()
        mockContext = TestCoreDataStack.managedObjectContext
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        mockContext = nil
        try super.tearDownWithError()
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        XCTAssertEqual(2 + 2, 4)
    }

    func testCoreDataStackInitialization() throws {
        XCTAssertNotNil(mockContext, "The mock NSManagedObjectContext should not be nil after setUp.")
    }
}
