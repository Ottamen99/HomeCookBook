import SwiftUI
import CoreData

struct RecipeDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    let recipe: Recipe  // Change back to let
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var servings: Int16
    @State private var refreshID = UUID()
    @State private var showingCookingMode = false
    @State private var scrollOffset: CGFloat = 0
    private let imageHeight: CGFloat = 300
    
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
    
    private var recipeStats: some View {
        HStack(spacing: 40) {
            StatView(value: "\(currentRecipe.timeInMinutes)", label: "min")
            StatView(value: "\(String(format: "%.0f", 270))", label: "grams") // Hardcoded for now
            StatView(value: "\(servings)", label: "serve")
        }
    }
    
    private struct StatView: View {
        let value: String
        let label: String
        
        var body: some View {
            VStack(spacing: 4) {
                Text(value)
                    .fontWeight(.semibold)
                Text(label)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
    
    private var recipeTags: some View {
        HStack(spacing: 12) {
            ForEach(["Lunch", "Shrimps", "Easy"], id: \.self) { tag in
                Text(tag)
                    .font(.subheadline)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
        }
    }
    
    private var recipeImage: some View {
        Group {
            if let imageData = currentRecipe.imageData,
               let uiImage = UIImage(data: imageData) {
                VStack(spacing: 24) {
                    // Circular image
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 250, height: 250)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(.systemGray6), lineWidth: 1))
                        .shadow(color: .black.opacity(0.1), radius: 8)
                        .padding(.top, 40)
                    
                    // Recipe name
                    Text(currentRecipe.name ?? "")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Stats row
                    HStack(spacing: 40) {
                        
                        if let difficultyString = currentRecipe.difficulty,
                           let difficulty = Difficulty(rawValue: difficultyString) {
                            DifficultyPill(difficulty: difficulty)
                        }
                        
                        StatView(value: "25", label: "min")
                        
                        // Servings control
                        HStack(spacing: 4) {
                            Button(action: { 
                                if servings > 1 {
                                    servings -= 1
                                }
                            }) {
                                Image(systemName: "minus")
                                    .foregroundColor(.black)
                                    .frame(width: 20, height: 20)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(Circle())
                            }
                            
                            VStack {
                                Text("\(servings)")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("serve")
                                    .foregroundColor(.gray)
                            }
                            .frame(width: 50)
                            
                            Button(action: { 
                                if servings < 20 {
                                    servings += 1
                                }
                            }) {
                                Image(systemName: "plus")
                                    .foregroundColor(.black)
                                    .frame(width: 20, height: 20)
                                    .padding(8)
                                    .background(Color.gray.opacity(0.1))
                                    .clipShape(Circle())
                            }
                        }
                        .font(.body)
                    }
                    .padding()
                    .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(.gray, lineWidth: 0.5)
                        )
                }
                .padding(.bottom, 20)
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
        return HStack {
            if let ingredient = recipeIngredient.ingredient {
                Text(ingredient.name ?? "")
                    .font(.body)
                
                Spacer()
                
                Text(String(format: "%.1f %@", scaledQuantity, recipeIngredient.unit ?? ""))
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
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
    
    // Create a separate view for the toolbar buttons
    private var toolbarButtons: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.1), radius: 5)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                Button(action: { showingEditSheet = true }) {
                    Image(systemName: "pencil")
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(color: .black.opacity(0.1), radius: 5)
                }
            }
        }
        .padding(.horizontal)
    }
    
    // Update the body view
    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                // Main content
                ScrollView {
                    VStack(spacing: 0) {
                        recipeImage
                        
                        // Ingredients section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Ingredients")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            ForEach(ingredients) { recipeIngredient in
                                let scaledQuantity = recipeIngredient.quantity * Double(servings) / Double(currentRecipe.servings)
                                HStack {
                                    if let ingredient = recipeIngredient.ingredient {
                                        Text(ingredient.name ?? "")
                                            .font(.body)
                                        
                                        Spacer()
                                        
                                        Text(String(format: "%.1f %@", scaledQuantity, recipeIngredient.unit ?? ""))
                                            .foregroundColor(.gray)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        .padding()
                        
                        // Add padding at the bottom for the fixed button
                        Color.clear.frame(height: 100)
                    }
                }
                
                // Overlay toolbar at top
                VStack {
                    toolbarButtons
                        .padding(.top, 8)
                    
                    Spacer()
                    
                    // Fixed Start cooking button at bottom
                    VStack {
                        Button(action: { showingCookingMode = true }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start cooking")
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(12)
                        }
                        .padding()
                    }
                    .background(
                        Rectangle()
                            .fill(.white)
                            .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
                    )
                }
            }
            .navigationBarHidden(true)
            .toolbar(.hidden, for: .tabBar)
        }
        .id(refreshID)
        .sheet(isPresented: $showingEditSheet) {
            refreshID = UUID()
        } content: {
            NavigationStack {
                EditRecipeView(recipe: currentRecipe)
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
    }
    
    private func deleteRecipe() {
        viewContext.delete(currentRecipe)
        try? viewContext.save()
        dismiss()
    }
    
    // Change IngredientsListView to a computed property to avoid redeclaration
    private var ingredientsListView: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Ingredients")
                .font(.headline)
            
            ForEach(ingredients) { recipeIngredient in
                let scaledQuantity = recipeIngredient.quantity * Double(servings) / Double(currentRecipe.servings)
                HStack {
                    if let ingredient = recipeIngredient.ingredient {
                        Text(ingredient.name ?? "")
                            .font(.body)
                        
                        Spacer()
                        
                        Text(String(format: "%.1f %@", scaledQuantity, recipeIngredient.unit ?? ""))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .padding(.vertical)
    }
}

// Add these supporting views
private struct ServingsControlView: View {
    @Binding var servings: Int16
    
    var body: some View {
        HStack {
            Spacer()
            Button(action: { 
                if servings > 1 {
                    servings -= 1
                }
            }) {
                Image(systemName: "minus")
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
            
            Text("\(servings)")
                .font(.title2)
                .fontWeight(.bold)
                .frame(width: 50)
            
            Button(action: { 
                if servings < 20 {
                    servings += 1
                }
            }) {
                Image(systemName: "plus")
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Circle())
            }
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

// Add helper view for difficulty pill
private struct DifficultyPill: View {
    let difficulty: Difficulty
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: difficulty.icon)
            Text(difficulty.rawValue)
        }
        .font(.subheadline)
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(difficulty.color)
        .clipShape(Capsule())
    }
} 
