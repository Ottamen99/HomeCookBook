import XCTest
import CoreData
@testable import RecipeBook

class PantryViewModelTests: XCTestCase {

    var sut: PantryViewModel!
    var mockContext: NSManagedObjectContext!
    var recipeViewModel: RecipeViewModel! // For creating test data

    // Pre-created entities for convenience
    var flour: Ingredient!
    var sugar: Ingredient!
    var eggs: Ingredient!
    var milk: Ingredient!
    var butter: Ingredient!

    var cakeRecipe: Recipe!
    var pancakeRecipe: Recipe!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockContext = TestCoreDataStack.managedObjectContext
        sut = PantryViewModel(viewContext: mockContext)
        recipeViewModel = RecipeViewModel(viewContext: mockContext) // Initialize recipeViewModel

        // Setup common ingredients
        flour = createIngredient(name: "Flour", desc: "All-purpose flour")
        sugar = createIngredient(name: "Sugar", desc: "White granulated sugar")
        eggs = createIngredient(name: "Eggs", desc: "Large eggs")
        milk = createIngredient(name: "Milk", desc: "Whole milk")
        butter = createIngredient(name: "Butter", desc: "Unsalted butter")

        // Setup common recipes
        cakeRecipe = createRecipe(
            name: "Simple Cake",
            description: "A simple vanilla cake",
            timeInMinutes: 60,
            servings: 8,
            ingredients: [
                (ingredient: flour, quantity: 200, unit: "g", comments: "Sifted"),
                (ingredient: sugar, quantity: 150, unit: "g", comments: "Fine"),
                (ingredient: eggs, quantity: 3, unit: "pieces", comments: "Room temperature"),
                (ingredient: milk, quantity: 120, unit: "ml", comments: "Any kind"),
                (ingredient: butter, quantity: 100, unit: "g", comments: "Melted")
            ]
        )

        pancakeRecipe = createRecipe(
            name: "Fluffy Pancakes",
            description: "Classic fluffy pancakes",
            timeInMinutes: 20,
            servings: 4,
            ingredients: [
                (ingredient: flour, quantity: 150, unit: "g"),
                (ingredient: eggs, quantity: 1, unit: "piece"),
                (ingredient: milk, quantity: 200, unit: "ml"),
                (ingredient: sugar, quantity: 25, unit: "g", comments: "Optional")
            ]
        )

        // Clear pantry before each test by default
        clearPantry()
        sut.updateRecipeAvailability() // Initial update with empty pantry
    }

    override func tearDownWithError() throws {
        sut = nil
        recipeViewModel = nil
        mockContext = nil // This will deallocate the in-memory store
        flour = nil
        sugar = nil
        eggs = nil
        milk = nil
        butter = nil
        cakeRecipe = nil
        pancakeRecipe = nil
        try super.tearDownWithError()
    }

    // MARK: - Helper Methods for Test Data Creation

    @discardableResult
    private func createIngredient(name: String, desc: String) -> Ingredient {
        recipeViewModel.addIngredient(name: name, description: desc)
        let fetchRequest = NSFetchRequest<Ingredient>(entityName: "Ingredient")
        fetchRequest.predicate = NSPredicate(format: "name == %@", name)
        do {
            let results = try mockContext.fetch(fetchRequest)
            if let ingredient = results.first {
                return ingredient
            } else {
                XCTFail("Failed to create or find ingredient: \(name)")
                fatalError("Failed to create or find ingredient: \(name)")
            }
        } catch {
            XCTFail("Error fetching ingredient \(name): \(error)")
            fatalError("Error fetching ingredient \(name): \(error)")
        }
    }

    @discardableResult
    private func createRecipe(name: String, description: String, timeInMinutes: Int16, servings: Int16, ingredients: [(ingredient: Ingredient, quantity: Double, unit: String, comments: String? = nil)]) -> Recipe {
        recipeViewModel.addRecipe(name: name, description: description, timeInMinutes: timeInMinutes, servings: servings, imageData: nil)
        guard let newRecipe = recipeViewModel.lastAddedRecipe else {
            XCTFail("Failed to create recipe: \(name)")
            fatalError("Failed to create recipe: \(name)")
        }

        for ing in ingredients {
            recipeViewModel.addRecipeIngredient(recipe: newRecipe, ingredient: ing.ingredient, quantity: ing.quantity, unit: ing.unit, comments: ing.comments)
        }

        // Refetch to ensure relationships are updated
         let fetchRequest = NSFetchRequest<Recipe>(entityName: "Recipe")
        fetchRequest.predicate = NSPredicate(format: "id == %@", newRecipe.id! as CVarArg)
        do {
            let results = try mockContext.fetch(fetchRequest)
            if let recipe = results.first {
                return recipe
            } else {
                XCTFail("Failed to re-fetch recipe: \(name)")
                fatalError("Failed to re-fetch recipe: \(name)")
            }
        } catch {
             XCTFail("Error re-fetching recipe \(name): \(error)")
             fatalError("Error re-fetching recipe \(name): \(error)")
        }
    }

    @discardableResult
    private func addPantryIngredient(ingredient: Ingredient, quantity: Double, unit: String, purchaseDate: Date = Date(), expiryDate: Date? = nil) -> PantryIngredient {
        let pantryIngredient = PantryIngredient(context: mockContext)
        pantryIngredient.id = UUID()
        pantryIngredient.ingredient = ingredient
        pantryIngredient.quantity = quantity
        pantryIngredient.unit = unit
        pantryIngredient.purchaseDate = purchaseDate
        pantryIngredient.expiryDate = expiryDate

        try! mockContext.save()
        return pantryIngredient
    }

    private func clearPantry() {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "PantryIngredient")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        try? mockContext.execute(deleteRequest)
        try? mockContext.save()
    }

    // MARK: - Test Cases

    func testUpdateRecipeAvailability_noPantryIngredients() {
        // Cake recipe requires 5 ingredients. No pantry ingredients added yet.
        sut.updateRecipeAvailability()

        XCTAssertTrue(sut.availableRecipes.isEmpty, "Available recipes should be empty when pantry is empty.")

        // Check if cakeRecipe is in almostAvailableRecipes
        let almostCake = sut.almostAvailableRecipes.first { $0.recipe == cakeRecipe }
        XCTAssertNotNil(almostCake, "Cake recipe should be in almost available if it has missing ingredients <= threshold (default 3).")
        XCTAssertEqual(almostCake?.missing.count, cakeRecipe.recipeIngredientsArray.count, "All ingredients should be missing for cake recipe.")
    }

    func testUpdateRecipeAvailability_exactMatch() {
        // Setup pantry to exactly match pancakeRecipe requirements
        addPantryIngredient(ingredient: flour, quantity: 150, unit: "g")
        addPantryIngredient(ingredient: eggs, quantity: 1, unit: "piece")
        addPantryIngredient(ingredient: milk, quantity: 200, unit: "ml")
        addPantryIngredient(ingredient: sugar, quantity: 25, unit: "g") // Optional, but let's match it

        sut.updateRecipeAvailability()

        XCTAssertEqual(sut.availableRecipes.count, 1, "There should be one available recipe.")
        XCTAssertTrue(sut.availableRecipes.contains(pancakeRecipe), "Pancake recipe should be available.")
        XCTAssertTrue(sut.almostAvailableRecipes.isEmpty, "Almost available recipes should be empty.")
    }

    func testUpdateRecipeAvailability_partialMatch_almostAvailable() {
        // Pancake recipe: Flour, Eggs, Milk, Sugar (optional)
        // Add 2 of 3 non-optional ingredients for pancakeRecipe
        addPantryIngredient(ingredient: flour, quantity: 150, unit: "g")
        addPantryIngredient(ingredient: milk, quantity: 200, unit: "ml")
        // Missing Eggs (and optional Sugar)

        sut.updateRecipeAvailability()

        XCTAssertTrue(sut.availableRecipes.isEmpty, "No recipes should be fully available.")
        XCTAssertEqual(sut.almostAvailableRecipes.count, 1, "There should be one almost available recipe.")

        guard let almostPancake = sut.almostAvailableRecipes.first else {
            XCTFail("Pancake recipe should be in almost available.")
            return
        }
        XCTAssertEqual(almostPancake.recipe, pancakeRecipe)

        // Expecting "Eggs" to be missing. "Sugar" is optional in this test model's setup or we add it as non-optional.
        // The current logic will count all non-matched RecipeIngredients.
        // Pancake ingredients: flour, eggs, milk, sugar. We have flour, milk. Missing: eggs, sugar. That's 2.
        let missingIngredientNames = almostPancake.missing.compactMap { $0.ingredient?.name }
        XCTAssertEqual(almostPancake.missing.count, 2, "Should be 2 missing ingredients (Eggs, Sugar).")
        XCTAssertTrue(missingIngredientNames.contains("Eggs"))
        XCTAssertTrue(missingIngredientNames.contains("Sugar"))
    }

    func testUpdateRecipeAvailability_partialMatch_almostAvailable_oneMissing() {
        // Pancake recipe: Flour, Eggs, Milk, Sugar
        addPantryIngredient(ingredient: flour, quantity: 150, unit: "g")
        addPantryIngredient(ingredient: milk, quantity: 200, unit: "ml")
        addPantryIngredient(ingredient: sugar, quantity: 25, unit: "g")
        // Missing Eggs

        sut.updateRecipeAvailability()

        XCTAssertTrue(sut.availableRecipes.isEmpty, "No recipes should be fully available.")
        XCTAssertEqual(sut.almostAvailableRecipes.count, 1, "There should be one almost available recipe.")

        guard let almostPancake = sut.almostAvailableRecipes.first else {
            XCTFail("Pancake recipe should be in almost available.")
            return
        }
        XCTAssertEqual(almostPancake.recipe, pancakeRecipe)
        XCTAssertEqual(almostPancake.missing.count, 1, "Should be 1 missing ingredient (Eggs).")
        XCTAssertEqual(almostPancake.missing.first?.ingredient?.name, "Eggs")
    }


    func testUpdateRecipeAvailability_partialMatch_tooManyMissing() {
        // Cake recipe has 5 ingredients. Add only 1.
        addPantryIngredient(ingredient: flour, quantity: 200, unit: "g") // Only flour for the cake

        sut.updateRecipeAvailability()

        XCTAssertTrue(sut.availableRecipes.isEmpty, "Available recipes should be empty.")
        // Cake recipe has 5 ingredients. 1 is present, 4 are missing.
        // Default threshold for 'almost available' is 3 missing ingredients.
        // So, if 4 are missing, it should not be in 'almostAvailableRecipes'.
        let almostCake = sut.almostAvailableRecipes.first { $0.recipe == cakeRecipe }
        XCTAssertNil(almostCake, "Cake recipe should not be in almost available if too many ingredients are missing.")

    }

    func testUpdateRecipeAvailability_sufficientQuantity() {
        // Pancake recipe requires 150g Flour. We add 200g.
        addPantryIngredient(ingredient: flour, quantity: 200, unit: "g")
        addPantryIngredient(ingredient: eggs, quantity: 1, unit: "piece")
        addPantryIngredient(ingredient: milk, quantity: 200, unit: "ml")
        addPantryIngredient(ingredient: sugar, quantity: 25, unit: "g")

        sut.updateRecipeAvailability()

        XCTAssertTrue(sut.availableRecipes.contains(pancakeRecipe), "Pancake recipe should be available with sufficient quantity.")
    }

    func testUpdateRecipeAvailability_insufficientQuantity() {
        // Pancake recipe requires 150g Flour. We add only 100g.
        addPantryIngredient(ingredient: flour, quantity: 100, unit: "g") // Insufficient
        addPantryIngredient(ingredient: eggs, quantity: 1, unit: "piece")
        addPantryIngredient(ingredient: milk, quantity: 200, unit: "ml")
        addPantryIngredient(ingredient: sugar, quantity: 25, unit: "g")

        sut.updateRecipeAvailability()

        XCTAssertFalse(sut.availableRecipes.contains(pancakeRecipe), "Pancake recipe should not be available with insufficient quantity.")

        let almostPancake = sut.almostAvailableRecipes.first { $0.recipe == pancakeRecipe }
        XCTAssertNotNil(almostPancake, "Pancake recipe should be in almost available.")
        XCTAssertEqual(almostPancake?.missing.count, 1, "One ingredient (Flour) should be marked as missing due to quantity.")
        XCTAssertEqual(almostPancake?.missing.first?.ingredient, flour, "Flour should be the missing ingredient.")
    }

    func testUpdateRecipeAvailability_unitMismatch() {
        // Pancake recipe requires 150g Flour. We add 150 "kg" Flour.
        addPantryIngredient(ingredient: flour, quantity: 150, unit: "kg") // Unit mismatch
        addPantryIngredient(ingredient: eggs, quantity: 1, unit: "piece")
        addPantryIngredient(ingredient: milk, quantity: 200, unit: "ml")
        addPantryIngredient(ingredient: sugar, quantity: 25, unit: "g")

        sut.updateRecipeAvailability()

        XCTAssertFalse(sut.availableRecipes.contains(pancakeRecipe), "Pancake recipe should not be available with unit mismatch.")

        let almostPancake = sut.almostAvailableRecipes.first { $0.recipe == pancakeRecipe }
        XCTAssertNotNil(almostPancake, "Pancake recipe should be in almost available due to unit mismatch.")
        XCTAssertEqual(almostPancake?.missing.count, 1, "One ingredient (Flour) should be marked as missing due to unit.")
        XCTAssertEqual(almostPancake?.missing.first?.ingredient, flour, "Flour should be the missing ingredient due to unit mismatch.")
    }

    func testUpdateRecipeAvailability_ingredientNameMismatch_notAvailable() {
        // Create a new ingredient not in any recipe
        let salt = createIngredient(name: "Salt", desc: "Table salt")
        addPantryIngredient(ingredient: salt, quantity: 100, unit: "g") // This is in pantry but not in pancakeRecipe

        // Add other ingredients for pancake recipe correctly
        addPantryIngredient(ingredient: eggs, quantity: 1, unit: "piece")
        addPantryIngredient(ingredient: milk, quantity: 200, unit: "ml")
        addPantryIngredient(ingredient: sugar, quantity: 25, unit: "g")
        // Missing "Flour" for pancakeRecipe

        sut.updateRecipeAvailability()

        XCTAssertFalse(sut.availableRecipes.contains(pancakeRecipe), "Pancake recipe should not be available if a required ingredient (Flour) is missing, even if other non-related ingredients (Salt) are present.")
        let almostPancake = sut.almostAvailableRecipes.first { $0.recipe == pancakeRecipe }
        XCTAssertNotNil(almostPancake)
        XCTAssertEqual(almostPancake?.missing.count, 1) // Flour is missing
        XCTAssertEqual(almostPancake?.missing.first?.ingredient, flour)
    }
}
