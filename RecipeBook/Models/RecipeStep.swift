import Foundation
import CoreData

struct RecipeStep: Identifiable {
    let id: UUID
    var instructions: String
    var selectedIngredients: [SelectedIngredient]
    var order: Int16
    
    init(id: UUID = UUID(), instructions: String, selectedIngredients: [SelectedIngredient], order: Int16) {
        self.id = id
        self.instructions = instructions
        self.selectedIngredients = selectedIngredients
        self.order = order
    }
    
    init(step: Step? = nil) {
        self.id = UUID()  // Always create a new UUID for the model
        self.instructions = step?.instructions ?? ""
        self.selectedIngredients = Array(step?.ingredients as? Set<RecipeIngredient> ?? []).map { ri in
            SelectedIngredient(
                ingredient: ri.ingredient!,
                quantity: ri.quantity,
                unit: UnitOfMeasure(rawValue: ri.unit ?? "") ?? .grams
            )
        }
        self.order = step?.order ?? 0
    }
} 