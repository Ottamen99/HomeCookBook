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
        let recipeIngredients = recipe.recipeIngredientsArray
        _selectedIngredients = State(initialValue: recipeIngredients.map { ri in
            SelectedIngredient(
                ingredient: ri.ingredient!,
                quantity: ri.quantity,
                unit: UnitOfMeasure(rawValue: ri.unit ?? "") ?? .grams
            )
        })
        
        // Convert existing steps to RecipeStep
        if let existingSteps = recipe.steps as? Set<Step> {
            _steps = State(initialValue: existingSteps.map { step in
                RecipeStep(step: step)
            })
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack {
                        if let image = image {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .overlay(alignment: .topTrailing) {
                                    Button {
                                        withAnimation {
                                            self.image = nil
                                        }
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.title2)
                                            .foregroundStyle(.white, Color.gray.opacity(0.7))
                                            .padding(8)
                                    }
                                }
                        }
                        
                        Button {
                            activeSheet = .imagePicker
                        } label: {
                            HStack {
                                Image(systemName: image == nil ? "photo.badge.plus" : "photo.badge.plus.fill")
                                Text(image == nil ? "Add Photo" : "Change Photo")
                            }
                        }
                    }
                }
                
                Section("Recipe Details") {
                    TextField("Recipe Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                    HStack {
                        Image(systemName: "clock")
                            .foregroundColor(.blue)
                        Stepper("Time: \(timeInMinutes) minutes", value: $timeInMinutes, in: 1...480)
                    }
                    HStack {
                        Image(systemName: "person.2")
                            .foregroundColor(.blue)
                        Stepper("Servings: \(servings)", value: $servings, in: 1...20)
                    }
                }
                
                Section("Ingredients") {
                    ForEach($selectedIngredients) { $ingredient in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(ingredient.ingredient.name ?? "")
                                .font(.headline)
                            HStack {
                                TextField("Quantity", value: $ingredient.quantity, format: .number)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 80)
                                Picker("Unit", selection: $ingredient.unit) {
                                    ForEach(UnitOfMeasure.allCases, id: \.self) { unit in
                                        Text(unit.displayName).tag(unit)
                                    }
                                }
                                .pickerStyle(.menu)
                                Spacer()
                                Button(role: .destructive) {
                                    withAnimation {
                                        selectedIngredients.removeAll { $0.id == ingredient.id }
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                }
                            }
                        }
                    }
                    
                    Button {
                        activeSheet = .ingredients
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Ingredient")
                        }
                    }
                }
                
                Section("Steps") {
                    ForEach($steps) { $step in
                        StepRowView(step: $step, recipeIngredients: selectedIngredients) {
                            activeSheet = .step(.edit(step))
                        }
                    }
                    .onMove { from, to in
                        steps.move(fromOffsets: from, toOffset: to)
                        updateStepOrder()
                    }
                    .onDelete { indexSet in
                        steps.remove(atOffsets: indexSet)
                        updateStepOrder()
                    }
                    
                    Button {
                        activeSheet = .step(.add)
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Step")
                        }
                    }
                }
            }
            .navigationTitle("Edit Recipe")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecipe()
                        dismiss()
                    }
                    .disabled(name.isEmpty || selectedIngredients.isEmpty)
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
