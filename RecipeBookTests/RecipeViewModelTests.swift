import XCTest
import CoreData
@testable import RecipeBook

class RecipeViewModelTests: XCTestCase {

    var sut: RecipeViewModel!
    var mockContext: NSManagedObjectContext!

    override func setUpWithError() throws {
        try super.setUpWithError()
        mockContext = TestCoreDataStack.managedObjectContext
        sut = RecipeViewModel(viewContext: mockContext)
    }

    override func tearDownWithError() throws {
        sut = nil
        mockContext = nil
        try super.tearDownWithError()
    }

    // Helper method to fetch entities
    private func fetchEntities<T: NSManagedObject>(entityName: String, context: NSManagedObjectContext) -> [T] {
        let fetchRequest = NSFetchRequest<T>(entityName: entityName)
        do {
            return try context.fetch(fetchRequest)
        } catch {
            XCTFail("Failed to fetch entities of type \(entityName): \(error)")
            return []
        }
    }

    func testAddRecipe() {
        sut.addRecipe(name: "Test Recipe", description: "Test Desc", timeInMinutes: 30, servings: 4)

        let recipes: [Recipe] = fetchEntities(entityName: "Recipe", context: mockContext)
        XCTAssertEqual(recipes.count, 1, "There should be one recipe in the context.")

        guard let recipe = recipes.first else {
            XCTFail("Recipe object not found.")
            return
        }

        XCTAssertEqual(recipe.name, "Test Recipe")
        XCTAssertEqual(recipe.desc, "Test Desc")
        XCTAssertEqual(recipe.timeInMinutes, 30)
        XCTAssertEqual(recipe.servings, 4)
        XCTAssertNotNil(recipe.id, "Recipe ID should not be nil")

        XCTAssertNotNil(sut.lastAddedRecipe, "lastAddedRecipe should be set on the view model.")
        XCTAssertEqual(sut.lastAddedRecipe, recipe, "lastAddedRecipe should be the recipe that was just added.")
    }

    func testAddIngredient() {
        sut.addIngredient(name: "Test Ingredient", description: "Test Ing Desc")

        let ingredients: [Ingredient] = fetchEntities(entityName: "Ingredient", context: mockContext)
        XCTAssertEqual(ingredients.count, 1, "There should be one ingredient in the context.")

        guard let ingredient = ingredients.first else {
            XCTFail("Ingredient object not found.")
            return
        }

        XCTAssertEqual(ingredient.name, "Test Ingredient")
        XCTAssertEqual(ingredient.desc, "Test Ing Desc")
        XCTAssertNotNil(ingredient.id, "Ingredient ID should not be nil")
    }

    func testAddRecipeIngredient() {
        // 1. Create a Recipe
        let recipeName = "Pasta Carbonara"
        sut.addRecipe(name: recipeName, description: "Classic Italian pasta dish", timeInMinutes: 25, servings: 2)
        let recipes: [Recipe] = fetchEntities(entityName: "Recipe", context: mockContext)
        guard let testRecipe = recipes.first(where: { $0.name == recipeName }) else {
            XCTFail("Test Recipe not found after adding.")
            return
        }

        // 2. Create an Ingredient
        let ingredientName = "Eggs"
        sut.addIngredient(name: ingredientName, description: "Fresh farm eggs")
        let ingredients: [Ingredient] = fetchEntities(entityName: "Ingredient", context: mockContext)
        guard let testIngredient = ingredients.first(where: { $0.name == ingredientName }) else {
            XCTFail("Test Ingredient not found after adding.")
            return
        }

        // 3. Add RecipeIngredient
        sut.addRecipeIngredient(recipe: testRecipe, ingredient: testIngredient, quantity: 2.0, unit: "pieces")

        let recipeIngredients: [RecipeIngredient] = fetchEntities(entityName: "RecipeIngredient", context: mockContext)
        XCTAssertEqual(recipeIngredients.count, 1, "There should be one RecipeIngredient in the context.")

        guard let recipeIngredient = recipeIngredients.first else {
            XCTFail("RecipeIngredient object not found.")
            return
        }

        XCTAssertEqual(recipeIngredient.recipe, testRecipe, "RecipeIngredient should point to the correct recipe.")
        XCTAssertEqual(recipeIngredient.ingredient, testIngredient, "RecipeIngredient should point to the correct ingredient.")
        XCTAssertEqual(recipeIngredient.quantity, 2.0)
        XCTAssertEqual(recipeIngredient.unit, "pieces")
        XCTAssertNotNil(recipeIngredient.id, "RecipeIngredient ID should not be nil")

        // Verify the relationship from Recipe
        XCTAssertTrue(testRecipe.recipeIngredientsArray.contains(recipeIngredient), "Recipe's ingredients should include the new RecipeIngredient.")
        XCTAssertEqual(testRecipe.recipeIngredientsArray.count, 1)
    }
}
