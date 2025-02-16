import SwiftUI

struct CookingModeView: View {
    let recipe: Recipe
    @State private var completedSteps = Set<Int>()
    @State private var currentStepIndex = 0
    @State private var showCompletedSteps = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    private var progress: Double {
        let total = Double(recipe.stepsArray.count)
        guard total > 0 else { return 0 }
        return min(1.0, Double(completedSteps.count) / total)
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
    
    private var sortedAndFilteredSteps: [Step] {
        let steps = recipe.stepsArray
        if showCompletedSteps {
            return steps
        } else {
            return steps.filter { !completedSteps.contains(Int($0.order)) }
        }
    }
    
    private func getStepStatus(_ step: Step) -> (isCompleted: Bool, isActive: Bool, canComplete: Bool) {
        let isCompleted = completedSteps.contains(Int(step.order))
        let stepIndex = Int(step.order)
        let previousStepCompleted = stepIndex == 0 || completedSteps.contains(stepIndex - 1)
        
        return (
            isCompleted: isCompleted,
            isActive: currentStepIndex == stepIndex,
            canComplete: previousStepCompleted
        )
    }
    
    private var cookingHeader: some View {
        VStack(spacing: 24) {
            // Progress circle
            Circle()
                .fill(Color.orange.opacity(0.1))
                .frame(width: 250, height: 250)
                .overlay {
                    ZStack {
                        Circle()
                            .stroke(Color.gray.opacity(0.2), lineWidth: 12)
                            .frame(width: 200, height: 200)
                        
                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(Color.orange, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                            .frame(width: 200, height: 200)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: 4) {
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 44, weight: .bold, design: .rounded))
                            Text("\(completedSteps.count) of \(recipe.stepsArray.count)")
                                .font(.title3)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.top, 40)
            
            Text(recipe.name ?? "")
                .font(.title)
                .fontWeight(.bold)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: 0) {
                        cookingHeader
                        
                        // Current step ingredients
                        if !currentStepIngredients.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Current Step")
                                    .font(.title2)
                                    .fontWeight(.bold)
                                
                                ForEach(currentStepIngredients) { ingredient in
                                    HStack {
                                        Text(ingredient.ingredient?.name ?? "")
                                            .font(.body)
                                        
                                        Spacer()
                                        
                                        Text("\(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit ?? "")")
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .padding()
                        }
                        
                        // All ingredients
                        VStack(alignment: .leading, spacing: 16) {
                            Text("All Ingredients")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            ForEach(recipe.recipeIngredientsArray) { ingredient in
                                HStack {
                                    Text(ingredient.ingredient?.name ?? "")
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    Text("\(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit ?? "")")
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding()
                        
                        // Steps
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Steps")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.horizontal)
                            
                            ForEach(sortedAndFilteredSteps) { step in
                                let status = getStepStatus(step)
                                
                                StepTimelineView(
                                    recipe: recipe,
                                    step: step,
                                    isCompleted: status.isCompleted,
                                    isActive: status.isActive,
                                    isFirst: step == recipe.stepsArray.first,
                                    isLast: step == recipe.stepsArray.last,
                                    onToggleComplete: { completed in
                                        toggleStepCompletion(step, completed: completed)
                                    },
                                    canComplete: status.canComplete
                                )
                            }
                        }
                        .padding(.vertical)
                        
                        // Add padding at the bottom when button is visible
                        if completedSteps.count == recipe.stepsArray.count {
                            Color.clear.frame(height: 100) // Height for button + padding
                        }
                    }
                }
                
                // Completion button
                if completedSteps.count == recipe.stepsArray.count {
                    Button {
                        dismiss()
                    } label: {
                        Text("Finish Cooking")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .padding()
                    .background(
                        Rectangle()
                            .fill(.white)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleStepCompletion(_ step: Step, completed: Bool) {
        withAnimation {
            let stepOrder = Int(step.order)
            if completed {
                // Only allow completion if previous step is completed
                if stepOrder == 0 || completedSteps.contains(stepOrder - 1) {
                    completedSteps.insert(stepOrder)
                    if currentStepIndex < recipe.stepsArray.count - 1 {
                        currentStepIndex = stepOrder + 1
                    }
                }
            } else {
                // Only allow uncompleting if no later steps are completed
                let laterStepsCompleted = completedSteps.contains { $0 > stepOrder }
                if !laterStepsCompleted {
                    completedSteps.remove(stepOrder)
                }
            }
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
