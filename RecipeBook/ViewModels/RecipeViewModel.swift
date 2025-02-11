import Foundation
import CoreData

class RecipeViewModel: ObservableObject {
    let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
    }
    
    func addRecipe(name: String, description: String, timeInMinutes: Int16, servings: Int16) {
        let recipe = Recipe(context: viewContext)
        recipe.name = name
        recipe.desc = description
        recipe.timeInMinutes = timeInMinutes
        recipe.servings = servings
        
        save()
    }
    
    func addIngredient(name: String, description: String) {
        let ingredient = Ingredient(context: viewContext)
        ingredient.name = name
        ingredient.desc = description
        
        save()
    }
    
    func addRecipeIngredient(recipe: Recipe, ingredient: Ingredient, quantity: Double, unit: String) {
        let recipeIngredient = RecipeIngredient(context: viewContext)
        recipeIngredient.recipe = recipe
        recipeIngredient.ingredient = ingredient
        recipeIngredient.quantity = quantity
        recipeIngredient.unit = unit
        
        save()
    }
    
    func save() {
        do {
            try viewContext.save()
        } catch {
            print("Error saving context: \(error)")
        }
    }
} 