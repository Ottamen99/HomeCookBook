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
                
                Text(step.instructions)
                
                if !step.selectedIngredients.isEmpty {
                    Text("Uses: " + step.selectedIngredients.map { $0.ingredient.name ?? "" }.joined(separator: ", "))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
        }
    }
} 
