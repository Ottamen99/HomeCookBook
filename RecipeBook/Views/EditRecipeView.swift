import SwiftUI

struct EditRecipeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe
    
    @State private var name: String
    @State private var description: String
    @State private var timeInMinutes: Int16
    @State private var servings: Int16
    @State private var selectedIngredients: [SelectedIngredient]
    @State private var image: UIImage?
    @State private var steps: [RecipeStep] = []
    @State private var activeSheet: EditRecipeSheet?
    
    init(recipe: Recipe) {
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
                        if timeInMinutes < 20 {
                            timeInMinutes += 1
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
        .padding(.top, 40)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    recipeImage
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Description")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        TextField("Add a description", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    
                    // Ingredients
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Ingredients")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button {
                                activeSheet = .ingredients
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                        
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
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    
                    // Add padding for the bottom button
                    Color.clear.frame(height: 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("Edit Recipe")
                        .font(.headline)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecipe()
                        dismiss()
                    }
                    .disabled(name.isEmpty || selectedIngredients.isEmpty)
                }
            }
            .safeAreaInset(edge: .bottom) {
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
                .background(.white)
            }
        }
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
    }
    
    private func updateStepOrder() {
        for (index, step) in steps.enumerated() {
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
            } catch {
                print("Error saving recipe: \(error)")
            }
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
