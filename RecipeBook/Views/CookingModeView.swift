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
                            
                            ForEach(recipe.stepsArray) { step in
                                let isCompleted = completedSteps.contains(Int(step.order))
                                let isCurrent = currentStepIndex == Int(step.order)
                                
                                Button {
                                    handleStepSelect(step)
                                } label: {
                                    HStack(alignment: .top, spacing: 16) {
                                        // Step number circle
                                        Circle()
                                            .fill(isCompleted ? Color.orange : (isCurrent ? Color.orange.opacity(0.2) : Color.gray.opacity(0.1)))
                                            .frame(width: 36, height: 36)
                                            .overlay {
                                                if isCompleted {
                                                    Image(systemName: "checkmark")
                                                        .foregroundColor(.white)
                                                } else {
                                                    Text("\(Int(step.order) + 1)")
                                                        .foregroundColor(isCurrent ? .orange : .gray)
                                                }
                                            }
                                        
                                        VStack(alignment: .leading, spacing: 12) {
                                            Text(step.instructions ?? "")
                                                .foregroundColor(isCurrent ? .primary : .secondary)
                                                .multilineTextAlignment(.leading)
                                            
                                            if isCurrent {
                                                Button {
                                                    handleStepComplete(step, completed: !isCompleted)
                                                } label: {
                                                    HStack(spacing: 8) {
                                                        Image(systemName: isCompleted ? "xmark.circle.fill" : "checkmark.circle.fill")
                                                        Text(isCompleted ? "Mark Incomplete" : "Mark Complete")
                                                            .fontWeight(.medium)
                                                    }
                                                    .foregroundColor(isCompleted ? .red : .orange)
                                                    .padding(.vertical, 8)
                                                    .padding(.horizontal, 16)
                                                    .background(
                                                        RoundedRectangle(cornerRadius: 20)
                                                            .fill(isCompleted ? Color.red.opacity(0.1) : Color.orange.opacity(0.1))
                                                    )
                                                }
                                            }
                                        }
                                        
                                        Spacer(minLength: 0)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(isCurrent ? Color.orange.opacity(0.05) : Color(.systemBackground))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(isCurrent ? Color.orange.opacity(0.5) : Color.clear, lineWidth: 1)
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
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
