import CoreData
@testable import RecipeBook // To access PersistenceController

struct TestCoreDataStack {
    /// Provides a fresh in-memory managed object context for testing.
    static var managedObjectContext: NSManagedObjectContext {
        let controller = PersistenceController(inMemory: true)
        // Optional: You might want to load the model explicitly if it's not done automatically
        // Forcing the schema to be loaded.
        _ = controller.container.persistentStoreCoordinator.managedObjectModel
        return controller.container.viewContext
    }

    /// A convenience static instance of PersistenceController configured for in-memory store.
    /// This can be used if tests need to interact directly with the PersistenceController
    /// or its container.
    static var previewPersistenceController: PersistenceController = {
        PersistenceController(inMemory: true)
    }()
}

// Example of how it might be used in a test:
//
// import XCTest
// @testable import RecipeBook
//
// class MyViewModelTests: XCTestCase {
//     var context: NSManagedObjectContext!
//
//     override func setUpWithError() throws {
//         try super.setUpWithError()
//         context = TestCoreDataStack.managedObjectContext
//         // Additional setup using the context
//     }
//
//     override func tearDownWithError() throws {
//         context = nil
//         try super.tearDownWithError()
//     }
//
//     func testSomething() {
//         // Use self.context for Core Data operations
//     }
// }
