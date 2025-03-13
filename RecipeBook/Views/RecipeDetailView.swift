import SwiftUI
import CoreData

struct RecipeDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject var recipe: Recipe
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var servings: Int16
    @State private var refreshID = UUID()
    @State private var showingCookingMode = false
    @State private var scrollOffset: CGFloat = 0
    @State private var shouldDismiss = false
    @AccessibilityFocusState private var isHeaderFocused: Bool
    
    // Add FetchRequest for ingredients
    @FetchRequest private var ingredients: FetchedResults<RecipeIngredient>
    
    // Add this to observe Ingredient changes
    @FetchRequest(
        entity: Ingredient.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Ingredient.name, ascending: true)]
    ) private var allIngredients: FetchedResults<Ingredient>
    
    init(recipe: Recipe) {
        self.recipe = recipe
        // Initialize servings with recipe's value
        _servings = State(initialValue: recipe.servings)
        
        // Initialize FetchRequest
        let predicate = NSPredicate(format: "recipe == %@", recipe)
        let sortDescriptors = [NSSortDescriptor(keyPath: \RecipeIngredient.ingredient?.name, ascending: true)]
        
        _ingredients = FetchRequest(
            sortDescriptors: sortDescriptors,
            predicate: predicate,
            animation: .default
        )
        
        // Initialize the allIngredients fetch request
        _allIngredients = FetchRequest(
            entity: Ingredient.entity(),
            sortDescriptors: [NSSortDescriptor(keyPath: \Ingredient.name, ascending: true)],
            animation: .default
        )
    }
    
    // MARK: - Main View
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Header with image and basic info
                recipeHeader
                
                // Main content
                VStack(alignment: .leading, spacing: 32) {
                    // Description
                    if let description = recipe.desc, !description.isEmpty {
                        descriptionSection(description)
                    }
                    
                    // Ingredients
                    ingredientsSection
                    
                    // Steps
                    stepsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 100) // Space for the bottom button
            }
        }
        .scrollIndicators(.visible)
        .safeAreaInset(edge: .top) {
            Color.clear.frame(height: 0)
                .accessibilityHidden(true)
        }
        .overlay(alignment: .top) {
            headerOverlay
        }
        .overlay(alignment: .bottom) {
            startCookingButton
        }
        .ignoresSafeArea(.container, edges: .top)
        .navigationBarHidden(true)
        .toolbar(.hidden, for: .tabBar)
        .id(refreshID)
        .sheet(isPresented: $showingEditSheet, onDismiss: {
            viewContext.refresh(recipe, mergeChanges: true)
            servings = recipe.servings
            refreshID = UUID()
        }) {
            NavigationStack {
                EditRecipeView(
                    recipe: recipe,
                    rootDismiss: $shouldDismiss,
                    refreshID: $refreshID
                )
            }
        }
        .onChange(of: shouldDismiss) { oldValue, newValue in
            if newValue {
                dismiss()
            }
        }
        .sheet(isPresented: $showingCookingMode) {
            NavigationStack {
                CookingModeView(recipe: recipe)
            }
        }
        .alert("Delete Recipe", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteRecipe()
            }
        } message: {
            Text("Are you sure you want to delete this recipe? This action cannot be undone.")
        }
        .onChange(of: recipe) { oldRecipe, newRecipe in
            servings = newRecipe.servings
            refreshID = UUID()
        }
        .onAppear {
            servings = recipe.servings
            refreshID = UUID()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isHeaderFocused = true
            }
        }
        .onDisappear {
            refreshID = UUID()
        }
    }
    
    // MARK: - Component Views
    
    private var recipeHeader: some View {
        VStack(spacing: 20) {
            // Recipe image
            ZStack(alignment: .bottom) {
                if let imageData = recipe.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 280)
                        .clipped()
                        .accessibilityHidden(true)
                } else {
                    Rectangle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(height: 280)
                        .overlay {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                        }
                        .accessibilityHidden(true)
                }
                
                // Gradient overlay for better text visibility
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 120)
            }
            
            // Recipe info
            VStack(alignment: .leading, spacing: 20) {
                // Title and difficulty
                HStack(alignment: .center) {
                    Text(recipe.name ?? "")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .lineSpacing(4) // Improve readability
                        .accessibilityFocused($isHeaderFocused)
                    
                    Spacer()
                    
                    if let difficultyString = recipe.difficulty,
                       let difficulty = Difficulty(rawValue: difficultyString) {
                        DifficultyPill(difficulty: difficulty)
                    }
                }
                
                // Stats row
                HStack(spacing: 24) {
                    // Time
                    Label {
                        Text("\(recipe.timeInMinutes) min")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    } icon: {
                        Image(systemName: "clock")
                            .foregroundColor(.orange)
                    }
                    
                    // Servings with stepper
                    servingsControl
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var servingsControl: some View {
        HStack(spacing: 8) {
            Label {
                Text("Servings")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } icon: {
                Image(systemName: "person.2")
                    .foregroundColor(.orange)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button {
                    if servings > 1 {
                        servings -= 1
                        updateServings()
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44) // 44pt minimum hit target
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .disabled(servings <= 1)
                .accessibilityLabel("Decrease servings")
                
                Text("\(servings)")
                    .font(.headline)
                    .frame(minWidth: 24, alignment: .center)
                    .accessibilityLabel("\(servings) servings")
                
                Button {
                    if servings < 20 {
                        servings += 1
                        updateServings()
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.body)
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44) // 44pt minimum hit target
                        .background(Color.secondary.opacity(0.1))
                        .clipShape(Circle())
                }
                .disabled(servings >= 20)
                .accessibilityLabel("Increase servings")
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.08))
        )
    }
    
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(6) // Improved line spacing for readability
        }
        .padding(.vertical, 8)
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Ingredients")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(ingredients) { recipeIngredient in
                    let scaledQuantity = recipeIngredient.quantity * Double(servings) / Double(recipe.servings)
                    HStack {
                        if let ingredient = recipeIngredient.ingredient {
                            Text(ingredient.name ?? "")
                                .font(.body)
                                .foregroundColor(.primary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(String(format: "%.1f %@", scaledQuantity, recipeIngredient.unit ?? ""))
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 12) // Increased for better hit target
                    .padding(.horizontal, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(colorScheme == .dark ? 
                                  Color(UIColor.secondarySystemBackground) : 
                                  Color(UIColor.systemBackground))
                            .shadow(color: Color.black.opacity(0.03), radius: 2, x: 0, y: 1)
                    )
                    .contentShape(Rectangle()) // Ensure the entire row is tappable
                }
            }
        }
    }
    
    private var stepsSection: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Instructions")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 24) { // Increased spacing between steps
                ForEach(recipe.stepsArray) { step in
                    stepView(step)
                }
            }
        }
    }
    
    private func stepView(_ step: Step) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Step header
            HStack(alignment: .center, spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.2))
                        .frame(width: 44, height: 44) // 44pt minimum hit target
                    
                    Text("\(step.order + 1)")
                        .font(.headline)
                        .foregroundColor(.orange)
                }
                
                Text("Step \(step.order + 1)")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            // Instructions
            Text(step.instructions ?? "")
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(6) // Improved line spacing
                .padding(.leading, 60) // Align with step number
            
            // Used ingredients
            if let ingredients = step.ingredients as? Set<RecipeIngredient>, !ingredients.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "leaf.fill")
                        .font(.subheadline)
                        .foregroundColor(.orange)
                    
                    Text(ingredients.compactMap { $0.ingredient?.name }.joined(separator: ", "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(10)
                .padding(.leading, 60) // Align with step number
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
    
    private var headerOverlay: some View {
        HStack {
            // Back button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44) // 44pt minimum hit target
                    .background(
                        Circle()
                            .fill(Color(UIColor.systemBackground).opacity(0.9))
                            .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                    )
            }
            .accessibilityLabel("Back")
            
            Spacer()
            
            HStack(spacing: 12) {
                // Edit button
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "pencil")
                        .font(.headline)
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44) // 44pt minimum hit target
                        .background(
                            Circle()
                                .fill(Color(UIColor.systemBackground).opacity(0.9))
                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                        )
                }
                .accessibilityLabel("Edit recipe")
                
                // Delete button
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .font(.headline)
                        .foregroundColor(.red)
                        .frame(width: 44, height: 44) // 44pt minimum hit target
                        .background(
                            Circle()
                                .fill(Color(UIColor.systemBackground).opacity(0.9))
                                .shadow(color: Color.black.opacity(0.1), radius: 3, x: 0, y: 1)
                        )
                }
                .accessibilityLabel("Delete recipe")
            }
        }
        .padding(16)
        .padding(.top, 44) // Account for safe area
    }
    
    private var startCookingButton: some View {
        VStack {
            Button(action: { showingCookingMode = true }) {
                HStack {
                    Image(systemName: "play.fill")
                    Text("Start Cooking")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54) // Taller button for better hit target
                .background(Color.orange)
                .cornerRadius(16)
                .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
            }
            .accessibilityLabel("Start cooking mode")
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(
            Rectangle()
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: -4)
                .edgesIgnoringSafeArea(.bottom)
        )
    }
    
    // MARK: - Helper Functions
    
    private func deleteRecipe() {
        viewContext.delete(recipe)
        try? viewContext.save()
        dismiss()
    }
    
    private func updateServings() {
        let oldServings = recipe.servings
        let newServings = servings
        
        viewContext.performAndWait {
            // Update recipe servings first
            recipe.servings = newServings
            
            // Update ingredient quantities
            for ingredient in ingredients {
                let baseQuantity = ingredient.quantity / Double(oldServings)
                ingredient.quantity = baseQuantity * Double(newServings)
            }
            
            do {
                try viewContext.save()
                viewContext.refresh(recipe, mergeChanges: false)
                refreshID = UUID()
            } catch {
                print("Error updating servings: \(error)")
                // Revert on failure
                servings = oldServings
            }
        }
    }
}

// MARK: - Supporting Views

private struct DifficultyPill: View {
    let difficulty: Difficulty
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: difficulty.icon)
            Text(difficulty.rawValue)
        }
        .font(.subheadline)
        .foregroundColor(.white)
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(difficulty.color)
        .clipShape(Capsule())
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    // Create a sample recipe
    let recipe = Recipe(context: context)
    recipe.name = "Spaghetti Carbonara"
    recipe.desc = "A classic Italian pasta dish with eggs, cheese, pancetta, and black pepper."
    recipe.timeInMinutes = 30
    recipe.servings = 4
    recipe.difficulty = Difficulty.medium.rawValue
    
    // Add some ingredients
    let ingredients = [
        ("Spaghetti", 400.0, "grams"),
        ("Eggs", 4.0, "pieces"),
        ("Pecorino Romano", 100.0, "grams"),
        ("Pancetta", 150.0, "grams"),
        ("Black Pepper", 2.0, "teaspoons")
    ]
    
    for (name, quantity, unit) in ingredients {
        let ingredient = Ingredient(context: context)
        ingredient.name = name
        
        let recipeIngredient = RecipeIngredient(context: context)
        recipeIngredient.ingredient = ingredient
        recipeIngredient.recipe = recipe
        recipeIngredient.quantity = quantity
        recipeIngredient.unit = unit
    }
    
    // Add some steps
    let steps = [
        "Bring a large pot of salted water to boil.",
        "Cook spaghetti according to package instructions.",
        "Meanwhile, cook pancetta until crispy.",
        "Mix eggs, cheese, and pepper in a bowl.",
        "Combine everything and serve immediately."
    ]
    
    for (index, instructions) in steps.enumerated() {
        let step = Step(context: context)
        step.recipe = recipe
        step.instructions = instructions
        step.order = Int16(index)
        step.createdAt = Date()
    }
    
    try? context.save()
    
    return RecipeDetailView(recipe: recipe)
        .environment(\.managedObjectContext, context)
} 
