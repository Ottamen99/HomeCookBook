import SwiftUI
import CoreData

class PantryViewModel: ObservableObject {
    @Published private(set) var availableRecipes: [Recipe] = []
    @Published private(set) var almostAvailableRecipes: [(recipe: Recipe, missing: [RecipeIngredient])] = []
    
    private let viewContext: NSManagedObjectContext
    
    init(viewContext: NSManagedObjectContext) {
        self.viewContext = viewContext
        updateRecipeAvailability()
    }
    
    func updateRecipeAvailability() {
        let request = Recipe.defaultFetchRequest
        let recipes = (try? viewContext.fetch(request)) ?? []
        
        let pantryRequest = PantryIngredient.defaultFetchRequest
        let pantryIngredients = (try? viewContext.fetch(pantryRequest)) ?? []
        
        // Update available recipes
        availableRecipes = recipes.filter { recipe in
            let requiredIngredients = recipe.recipeIngredientsArray
            return requiredIngredients.allSatisfy { recipeIngredient in
                guard let ingredient = recipeIngredient.ingredient else { return false }
                return pantryIngredients.contains { pantryIngredient in
                    pantryIngredient.ingredient == ingredient &&
                    pantryIngredient.quantity >= recipeIngredient.quantity &&
                    pantryIngredient.unit == recipeIngredient.unit
                }
            }
        }
        
        // Update almost available recipes
        almostAvailableRecipes = recipes.compactMap { recipe in
            let requiredIngredients = recipe.recipeIngredientsArray
            let missingIngredients = requiredIngredients.filter { recipeIngredient in
                guard let ingredient = recipeIngredient.ingredient else { return false }
                return !pantryIngredients.contains { pantryIngredient in
                    pantryIngredient.ingredient == ingredient &&
                    pantryIngredient.quantity >= recipeIngredient.quantity &&
                    pantryIngredient.unit == recipeIngredient.unit
                }
            }
            
            if missingIngredients.count > 0 && missingIngredients.count <= 3 {
                return (recipe: recipe, missing: missingIngredients)
            }
            return nil
        }
    }
} 