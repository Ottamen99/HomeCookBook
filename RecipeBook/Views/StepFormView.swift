import SwiftUI

struct StepFormView: View {
    @Environment(\.dismiss) private var dismiss
    let step: RecipeStep?
    let recipeIngredients: [SelectedIngredient]
    let onSave: (RecipeStep) -> Void
    
    @State private var instructions = ""
    @State private var selectedIngredientIds: Set<UUID> = []
    @FocusState private var isInstructionsFocused: Bool
    
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Instructions section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Instructions", systemImage: "text.justify")
                            .font(.headline)
                        
                        TextEditor(text: $instructions)
                            .frame(minHeight: 120)
                            .padding(12)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .focused($isInstructionsFocused)
                    }
                    .padding(.horizontal)
                    
                    // Used Ingredients section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Used Ingredients", systemImage: "checklist")
                            .font(.headline)
                        
                        ForEach(recipeIngredients) { ingredient in
                            ingredientRow(ingredient)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWithHapticFeedback()
                    }
                    .fontWeight(.semibold)
                    .disabled(instructions.isEmpty)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isInstructionsFocused = false
                        }
                    }
                }
            }
        }
    }
    
    private func ingredientRow(_ ingredient: SelectedIngredient) -> some View {
        let isSelected = selectedIngredientIds.contains(ingredient.id)
        
        return Button {
            withAnimation(.spring(response: 0.3)) {
                if isSelected {
                    selectedIngredientIds.remove(ingredient.id)
                } else {
                    selectedIngredientIds.insert(ingredient.id)
                }
            }
            
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } label: {
            HStack(spacing: 16) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(isSelected ? .orange : .secondary)
                    .symbolRenderingMode(.hierarchical)
                    .animation(.spring(response: 0.3), value: isSelected)
                
                // Ingredient details
                VStack(alignment: .leading, spacing: 4) {
                    Text(ingredient.ingredient.name ?? "")
                        .foregroundStyle(.primary)
                    Text("\(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit.rawValue)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.regularMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.orange.opacity(0.3) : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func saveWithHapticFeedback() {
        // Success haptic
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        
        // Create and save the step
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
}

#Preview {
    NavigationStack {
        StepFormView(
            step: RecipeStep(
                id: UUID(),
                instructions: "In a large bowl, whisk together flour, sugar, baking powder, and salt until well combined.",
                selectedIngredients: [],
                order: 0
            ),
            recipeIngredients: PreviewData.sampleIngredients
        ) { _ in
            // Empty action for preview
        }
    }
} 