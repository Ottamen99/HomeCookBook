import SwiftUI

struct EditRecipeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.presentationMode) private var presentationMode
    @Binding var rootDismiss: Bool
    @Binding var refreshID: UUID
    let recipe: Recipe
    
    @State private var name: String
    @State private var description: String
    @State private var timeInMinutes: Int16
    @State private var servings: Int16
    @State private var selectedIngredients: [SelectedIngredient]
    @State private var image: UIImage?
    @State private var steps: [RecipeStep] = []
    @State private var activeSheet: EditRecipeSheet?
    @State private var showingDeleteAlert = false
    
    init(recipe: Recipe, rootDismiss: Binding<Bool>, refreshID: Binding<UUID>) {
        self.recipe = recipe
        _name = State(initialValue: recipe.name ?? "")
        _description = State(initialValue: recipe.desc ?? "")
        _timeInMinutes = State(initialValue: recipe.timeInMinutes)
        _servings = State(initialValue: recipe.servings)
        
        // Initialize image if exists
        if let imageData = recipe.imageData {
            _image = State(initialValue: UIImage(data: imageData))
        }
        
        // Convert existing recipe ingredients to selected ingredients
        let initialIngredients = recipe.recipeIngredientsArray.map { ri -> SelectedIngredient in
            let unit = UnitOfMeasure(rawValue: ri.unit ?? "") ?? .grams
            return SelectedIngredient(
                ingredient: ri.ingredient!,
                quantity: ri.quantity,
                unit: unit
            )
        }
        _selectedIngredients = State(initialValue: initialIngredients)
        
        // Convert existing steps to RecipeStep
        if let existingSteps = recipe.steps as? Set<Step> {
            _steps = State(initialValue: existingSteps.map { step in
                RecipeStep(step: step)
            })
        }
        
        _rootDismiss = rootDismiss
        _refreshID = refreshID
    }
    
    private var recipeImage: some View {
        VStack(spacing: 24) {
            // Circular image
            Group {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                        .frame(width: 250, height: 250)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(.systemGray6), lineWidth: 1))
                        .shadow(color: .black.opacity(0.1), radius: 8)
                } else {
                    Circle()
                        .fill(Color.gray.opacity(0.1))
                        .frame(width: 250, height: 250)
                        .overlay {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                        }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                        Button {
                            activeSheet = .imagePicker
                        } label: {
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white, Color.orange)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .offset(x: -8, y: -8)
            }
            
            // Recipe name input
            TextField("Recipe Name", text: $name)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Stats row
            HStack(spacing: 40) {
                // Time
                HStack(spacing: 4) {
                    Button(action: {
                        if timeInMinutes > 1 {
                            timeInMinutes -= 1
                            updateTimeInMinutes()
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
                        Text("\(timeInMinutes)")
                            .font(.title3)
                            .fontWeight(.bold)
                        Text("min")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 50)
                    
                    Button(action: {
                        if timeInMinutes < 480 {
                            timeInMinutes += 1
                            updateTimeInMinutes()
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
                
                // Servings
                HStack(spacing: 4) {
                    Button(action: { 
                        if servings > 1 {
                            servings -= 1
                            updateServings()
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
                            updateServings()
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
        .padding(.top, 40)
    }
    
    // Update toolbar buttons view
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
            
            Button {
                showingDeleteAlert = true
            } label: {
                Image(systemName: "trash")
                    .foregroundColor(.red)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.1), radius: 5)
            }
        }
        .padding(.horizontal)
    }
    
    // Add this view for the ingredient button
    private var addIngredientsButton: some View {
        Button {
            activeSheet = .ingredients
        } label: {
            VStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.1))
                    .frame(width: 60, height: 60)
                    .overlay {
                        Image(systemName: "plus")
                            .foregroundColor(.black)
                            .font(.system(size: 24))
                    }
                
                Text("Add Ingredients")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.black)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }
    
    // First, add a computed property for sorted steps
    private var sortedSteps: [RecipeStep] {
        steps.sorted { $0.order < $1.order }
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 0) {
                    recipeImage
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Description")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 100, maxHeight: 200)
                            .scrollContentBackground(.hidden)
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .padding()
                    
                    // Ingredients
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Ingredients")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if selectedIngredients.isEmpty {
                            addIngredientsButton
                        } else {
                    ForEach($selectedIngredients) { $ingredient in
                                HStack {
                            Text(ingredient.ingredient.name ?? "")
                                        .font(.body)
                                    
                                    Spacer()
                                    
                                    TextField("Qty", value: $ingredient.quantity, format: .number)
                                    .keyboardType(.decimalPad)
                                        .frame(width: 60)
                                        .multilineTextAlignment(.trailing)
                                    
                                Picker("Unit", selection: $ingredient.unit) {
                                    ForEach(UnitOfMeasure.allCases, id: \.self) { unit in
                                        Text(unit.displayName).tag(unit)
                                    }
                                }
                                .pickerStyle(.menu)
                                    .frame(width: 80)
                                }
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                            
                            // Add more ingredients button
                    Button {
                        activeSheet = .ingredients
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                    Text("Add more ingredients")
                                }
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding()
                    
                    // Steps section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Steps")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if steps.isEmpty {
                            Button {
                                activeSheet = .step(.add)
                            } label: {
                                VStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                        .overlay {
                                            Image(systemName: "plus")
                                                .foregroundColor(.black)
                                                .font(.system(size: 24))
                                        }
                                    
                                    Text("Add Steps")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.black)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                        } else {
                            ForEach(sortedSteps) { step in
                                StepRowView(
                                    step: .constant(step),
                                    recipeIngredients: selectedIngredients
                                ) {
                                    activeSheet = .step(.edit(step))
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                            
                            // Add more steps button
                            Button {
                                activeSheet = .step(.add)
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add more steps")
                                }
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding()
                    
                    // Add padding for the bottom button
                    Color.clear.frame(height: 100)
                }
            }
            
            // Overlay toolbar at top
            VStack {
                toolbarButtons
                    .padding(.top, 8)
                
                Spacer()
                
                // Bottom save button with solid background
                ZStack {
                    // Solid background that extends to bottom safe area
                    Rectangle()
                        .fill(Color(.systemBackground))
                        .edgesIgnoringSafeArea(.bottom)
                        .frame(height: 100)
                        .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
                    
                    Button(action: {
                        saveRecipe()
                        dismiss()
                    }) {
                        Text("Save Recipe")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.black)
                            .cornerRadius(12)
                    }
                    .disabled(name.isEmpty || selectedIngredients.isEmpty)
                    .padding()
                }
            }
        }
        .navigationBarHidden(true)
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .ingredients:
                    IngredientSelectionView(selectedIngredients: $selectedIngredients)
                case .imagePicker:
                    ImagePicker(image: $image)
                case .step(let stepSheet):
                    NavigationView {
                        switch stepSheet {
                        case .add:
                            StepFormView(
                                step: nil,
                                recipeIngredients: selectedIngredients
                            ) { newStep in
                                steps.append(newStep)
                                updateStepOrder()
                                activeSheet = nil
                            }
                        case .edit(let step):
                            StepFormView(
                                step: step,
                                recipeIngredients: selectedIngredients
                            ) { newStep in
                                if let index = steps.firstIndex(where: { $0.id == step.id }) {
                                    steps[index] = newStep
                                }
                                updateStepOrder()
                                activeSheet = nil
                            }
                        }
                    }
                }
            }
        // Add delete alert
        .alert("Delete Recipe", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteRecipe()
            }
        } message: {
            Text("Are you sure you want to delete this recipe? This action cannot be undone.")
        }
    }
    
    private func updateStepOrder() {
        for (index, _) in steps.enumerated() {
            steps[index].order = Int16(index)
        }
    }
    
    private func saveRecipe() {
        viewContext.perform {
            // Save basic recipe details
            recipe.name = name
            recipe.desc = description
            recipe.timeInMinutes = timeInMinutes
            recipe.servings = servings
            
            // Save image data
            if let image = image {
                recipe.imageData = image.jpegData(compressionQuality: 0.8)
            } else {
                recipe.imageData = nil
            }
            
            // First, create a dictionary of all recipe ingredients we'll need
            var recipeIngredients: [String: RecipeIngredient] = [:]
            
            // Helper function to get or create a RecipeIngredient
            func getOrCreateRecipeIngredient(for selected: SelectedIngredient) -> RecipeIngredient {
                let key = "\(selected.ingredient.objectID)_\(selected.quantity)_\(selected.unit.rawValue)"
                if let existing = recipeIngredients[key] {
                    return existing
                }
                
                let ri = RecipeIngredient(context: viewContext)
                ri.recipe = recipe
                ri.ingredient = selected.ingredient
                ri.quantity = selected.quantity
                ri.unit = selected.unit.rawValue
                recipeIngredients[key] = ri
                return ri
            }
            
            // Remove all existing recipe ingredients
            if let existingIngredients = recipe.recipeIngredients as? Set<RecipeIngredient> {
                existingIngredients.forEach { viewContext.delete($0) }
            }
            
            // Add new recipe ingredients from the ingredients list
            for selected in selectedIngredients {
                _ = getOrCreateRecipeIngredient(for: selected)
            }
            
            // Remove all existing steps
            if let existingSteps = recipe.steps as? Set<Step> {
                existingSteps.forEach { viewContext.delete($0) }
            }
            
            // Add new steps
            for step in steps {
                let newStep = Step(context: viewContext)
                newStep.recipe = recipe
                newStep.instructions = step.instructions
                newStep.order = step.order
                newStep.createdAt = Date()
                
                // Link ingredients to step
                for selectedIngredient in step.selectedIngredients {
                    let recipeIngredient = getOrCreateRecipeIngredient(for: selectedIngredient)
                    newStep.addToIngredients(recipeIngredient)
                }
            }
            
            // Save all changes
            do {
                try viewContext.save()
                viewContext.refresh(recipe, mergeChanges: true)
                refreshID = UUID()
            } catch {
                print("Error saving recipe: \(error)")
            }
        }
    }
    
    // Update delete function
    private func deleteRecipe() {
        viewContext.delete(recipe)
        try? viewContext.save()
        dismiss()  // Dismiss the edit sheet
        rootDismiss = true  // Trigger dismiss of the detail view
    }
    
    private func updateServings() {
        viewContext.perform {
            recipe.servings = servings
            try? viewContext.save()
            viewContext.refresh(recipe, mergeChanges: true)
            refreshID = UUID()  // This will trigger a refresh of the view
        }
    }
    
    private func updateTimeInMinutes() {
        viewContext.perform {
            recipe.timeInMinutes = timeInMinutes
            try? viewContext.save()
            viewContext.refresh(recipe, mergeChanges: true)
            refreshID = UUID()  // This will trigger a refresh of the view
        }
    }
}

enum EditRecipeSheet: Identifiable {
    case ingredients
    case imagePicker
    case step(StepSheet)
    
    var id: String {
        switch self {
        case .ingredients:
            return "ingredients"
        case .imagePicker:
            return "imagePicker"
        case .step(let stepSheet):
            return "step-\(stepSheet.id)"
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    // Create a sample recipe
    let recipe = Recipe(context: context)
    recipe.name = "Classic Pancakes"
    recipe.desc = "Fluffy and delicious homemade pancakes perfect for breakfast."
    recipe.timeInMinutes = 20
    recipe.servings = 4
    recipe.difficulty = Difficulty.easy.rawValue
    
    // Add some ingredients
    let ingredients = [
        ("All-purpose Flour", 200.0, "grams"),
        ("Milk", 240.0, "ml"),
        ("Eggs", 2.0, "pieces"),
        ("Sugar", 30.0, "grams"),
        ("Baking Powder", 10.0, "grams"),
        ("Salt", 5.0, "grams"),
        ("Butter", 30.0, "grams")
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
        "In a large bowl, whisk together flour, sugar, baking powder, and salt.",
        "In another bowl, whisk milk, eggs, and melted butter.",
        "Pour wet ingredients into dry ingredients and mix until just combined.",
        "Heat a non-stick pan over medium heat.",
        "Pour 1/4 cup batter for each pancake and cook until bubbles form.",
        "Flip and cook other side until golden brown."
    ]
    
    for (index, instructions) in steps.enumerated() {
        let step = Step(context: context)
        step.recipe = recipe
        step.instructions = instructions
        step.order = Int16(index)
        step.createdAt = Date()
    }
    
    try? context.save()
    
    return NavigationStack {
        EditRecipeView(
            recipe: recipe,
            rootDismiss: .constant(false),
            refreshID: .constant(UUID())
        )
        .environment(\.managedObjectContext, context)
    }
} 
