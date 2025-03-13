import SwiftUI

struct AddRecipeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @EnvironmentObject private var viewModel: RecipeViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ingredient.name, ascending: true)],
        animation: .default)
    private var ingredients: FetchedResults<Ingredient>
    
    @State private var name = ""
    @State private var description = ""
    @State private var timeInMinutes: Int16 = 30
    @State private var servings: Int16 = 2
    @State private var selectedIngredients: [SelectedIngredient] = []
    @State private var showingIngredientSheet = false
    @State private var image: UIImage?
    @State private var activeSheet: AddRecipeSheet?
    @State private var difficulty: Difficulty = .medium
    @FocusState private var isNameFocused: Bool
    @FocusState private var isDescriptionFocused: Bool
    
    // MARK: - Body
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                // Recipe image and basic info
                recipeImageSection
                
                // Description section
                descriptionSection
                
                // Ingredients section
                ingredientsSection
                
                // Add padding for the bottom button
                Color.clear.frame(height: 80)
            }
            .padding(.top, 16)
        }
        .scrollIndicators(.visible)
        .dismissKeyboardOnTap()
        .overlay(alignment: .top) {
            headerOverlay
        }
        .safeAreaInset(edge: .bottom) {
            createRecipeButton
        }
        .navigationBarHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .ingredients:
                NavigationStack {
                    IngredientSelectionView(selectedIngredients: $selectedIngredients)
                }
            case .imagePicker:
                ImagePicker(image: $image)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    isNameFocused = false
                    isDescriptionFocused = false
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    private var recipeImageSection: some View {
        VStack(spacing: dynamicTypeSize > .large ? 16 : 24) {
            // Recipe image
            ZStack {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(.systemGray6), lineWidth: 1))
                        .shadow(color: .black.opacity(0.1), radius: 8)
                        .accessibilityHidden(true)
                } else {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 200, height: 200)
                        .overlay {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.orange)
                        }
                        .accessibilityHidden(true)
                }
                
                // Camera button
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Button {
                            activeSheet = .imagePicker
                        } label: {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .frame(width: 48, height: 48) // Slightly larger for better visibility
                                .background(Color.orange)
                                .clipShape(Circle())
                                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                        }
                        .accessibilityLabel("Add recipe photo")
                        .offset(x: -8, y: -8)
                    }
                }
                .frame(width: 200, height: 200)
            }
            
            // Recipe name input
            TextField("Recipe Name", text: $name)
                .font(.title2.weight(.bold))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .focused($isNameFocused)
                .accessibilityLabel("Recipe name")
                .submitLabel(.next)
                .onSubmit {
                    isDescriptionFocused = true
                }
            
            // Stats row
            statsRow
        }
    }
    
    private var statsRow: some View {
        VStack(spacing: 16) {
            // For larger dynamic type sizes, stack controls vertically
            if dynamicTypeSize > .large {
                VStack(spacing: 20) {
                    timeControl
                    servingsControl
                    difficultyControl
                }
            } else {
                HStack(spacing: 24) {
                    timeControl
                    servingsControl
                    difficultyControl
                }
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? 
                      Color(UIColor.secondarySystemBackground) : 
                      Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
    
    private var timeControl: some View {
        VStack(spacing: 8) {
            Text("Time")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Button(action: {
                    if timeInMinutes > 5 {
                        timeInMinutes -= 5
                    }
                }) {
                    Image(systemName: "minus")
                        .foregroundColor(timeInMinutes <= 5 ? .secondary : .primary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
                .disabled(timeInMinutes <= 5)
                .accessibilityLabel("Decrease cooking time")
                
                VStack(spacing: 2) {
                    Text("\(timeInMinutes)")
                        .font(.headline)
                    Text("min")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(minWidth: 50)
                .accessibilityLabel("\(timeInMinutes) minutes cooking time")
                
                Button(action: {
                    if timeInMinutes < 480 {
                        timeInMinutes += 5
                    }
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(timeInMinutes >= 480 ? .secondary : .primary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
                .disabled(timeInMinutes >= 480)
                .accessibilityLabel("Increase cooking time")
            }
        }
    }
    
    private var servingsControl: some View {
        VStack(spacing: 8) {
            Text("Servings")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                Button(action: { 
                    if servings > 1 {
                        servings -= 1
                    }
                }) {
                    Image(systemName: "minus")
                        .foregroundColor(servings <= 1 ? .secondary : .primary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
                .disabled(servings <= 1)
                .accessibilityLabel("Decrease servings")
                
                VStack(spacing: 2) {
                    Text("\(servings)")
                        .font(.headline)
                    Text("serve")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(minWidth: 50)
                .accessibilityLabel("\(servings) servings")
                
                Button(action: { 
                    if servings < 20 {
                        servings += 1
                    }
                }) {
                    Image(systemName: "plus")
                        .foregroundColor(servings >= 20 ? .secondary : .primary)
                        .frame(width: 44, height: 44)
                        .background(
                            Circle()
                                .fill(Color.secondary.opacity(0.1))
                        )
                }
                .disabled(servings >= 20)
                .accessibilityLabel("Increase servings")
            }
        }
    }
    
    private var difficultyControl: some View {
        VStack(spacing: 8) {
            Text("Difficulty")
                .font(.subheadline.weight(.medium))
                .foregroundColor(.secondary)
            
            Menu {
                Picker("Difficulty", selection: $difficulty) {
                    ForEach(Difficulty.allCases, id: \.self) { level in
                        Label {
                            Text(level.rawValue)
                        } icon: {
                            Image(systemName: level.icon)
                                .foregroundColor(level.color)
                        }
                        .tag(level)
                    }
                }
            } label: {
                VStack(spacing: 4) {
                    Image(systemName: difficulty.icon)
                        .font(.headline)
                        .foregroundColor(difficulty.color)
                        .frame(height: 24)
                    
                    Text(difficulty.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.secondary.opacity(0.1))
                )
                .contentShape(Rectangle())
            }
            .accessibilityLabel("Select difficulty: \(difficulty.rawValue)")
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Description")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                if !description.isEmpty {
                    Text("\(description.count) characters")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            
            TextEditor(text: $description)
                .frame(minHeight: 120)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(colorScheme == .dark ? 
                              Color(UIColor.secondarySystemBackground) : 
                              Color(UIColor.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                )
                .focused($isDescriptionFocused)
                .padding(.horizontal, 20)
                .accessibilityLabel("Recipe description")
        }
    }
    
    private var ingredientsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Ingredients")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    activeSheet = .ingredients
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                        Text("Add")
                    }
                    .font(.headline)
                    .foregroundColor(.orange)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.1))
                    )
                    .contentShape(Capsule())
                }
                .accessibilityLabel("Add ingredients")
            }
            .padding(.horizontal, 20)
            
            if selectedIngredients.isEmpty {
                emptyIngredientsView
            } else {
                ingredientsList
            }
        }
    }
    
    private var emptyIngredientsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "leaf.circle")
                .font(.system(size: 50))
                .foregroundColor(.orange.opacity(0.5))
                .padding(.top, 20)
            
            Text("No ingredients added yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button {
                activeSheet = .ingredients
            } label: {
                Text("Add Ingredients")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 44) // 44pt minimum hit target
                    .frame(maxWidth: 200)
                    .background(Color.orange)
                    .cornerRadius(10)
            }
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? 
                      Color(UIColor.secondarySystemBackground) : 
                      Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
    
    private var ingredientsList: some View {
        VStack(spacing: 0) {
            ForEach($selectedIngredients) { $ingredient in
                HStack {
                    Text(ingredient.ingredient.name ?? "")
                        .font(.body)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    HStack(spacing: 12) {
                        TextField("Qty", value: $ingredient.quantity, format: .number)
                            .keyboardType(.decimalPad)
                            .frame(width: 60)
                            .multilineTextAlignment(.trailing)
                            .padding(8)
                            .background(Color.secondary.opacity(0.1))
                            .cornerRadius(8)
                        
                        Picker("Unit", selection: $ingredient.unit) {
                            ForEach(UnitOfMeasure.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .foregroundColor(.orange)
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                }
                .padding(.vertical, 12) // Increased for better hit target
                .padding(.horizontal, 16)
                .background(
                    RoundedRectangle(cornerRadius: 0)
                        .fill(Color.clear)
                )
                
                Divider()
                    .padding(.horizontal, 16)
            }
            
            // Add button to add more ingredients
            Button {
                activeSheet = .ingredients
            } label: {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Add More Ingredients")
                }
                .font(.subheadline)
                .foregroundColor(.orange)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? 
                      Color(UIColor.secondarySystemBackground) : 
                      Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.horizontal, 20)
    }
    
    private var headerOverlay: some View {
        HStack {
            // Back button
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44) // 44pt minimum hit target
                    .background(
                        Circle()
                            .fill(colorScheme == .dark ? 
                                  Color(UIColor.secondarySystemBackground) : 
                                  Color(UIColor.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 1)
                    )
            }
            .accessibilityLabel("Cancel")
            
            Spacer()
            
            Text("New Recipe")
                .font(.headline)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Placeholder to balance the layout
            Color.clear
                .frame(width: 44, height: 44)
        }
        .padding(16)
        .background(
            Rectangle()
                .fill(colorScheme == .dark ? 
                      Color(UIColor.systemBackground) : 
                      Color.white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
    }
    
    private var createRecipeButton: some View {
        Button(action: {
            saveRecipe()
            dismiss()
        }) {
            Text("Create Recipe")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54) // Taller button for better hit target
                .background(
                    name.isEmpty || selectedIngredients.isEmpty ? 
                    Color.gray : Color.orange
                )
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        }
        .disabled(name.isEmpty || selectedIngredients.isEmpty)
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(colorScheme == .dark ? 
                      Color(UIColor.systemBackground) : 
                      Color.white)
                .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
                .edgesIgnoringSafeArea(.bottom)
        )
    }
    
    // MARK: - Helper Functions
    
    private func saveRecipe() {
        let recipe = Recipe(context: viewContext)
        recipe.name = name
        recipe.desc = description
        recipe.timeInMinutes = timeInMinutes
        recipe.servings = servings
        recipe.difficulty = difficulty.rawValue
        
        // Save image data
        if let image = image {
            recipe.imageData = image.jpegData(compressionQuality: 0.8)
        } else {
            // Create default image
            let defaultImage = UIImage(systemName: "fork.knife.circle.fill")?
                .withTintColor(.orange)
                .withRenderingMode(.alwaysOriginal)
            recipe.imageData = defaultImage?.jpegData(compressionQuality: 1.0)
        }
        
        // Save ingredients
        for selected in selectedIngredients {
            let recipeIngredient = RecipeIngredient(context: viewContext)
            recipeIngredient.recipe = recipe
            recipeIngredient.ingredient = selected.ingredient
            recipeIngredient.quantity = selected.quantity
            recipeIngredient.unit = selected.unit.rawValue
        }
        
        try? viewContext.save()
    }
}

struct SelectedIngredient: Identifiable {
    let id = UUID()
    let ingredient: Ingredient
    var quantity: Double
    var unit: UnitOfMeasure
}

enum AddRecipeSheet: Identifiable {
    case imagePicker
    case ingredients
    
    var id: Int {
        switch self {
        case .imagePicker: return 0
        case .ingredients: return 1
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    return NavigationStack {
        AddRecipeView()
            .environment(\.managedObjectContext, context)
            .environmentObject(RecipeViewModel(viewContext: context))
    }
} 
