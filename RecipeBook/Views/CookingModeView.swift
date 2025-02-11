import SwiftUI

struct CookingModeView: View {
    let recipe: Recipe
    @State private var completedSteps = Set<Int>()
    @State private var currentStepIndex = 0
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private var progress: Double {
        Double(completedSteps.count) / Double(recipe.stepsArray.count)
    }
    
    private var currentStep: Step? {
        recipe.stepsArray.first { Int($0.order) == currentStepIndex }
    }
    
    private var currentStepIngredients: [RecipeIngredient] {
        if let ingredients = currentStep?.ingredients as? Set<RecipeIngredient> {
            return Array(ingredients).sorted { ($0.ingredient?.name ?? "") < ($1.ingredient?.name ?? "") }
        }
        return []
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                // Progress section
                ProgressSection(
                    progress: progress,
                    completedCount: completedSteps.count,
                    totalCount: recipe.stepsArray.count
                )
                
                // Current step ingredients
                if !currentStepIngredients.isEmpty {
                    CurrentIngredientsSection(ingredients: currentStepIngredients)
                }
                
                // All ingredients
                AllIngredientsSection(ingredients: recipe.recipeIngredientsArray)
                
                // Steps timeline
                StepsSection(
                    recipe: recipe,
                    completedSteps: completedSteps,
                    currentStepIndex: currentStepIndex,
                    onStepComplete: handleStepComplete,
                    onStepSelect: handleStepSelect
                )
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Cooking \(recipe.name ?? "")")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if completedSteps.count == recipe.stepsArray.count {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Finish", systemImage: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
    
    private func handleStepComplete(_ step: Step, completed: Bool) {
        withAnimation {
            if completed {
                // Only allow completion if previous step is completed
                if step.order == 0 || completedSteps.contains(Int(step.order - 1)) {
                    completedSteps.insert(Int(step.order))
                    if currentStepIndex < recipe.stepsArray.count - 1 {
                        currentStepIndex = Int(step.order) + 1
                    }
                }
            } else {
                // Only allow uncompleting if no later steps are completed
                let laterStepsCompleted = completedSteps.contains { $0 > Int(step.order) }
                if !laterStepsCompleted {
                    completedSteps.remove(Int(step.order))
                }
            }
        }
    }
    
    private func handleStepSelect(_ step: Step) {
        withAnimation {
            currentStepIndex = Int(step.order)
        }
    }
}

// MARK: - Supporting Views

struct ProgressSection: View {
    let progress: Double
    let completedCount: Int
    let totalCount: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Text("\(Int(progress * 100))%")
                .font(.system(.title, design: .rounded))
                .fontWeight(.bold)
            
            ProgressView(value: progress)
                .tint(.green)
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            Text("\(completedCount) of \(totalCount) steps completed")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .backgroundStyle()
    }
}

struct CurrentIngredientsSection: View {
    let ingredients: [RecipeIngredient]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Current Step Ingredients", systemImage: "list.bullet.circle.fill")
                .font(.headline)
            
            ForEach(ingredients) { ingredient in
                HStack(spacing: 12) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundColor(.blue)
                        .imageScale(.large)
                    
                    VStack(alignment: .leading) {
                        Text(ingredient.ingredient?.name ?? "")
                            .font(.system(.body, design: .rounded))
                            .bold()
                        Text("\(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit ?? "")")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .backgroundStyle()
    }
}

struct AllIngredientsSection: View {
    let ingredients: [RecipeIngredient]
    @State private var isExpanded = false
    
    var body: some View {
        DisclosureGroup(
            isExpanded: $isExpanded,
            content: {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(ingredients) { ingredient in
                        HStack(spacing: 12) {
                            Image(systemName: "circle.fill")
                                .font(.system(size: 6))
                                .foregroundColor(.blue)
                            Text("\(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit ?? "") \(ingredient.ingredient?.name ?? "")")
                        }
                    }
                }
                .padding(.top, 8)
            },
            label: {
                Label("All Ingredients", systemImage: "tray.full.fill")
                    .font(.headline)
            }
        )
        .padding()
        .backgroundStyle()
    }
}

// MARK: - Helper ViewModifier
struct BackgroundStyleModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(
                color: colorScheme == .dark ? .clear : .black.opacity(0.1),
                radius: 8,
                y: 2
            )
    }
}

extension View {
    func backgroundStyle() -> some View {
        modifier(BackgroundStyleModifier())
    }
} 