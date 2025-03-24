import SwiftUI
import CoreData

struct CookingModeView: View {
    let recipe: Recipe
    @State private var completedSteps = Set<Int>()
    @State private var currentStepIndex = 0
    @State private var showCompletedSteps = true
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var isProgressFocused: Bool
    
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
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                ScrollView {
                    VStack(spacing: dynamicTypeSize > .large ? 24 : 32) {
                        // Progress section
                        progressSection
                            .accessibilityElement(children: .combine)
                            .accessibilityLabel("Recipe progress")
                            .accessibilityValue("\(Int(progress * 100))% complete, \(completedSteps.count) of \(recipe.stepsArray.count) steps completed")
                            .accessibilityFocused($isProgressFocused)
                        
                        // Current step ingredients
                        if !currentStepIngredients.isEmpty {
                            currentStepIngredientsSection
                        }
                        
                        // Toggle for showing/hiding completed steps
                        if !completedSteps.isEmpty && completedSteps.count < recipe.stepsArray.count {
                            toggleCompletedStepsButton
                        }
                        
                        // All ingredients
                        allIngredientsSection
                        
                        // Steps
                        stepsSection
                        
                        // Add padding at the bottom when button is visible
                        if completedSteps.count == recipe.stepsArray.count {
                            Color.clear.frame(height: 100) // Height for button + padding
                        }
                    }
                    .padding(.top, 16)
                    .padding(.horizontal)
                }
                .scrollIndicators(.visible)
                .scrollContentBackground(.hidden)
                .background(Color(.systemGroupedBackground))
                
                // Completion button
                if completedSteps.count == recipe.stepsArray.count {
                    finishCookingButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Cooking Mode")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Cancel", systemImage: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Cancel cooking mode")
                }
                
                ToolbarItem(placement: .principal) {
                    Text(recipe.name ?? "")
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isProgressFocused = true
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    private var progressSection: some View {
        VStack(spacing: 16) {
            // Progress circle with added animation
            ZStack {
                Circle()
                    .fill(.thinMaterial)
                    .frame(width: min(250, UIScreen.main.bounds.width - 40), height: min(250, UIScreen.main.bounds.width - 40))
                
                Circle()
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 12)
                    .frame(width: min(200, UIScreen.main.bounds.width - 80), height: min(200, UIScreen.main.bounds.width - 80))
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: min(200, UIScreen.main.bounds.width - 80), height: min(200, UIScreen.main.bounds.width - 80))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6), value: progress)
                
                VStack(spacing: 4) {
                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.7)
                        .foregroundStyle(.primary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.4), value: progress)
                    
                    Text("\(completedSteps.count) of \(recipe.stepsArray.count)")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .contentTransition(.numericText())
                        .animation(.spring(response: 0.4), value: completedSteps.count)
                }
                .padding()
            }
            .accessibilityHidden(true)
            
            Text(recipe.name ?? "")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.9)
        }
        .padding(.bottom, 8)
    }
    
    private var currentStepIngredientsSection: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Label("Current Step Ingredients", systemImage: "list.bullet.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .symbolRenderingMode(.hierarchical)
                    
                    Spacer()
                    
                    Text("Step \(currentStepIndex + 1)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.accentColor)
                        )
                }
                
                Divider()
                
                ForEach(currentStepIngredients) { ingredient in
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.right.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.system(size: 18))
                            .symbolRenderingMode(.hierarchical)
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ingredient.ingredient?.name ?? "")
                                .font(.body.bold())
                                .foregroundStyle(.primary)
                            
                            Text("\(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit ?? "")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        } label: {
            // Empty label to maintain consistent styling with iOS standards
        }
        .groupBoxStyle(CardGroupBoxStyle())
    }
    
    private var toggleCompletedStepsButton: some View {
        Button {
            withAnimation(.spring(response: 0.4)) {
                showCompletedSteps.toggle()
            }
        } label: {
            Label(
                showCompletedSteps ? "Hide Completed Steps" : "Show Completed Steps",
                systemImage: showCompletedSteps ? "eye.slash" : "eye"
            )
            .font(.subheadline.bold())
            .foregroundStyle(.primary)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
        .buttonStyle(.borderless)
        .accessibilityHint(showCompletedSteps ? "Hides steps you've already completed" : "Shows all steps including completed ones")
    }
    
    private var allIngredientsSection: some View {
        GroupBox {
            DisclosureGroup {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    ForEach(recipe.recipeIngredientsArray) { ingredient in
                        HStack {
                            Text(ingredient.ingredient?.name ?? "")
                                .font(.body)
                                .foregroundStyle(.primary)
                            
                            Spacer()
                            
                            Text("\(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit ?? "")")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 6)
                    }
                }
                .padding(.top, 8)
            } label: {
                Label("All Ingredients", systemImage: "tray.full")
                    .font(.headline)
                    .foregroundStyle(.primary)
                    .symbolRenderingMode(.hierarchical)
            }
        } label: {
            // Empty label to maintain consistent styling with iOS standards
        }
        .groupBoxStyle(CardGroupBoxStyle())
    }
    
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Steps")
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if !sortedAndFilteredSteps.isEmpty {
                    Text("\(sortedAndFilteredSteps.count) \(sortedAndFilteredSteps.count == 1 ? "step" : "steps")")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            if sortedAndFilteredSteps.isEmpty {
                emptyStepsView
            } else {
                LazyVStack(spacing: 16) {
                    ForEach(sortedAndFilteredSteps) { step in
                        let status = getStepStatus(step)
                        
                        CookingStepView(
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
                        .id(step.id)
                        .transition(.opacity.combined(with: .move(edge: .leading)))
                    }
                }
            }
        }
        .padding(.vertical)
    }
    
    private var emptyStepsView: some View {
        GroupBox {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 50))
                    .foregroundStyle(.green)
                    .symbolRenderingMode(.hierarchical)
                    .accessibilityHidden(true)
                
                Text("All steps completed!")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("You've completed all the steps for this recipe.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                
                Button {
                    withAnimation(.spring(response: 0.4)) {
                        showCompletedSteps = true
                    }
                } label: {
                    Text("Show All Steps")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(height: 44)
                        .frame(maxWidth: 200)
                        .background(Color.green)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
        } label: {
            // Empty label to maintain consistent styling with iOS standards
        }
        .groupBoxStyle(CardGroupBoxStyle())
    }
    
    private var finishCookingButton: some View {
        Button {
            dismiss()
        } label: {
            Label("Finish Cooking", systemImage: "checkmark.circle.fill")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54) // Taller button for better hit target (44pt minimum)
                .background(Color.green)
                .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.bordered)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(.thinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
                .edgesIgnoringSafeArea(.bottom)
        )
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityHint("Completes the cooking process and returns to the recipe details")
    }
    
    // MARK: - Helper Functions
    
    private func toggleStepCompletion(_ step: Step, completed: Bool) {
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()
        
        withAnimation(.spring(response: 0.4)) {
            let stepOrder = Int(step.order)
            if completed {
                // Only allow completion if previous step is completed
                if stepOrder == 0 || completedSteps.contains(stepOrder - 1) {
                    completedSteps.insert(stepOrder)
                    impact.impactOccurred()
                    if currentStepIndex < recipe.stepsArray.count - 1 {
                        currentStepIndex = stepOrder + 1
                    }
                }
            } else {
                // Only allow uncompleting if no later steps are completed
                let laterStepsCompleted = completedSteps.contains { $0 > stepOrder }
                if !laterStepsCompleted {
                    completedSteps.remove(stepOrder)
                    impact.impactOccurred(intensity: 0.7)
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct CookingStepView: View {
    let recipe: Recipe
    let step: Step
    let isCompleted: Bool
    let isActive: Bool
    let isFirst: Bool
    let isLast: Bool
    let onToggleComplete: (Bool) -> Void
    let canComplete: Bool
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            // Timeline visualization
            timelineView
            
            // Step content
            stepContentView
        }
    }
    
    // MARK: - Extracted Views
    
    private var timelineView: some View {
        VStack(spacing: 0) {
            // Top connector line
            if !isFirst {
                Rectangle()
                    .fill(isCompleted ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 2)
                    .frame(height: 24)
            }
            
            // Circle indicator
            stepCircleIndicator
            
            // Bottom connector line
            if !isLast {
                Rectangle()
                    .fill(isCompleted ? Color.green : Color.gray.opacity(0.3))
                    .frame(width: 2)
                    .frame(height: 24)
            }
        }
        .padding(.top, 8)
    }
    
    private var stepCircleIndicator: some View {
        ZStack {
            Circle()
                .fill(backgroundColor)
                .frame(width: 26, height: 26)
            
            if isCompleted {
                Image(systemName: "checkmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            } else {
                Text("\(Int(step.order) + 1)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(isActive ? .white : .primary)
            }
        }
        .accessibilityHidden(true)
    }
    
    private var stepContentView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Step description
            Text(step.instructions ?? "")
                .font(.body)
                .foregroundColor(isCompleted ? .secondary : .primary)
                .strikethrough(isCompleted, color: .secondary)
                .padding(.top, 8)
                .fixedSize(horizontal: false, vertical: true)
            
            // Complete/Uncomplete button
            stepActionButton
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? 
                      Color(UIColor.secondarySystemBackground) : 
                      Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var stepActionButton: some View {
        Button {
            onToggleComplete(!isCompleted)
        } label: {
            HStack {
                Image(systemName: isCompleted ? "arrow.uturn.backward" : "checkmark")
                Text(isCompleted ? "Mark as Incomplete" : "Mark as Complete")
            }
            .font(.subheadline.weight(.medium))
            .foregroundColor(isCompleted ? .primary : .white)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(
                Capsule()
                    .fill(isCompleted ? Color.secondary.opacity(0.2) : Color.green)
            )
            .contentShape(Capsule())
        }
        .disabled(!canComplete && !isCompleted)
        .opacity(canComplete || isCompleted ? 1.0 : 0.5)
        .accessibilityHint(canComplete || isCompleted ? 
                          (isCompleted ? "Marks this step as not completed" : "Marks this step as completed") : 
                          "Complete previous steps first")
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return .green
        } else if isActive {
            return .orange
        } else {
            return Color.gray.opacity(0.3)
        }
    }
}

// Custom GroupBox style for card-like appearance
struct CardGroupBoxStyle: GroupBoxStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading) {
            configuration.label
            configuration.content
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
}

// MARK: - Preview Provider
struct CookingModeView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let recipe = createSampleRecipe(in: context)
        
        return CookingModeView(recipe: recipe)
            .environment(\.managedObjectContext, context)
    }
    
    static func createSampleRecipe(in context: NSManagedObjectContext) -> Recipe {
        // Create a sample recipe
        let recipe = Recipe(context: context)
        recipe.name = "Spaghetti Carbonara"
        recipe.timeInMinutes = 30
        recipe.servings = 2
        
        // Create ingredients
        let pasta = Ingredient(context: context)
        pasta.name = "Spaghetti"
        
        let eggs = Ingredient(context: context)
        eggs.name = "Eggs"
        
        let bacon = Ingredient(context: context)
        bacon.name = "Bacon"
        
        let cheese = Ingredient(context: context)
        cheese.name = "Parmesan Cheese"
        
        // Create recipe ingredients
        let ri1 = RecipeIngredient(context: context)
        ri1.recipe = recipe
        ri1.ingredient = pasta
        ri1.quantity = 200
        ri1.unit = "g"
        
        let ri2 = RecipeIngredient(context: context)
        ri2.recipe = recipe
        ri2.ingredient = eggs
        ri2.quantity = 2
        ri2.unit = "whole"
        
        let ri3 = RecipeIngredient(context: context)
        ri3.recipe = recipe
        ri3.ingredient = bacon
        ri3.quantity = 100
        ri3.unit = "g"
        
        let ri4 = RecipeIngredient(context: context)
        ri4.recipe = recipe
        ri4.ingredient = cheese
        ri4.quantity = 50
        ri4.unit = "g"
        
        // Create steps
        let step1 = Step(context: context)
        step1.recipe = recipe
        step1.order = 0
        step1.instructions = "Boil water in a large pot and add salt."
        
        let step2 = Step(context: context)
        step2.recipe = recipe
        step2.order = 1
        step2.instructions = "Cook pasta according to package instructions until al dente."
        step2.addToIngredients(ri1)
        
        let step3 = Step(context: context)
        step3.recipe = recipe
        step3.order = 2
        step3.instructions = "Meanwhile, cook bacon in a large skillet until crispy."
        step3.addToIngredients(ri3)
        
        let step4 = Step(context: context)
        step4.recipe = recipe
        step4.order = 3
        step4.instructions = "In a bowl, whisk eggs and grated cheese together."
        step4.addToIngredients(ri2)
        step4.addToIngredients(ri4)
        
        let step5 = Step(context: context)
        step5.recipe = recipe
        step5.order = 4
        step5.instructions = "Drain pasta and immediately add to the skillet with bacon. Remove from heat."
        
        let step6 = Step(context: context)
        step6.recipe = recipe
        step6.order = 5
        step6.instructions = "Quickly pour egg mixture over pasta and stir continuously until creamy. Season with salt and pepper."
        
        try? context.save()
        
        return recipe
    }
}
