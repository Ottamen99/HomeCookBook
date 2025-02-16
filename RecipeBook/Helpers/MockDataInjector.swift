import Foundation
import CoreData
import UIKit

class MockDataInjector {
    static func inject(into context: NSManagedObjectContext) {
        // Create ingredients
        let ingredients: [(name: String, description: String)] = [
            ("All-purpose Flour", "A versatile wheat flour suitable for most baking needs"),
            ("Sugar", "Regular granulated white sugar"),
            ("Eggs", "Fresh chicken eggs"),
            ("Milk", "Whole dairy milk"),
            ("Butter", "Unsalted butter"),
            ("Vanilla Extract", "Pure vanilla extract"),
            ("Baking Powder", "Leavening agent for baking"),
            ("Salt", "Fine table salt"),
            ("Chocolate Chips", "Semi-sweet chocolate chips"),
            ("Olive Oil", "Extra virgin olive oil")
        ]
        
        var ingredientEntities: [Ingredient] = []
        
        for (name, description) in ingredients {
            let ingredient = Ingredient(context: context)
            ingredient.name = name
            ingredient.desc = description
            ingredientEntities.append(ingredient)
        }
        
        // Create recipes with images
        let recipes: [(name: String, description: String, time: Int16, servings: Int16, difficulty: String, image: String)] = [
            (
                "Classic Chocolate Chip Cookies",
                "Soft and chewy cookies loaded with chocolate chips",
                45,
                24,
                Difficulty.easy.rawValue,
                "cookie.fill"
            ),
            (
                "Homemade Pizza",
                "Crispy crust topped with fresh ingredients",
                60,
                4,
                Difficulty.medium.rawValue,
                "flame.fill"
            ),
            (
                "Beef Stir Fry",
                "Quick and flavorful Asian-inspired dish",
                30,
                4,
                Difficulty.easy.rawValue,
                "fork.knife"
            )
        ]
        
        for (name, description, time, servings, difficulty, imageName) in recipes {
            let recipe = Recipe(context: context)
            recipe.name = name
            recipe.desc = description
            recipe.timeInMinutes = time
            recipe.servings = servings
            recipe.difficulty = difficulty
            
            // Create and set default image
            let defaultImage = UIImage(systemName: imageName)?
                .withTintColor(.orange)
                .withRenderingMode(.alwaysOriginal)
            recipe.imageData = defaultImage?.jpegData(compressionQuality: 1.0)
            
            // Add steps for each recipe
            if name == "Classic Chocolate Chip Cookies" {
                let steps = [
                    "Preheat oven to 375°F (190°C) and line baking sheets with parchment paper.",
                    "In a large bowl, cream together butter and sugars for 3 minutes until light and fluffy.",
                    "Beat in eggs one at a time, then stir in vanilla extract.",
                    "In another bowl, whisk together flour, baking soda, and salt.",
                    "Gradually mix dry ingredients into wet ingredients.",
                    "Fold in chocolate chips.",
                    "Drop rounded tablespoons of dough onto prepared baking sheets.",
                    "Bake for 10 minutes or until edges are lightly browned."
                ]
                
                for (index, instructions) in steps.enumerated() {
                    let step = Step(context: context)
                    step.recipe = recipe
                    step.instructions = instructions
                    step.order = Int16(index)
                    step.createdAt = Date()
                }
                
                // Add recipe ingredients
                let recipeIngredients: [(ingredient: String, quantity: Double, unit: String)] = [
                    ("All-purpose Flour", 280, "grams"),
                    ("Sugar", 200, "grams"),
                    ("Butter", 230, "grams"),
                    ("Eggs", 2, "pieces"),
                    ("Chocolate Chips", 340, "grams"),
                    ("Vanilla Extract", 10, "ml"),
                    ("Baking Powder", 5, "grams"),
                    ("Salt", 3, "grams")
                ]
                
                for (ingredientName, quantity, unit) in recipeIngredients {
                    if let ingredient = ingredientEntities.first(where: { $0.name == ingredientName }) {
                        let recipeIngredient = RecipeIngredient(context: context)
                        recipeIngredient.recipe = recipe
                        recipeIngredient.ingredient = ingredient
                        recipeIngredient.quantity = quantity
                        recipeIngredient.unit = unit
                    }
                }
            }
        }
        
        // Save the context
        do {
            try context.save()
        } catch {
            print("Error saving mock data: \(error)")
        }
    }
} 