import SwiftUI

// Temporarily commented out until we find the original definition
/*
@MainActor
enum PreviewData {
    static func createIngredient(name: String) -> Ingredient {
        let context = PersistenceController.preview.container.viewContext
        let ingredient = Ingredient(context: context)
        ingredient.name = name
        return ingredient
    }
    
    static var sampleIngredients: [SelectedIngredient] {
        [
            SelectedIngredient(
                ingredient: createIngredient(name: "All-purpose Flour"),
                quantity: 200,
                unit: .grams
            ),
            SelectedIngredient(
                ingredient: createIngredient(name: "Sugar"),
                quantity: 50,
                unit: .grams
            ),
            SelectedIngredient(
                ingredient: createIngredient(name: "Baking Powder"),
                quantity: 10,
                unit: .grams
            ),
            SelectedIngredient(
                ingredient: createIngredient(name: "Salt"),
                quantity: 5,
                unit: .grams
            )
        ]
    }
}
*/ 