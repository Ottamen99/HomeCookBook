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
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 24) {
                    // Back button row
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .foregroundColor(.black)
                                .padding()
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .shadow(color: .black.opacity(0.1), radius: 5)
                        }
                        
                        Text(title)
                            .font(.headline)
                            .padding(.leading, 8)
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    // Instructions section
                    VStack(alignment: .leading, spacing: 16) {
                        TextEditor(text: $instructions)
                            .frame(minHeight: 100, maxHeight: 200)
                            .scrollContentBackground(.hidden)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding()
                    
                    // Used Ingredients section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Used Ingredients")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        ForEach(recipeIngredients) { ingredient in
                            ingredientRow(ingredient)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        }
                    }
                    .padding()
                    
                    // Add padding for the bottom button
                    Color.clear.frame(height: 100)
                }
            }
            
            // Bottom save button with solid background
            VStack {
                Spacer()
                
                ZStack {
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .edgesIgnoringSafeArea(.bottom)
                        .frame(height: 100)
                        .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
                    
                    Button(action: saveStep) {
                        Text("Save Step")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(12)
                    }
                    .disabled(instructions.isEmpty)
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
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
                Text("\(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit.rawValue) \(ingredient.ingredient.name ?? "")")
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .orange : .gray)
                    .font(.title3)
            }
        }
    }
    
    private func saveStep() {
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