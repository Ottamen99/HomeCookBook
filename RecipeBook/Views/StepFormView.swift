import SwiftUI

struct StepFormView: View {
    @Environment(\.dismiss) private var dismiss
    let step: RecipeStep?
    let recipeIngredients: [SelectedIngredient]
    let onSave: (RecipeStep) -> Void
    
    @State private var instructions = ""
    @State private var selectedIngredientIds: Set<UUID> = []
    
    init(step: RecipeStep?, recipeIngredients: [SelectedIngredient], onSave: @escaping (RecipeStep) -> Void) {
        self.step = step
        self.recipeIngredients = recipeIngredients
        self.onSave = onSave
        
        _instructions = State(initialValue: step?.instructions ?? "")
        
        var initialSelection: Set<UUID> = []
        if let step = step {
            initialSelection = Set(step.selectedIngredients.compactMap { recipeIngredient in
                recipeIngredients.first { $0.ingredient == recipeIngredient.ingredient }?.id
            })
        }
        _selectedIngredientIds = State(initialValue: initialSelection)
    }
    
    private var title: String {
        step == nil ? "New Step" : "Edit Step"
    }
    
    private func ingredientRow(_ ingredient: SelectedIngredient) -> some View {
        let isSelected = selectedIngredientIds.contains(ingredient.id)
        return Button {
            if isSelected {
                selectedIngredientIds.remove(ingredient.id)
            } else {
                selectedIngredientIds.insert(ingredient.id)
            }
        } label: {
            HStack {
                Text("\(String(format: "%.2f", ingredient.quantity)) \(ingredient.unit.rawValue) \(ingredient.ingredient.name ?? "")")
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .foregroundColor(.blue)
                }
            }
        }
        .foregroundColor(.primary)
    }
    
    var body: some View {
        Form {
            Section("Instructions") {
                TextField("Step instructions", text: $instructions, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section("Used Ingredients") {
                ForEach(recipeIngredients) { ingredient in
                    ingredientRow(ingredient)
                }
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("Save") {
                    let selectedIngredients = selectedIngredientIds.compactMap { id in
                        recipeIngredients.first { $0.id == id }
                    }
                    
                    let newStep = RecipeStep(
                        instructions: instructions,
                        selectedIngredients: selectedIngredients,
                        order: step?.order ?? 0
                    )
                    onSave(newStep)
                    dismiss()
                }
                .disabled(instructions.isEmpty)
            }
        }
    }
} 