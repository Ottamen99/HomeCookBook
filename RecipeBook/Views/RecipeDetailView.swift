import SwiftUI
import CoreData

struct RecipeDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe  // Change back to let
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var servings: Int16
    @State private var refreshID = UUID()
    @State private var showingCookingMode = false
    
    // Add FetchRequest for ingredients
    @FetchRequest private var ingredients: FetchedResults<RecipeIngredient>
    
    // Add this to observe Ingredient changes
    @FetchRequest(
        entity: Ingredient.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \Ingredient.name, ascending: true)]
    ) private var allIngredients: FetchedResults<Ingredient>
    
    init(recipe: Recipe) {
        self.recipe = recipe
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
    
    private var currentRecipe: Recipe {
        recipe
    }
    
    private var recipeImage: some View {
        Group {
            if let imageData = currentRecipe.imageData,
               let uiImage = UIImage(data: imageData) {
                Section {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .listRowInsets(EdgeInsets())
            }
        }
    }
    
    private var timeView: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.blue)
            Text("\(currentRecipe.timeInMinutes) minutes")
        }
    }
    
    private var servingsView: some View {
        HStack {
            Image(systemName: "person.2")
                .foregroundColor(.blue)
            Stepper("Servings: \(servings)", value: $servings, in: 1...20)
        }
    }
    
    private var recipeDetails: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                timeView
                servingsView
            }
        }
    }
    
    private var recipeDescription: some View {
        Group {
            if let description = currentRecipe.desc, !description.isEmpty {
                Section("Description") {
                    Text(description)
                        .lineSpacing(4)
                }
            }
        }
    }
    
    private func ingredientView(for recipeIngredient: RecipeIngredient) -> some View {
        let scaledQuantity = recipeIngredient.quantity * Double(servings) / Double(currentRecipe.servings)
        return HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                }
            
            VStack(alignment: .leading, spacing: 4) {
                // Use Text view with ID to force refresh when ingredient name changes
                if let ingredient = recipeIngredient.ingredient {
                    Text(ingredient.name ?? "")
                        .id("ingredient-\(ingredient.objectID)-\(ingredient.name ?? "")")
                        .font(.headline)
                }
                Text(String(format: "%.2f %@", scaledQuantity, recipeIngredient.unit ?? ""))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var ingredientsSection: some View {
        Section("Ingredients") {
            ForEach(ingredients) { recipeIngredient in
                ingredientView(for: recipeIngredient)
                    .id("recipeIngredient-\(recipeIngredient.objectID)-\(recipeIngredient.ingredient?.name ?? "")")
            }
        }
    }
    
    private func stepView(for step: Step) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Step \(step.order + 1)")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Spacer()
                
                if let duration = StepDuration.detect(in: step.instructions ?? "") {
                    Button {
                        startNativeTimer(duration: duration)
                    } label: {
                        Label("Set \(duration.formattedString) timer", systemImage: "timer")
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            
            Text(step.instructions ?? "")
            
            if let ingredients = step.ingredients as? Set<RecipeIngredient>, !ingredients.isEmpty {
                Text("Uses: " + ingredients.compactMap { $0.ingredient?.name }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func startNativeTimer(duration: StepDuration) {
        // Format the timer URL with components
        var components = URLComponents()
        components.scheme = "x-apple-timer"
        components.queryItems = [
            URLQueryItem(name: "minutes", value: String(duration.totalSeconds / 60))
        ]
        
        if let url = components.url {
            UIApplication.shared.open(url) { success in
                if !success {
                    // Fallback to Clock app if timer scheme fails
                    if let clockURL = URL(string: "clock:") {
                        UIApplication.shared.open(clockURL)
                    }
                }
            }
        }
    }
    
    private var stepsSection: some View {
        Group {
            if !currentRecipe.stepsArray.isEmpty {
                Section("Instructions") {
                    ForEach(currentRecipe.stepsArray) { step in
                        stepView(for: step)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
    }
    
    private var deleteSection: some View {
        Section {
            Button("Delete Recipe", role: .destructive) {
                showingDeleteAlert = true
            }
        }
    }
    
    var body: some View {
        List {
            recipeImage
            recipeDetails
            recipeDescription
            ingredientsSection
            stepsSection
            deleteSection
        }
        .id(refreshID)
        .navigationTitle(currentRecipe.name ?? "Recipe Details")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack {
                    Button {
                        showingCookingMode = true
                    } label: {
                        Image(systemName: "play.circle")
                    }
                    
                    Button {
                        showingEditSheet = true
                    } label: {
                        Text("Edit")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            refreshID = UUID()
        } content: {
            EditRecipeView(recipe: currentRecipe)
        }
        .sheet(isPresented: $showingCookingMode) {
            NavigationView {
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
    }
    
    private func deleteRecipe() {
        viewContext.delete(currentRecipe)
        try? viewContext.save()
        dismiss()
    }
} 