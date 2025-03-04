import SwiftUI

struct StepRowView: View {
    @Binding var step: RecipeStep
    let recipeIngredients: [SelectedIngredient]
    let onEdit: () -> Void
    
    var body: some View {
        Button(action: onEdit) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Step \(step.order + 1)")
                    .font(.headline)
                    .foregroundColor(.blue)
                    .multilineTextAlignment(.leading)
                
                Text(step.instructions)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                if !step.selectedIngredients.isEmpty {
                    Text("Uses: " + step.selectedIngredients.map { $0.ingredient.name ?? "" }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    StepRowView(
        step: .constant(RecipeStep(
            id: UUID(),
            instructions: "In a large bowl, whisk together flour, sugar, baking powder, and salt until well combined.",
            selectedIngredients: [],
            order: 0
        )),
        recipeIngredients: PreviewData.sampleIngredients
    ) {
        // Empty action for preview
    }
    .padding()
}

// Update PreviewData helper to be MainActor-isolated
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
