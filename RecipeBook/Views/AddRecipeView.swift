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
    @State private var steps: [RecipeStep] = []
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Recipe image and basic info
                    recipeImageSection
                    
                    // Description section
                    descriptionSection
                    
                    // Ingredients section
                    ingredientsSection
                    
                    // Steps section
                    stepsSection
                    
                    // Add some bottom padding
                    Color.clear.frame(height: 20)
                }
                .padding(.top, 16)
                .padding(.horizontal, dynamicTypeSize > .large ? 12 : 16)
            }
            .scrollIndicators(.visible)
            .dismissKeyboardOnTap()
            .navigationTitle("Create new recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRecipe()
                        dismiss()
                    }
                    .bold()
                    .disabled(name.isEmpty || selectedIngredients.isEmpty)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            isNameFocused = false
                            isDescriptionFocused = false
                        }
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .ingredients:
                    NavigationStack {
                        IngredientSelectionView(selectedIngredients: $selectedIngredients)
                    }
                case .imagePicker:
                    ImagePicker(image: $image)
                case .step(let stepSheet):
                    NavigationStack {
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
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFocused = true
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
                        .frame(width: min(200, UIScreen.main.bounds.width - 40), height: min(200, UIScreen.main.bounds.width - 40))
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(.systemGray6), lineWidth: 1))
                        .shadow(color: .black.opacity(0.1), radius: 8)
                        .accessibilityHidden(true)
                } else {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: min(200, UIScreen.main.bounds.width - 40), height: min(200, UIScreen.main.bounds.width - 40))
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
                .frame(width: min(200, UIScreen.main.bounds.width - 40), height: min(200, UIScreen.main.bounds.width - 40))
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
                .lineLimit(2)
                .minimumScaleFactor(0.8)
            
            // New stats section
            statsSection
        }
    }
    
    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Label("Recipe Details", systemImage: "stopwatch")
                .font(.headline)
                .foregroundStyle(.primary)
            
            // Stats container
            VStack(spacing: 0) {
                // Cooking time row
                cookingTimeRow
                
                Divider()
                    .padding(.horizontal)
                
                // Servings row
                servingsRow
                
                Divider()
                    .padding(.horizontal)
                
                // Difficulty row
                difficultyRow
            }
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var cookingTimeRow: some View {
        HStack(spacing: 12) {
            // Icon and label
            Label {
                Text("Cooking Time")
                    .foregroundStyle(.primary)
            } icon: {
                Image(systemName: "clock")
                    .foregroundStyle(.orange)
                    .frame(width: 24)
            }
            
            Spacer()
            
            // Time stepper with fixed width for better alignment
            HStack(spacing: 8) {
                Text(formatTime(timeInMinutes))
                    .foregroundStyle(.secondary)
                    .frame(width: 65, alignment: .trailing)
                    .monospacedDigit()
                
                // Custom stepper buttons for better control
                HStack(spacing: 0) {
                    Button {
                        if timeInMinutes > 5 {
                            timeInMinutes -= 5
                        } else if timeInMinutes > 1 {
                            timeInMinutes = 1
                        }
                    } label: {
                        Image(systemName: "minus")
                            .fontWeight(.semibold)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .disabled(timeInMinutes <= 1)
                    
                    Button {
                        if timeInMinutes < 480 {
                            timeInMinutes += 5
                        }
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .disabled(timeInMinutes >= 480)
                }
                .foregroundStyle(.primary)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
    }
    
    private var servingsRow: some View {
        HStack(spacing: 12) {
            // Icon and label
            Label {
                Text("Servings")
                    .foregroundStyle(.primary)
            } icon: {
                Image(systemName: "person.2")
                    .foregroundStyle(.orange)
                    .frame(width: 24)
            }
            
            Spacer()
            
            // Servings stepper with fixed width for better alignment
            HStack(spacing: 8) {
                Text("\(servings)")
                    .foregroundStyle(.secondary)
                    .frame(width: 65, alignment: .trailing)
                    .monospacedDigit()
                
                // Custom stepper buttons
                HStack(spacing: 0) {
                    Button {
                        if servings > 1 {
                            servings -= 1
                        }
                    } label: {
                        Image(systemName: "minus")
                            .fontWeight(.semibold)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .disabled(servings <= 1)
                    
                    Button {
                        if servings < 20 {
                            servings += 1
                        }
                    } label: {
                        Image(systemName: "plus")
                            .fontWeight(.semibold)
                    }
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
                    .disabled(servings >= 20)
                }
                .foregroundStyle(.primary)
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 54)
    }
    
    private var difficultyRow: some View {
        HStack(spacing: 12) {
            // Icon and label
            Label {
                Text("Difficulty")
                    .foregroundStyle(.primary)
            } icon: {
                Image(systemName: "gauge.medium")
                    .foregroundStyle(.orange)
                    .frame(width: 24)
            }
            
            Spacer()
            
            // Difficulty picker
            Menu {
                ForEach(Difficulty.allCases, id: \.self) { level in
                    Button {
                        difficulty = level
                    } label: {
                        if difficulty == level {
                            Label(level.rawValue.capitalized, systemImage: "checkmark")
                        } else {
                            Text(level.rawValue.capitalized)
                        }
                    }
                }
            } label: {
                HStack(spacing: 8) {
                    DifficultyPill(difficulty: difficulty)
                        .frame(width: 120, alignment: .trailing)
                    
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption)
                        .foregroundStyle(.gray)
                        .frame(width: 44, alignment: .leading)
                }
                .frame(width: 164, alignment: .trailing)
            }
        }
        .padding(.leading, 16)
        .frame(height: 54)
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
    }
    
    private var ingredientsList: some View {
        VStack(spacing: 0) {
            ForEach($selectedIngredients) { $ingredient in
                VStack {
                    if dynamicTypeSize > .large {
                        // Vertical layout for larger text sizes
                        VStack(alignment: .leading, spacing: 12) {
                            Text(ingredient.ingredient.name ?? "")
                                .font(.body)
                                .lineLimit(1)
                            
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
                            }
                        }
                    } else {
                        // Horizontal layout for normal text sizes
                        HStack {
                            Text(ingredient.ingredient.name ?? "")
                                .font(.body)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                            
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
                                .frame(maxWidth: 120)
                            }
                        }
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
    }
    
    // Add the steps section
    private var stepsSection: some View {
        VStack(alignment: .leading) {
            // Header
            HStack {
                Label("Steps", systemImage: "list.number")
                    .font(.title3.weight(.bold))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button {
                    activeSheet = .step(.add)
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
                }
            }
            
            if steps.isEmpty {
                emptyStepsView
            } else {
                stepsListView
            }
        }
    }
    
    private var emptyStepsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.number.circle")
                .font(.system(size: 50))
                .foregroundColor(.orange.opacity(0.5))
                .padding(.top, 20)
            
            Text("No steps added yet")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Button {
                activeSheet = .step(.add)
            } label: {
                Text("Add Steps")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 44)
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
    }
    
    private var stepsListView: some View {
        VStack(spacing: 8) {
            ForEach(steps.indices, id: \.self) { index in
                Button {
                    activeSheet = .step(.edit(steps[index]))
                } label: {
                    HStack(alignment: .top, spacing: 16) {
                        Text("\(index + 1)")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(.white)
                            .frame(width: 28, height: 28)
                            .background(Circle().fill(Color.orange))
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(steps[index].instructions)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.leading)
                                .lineLimit(4)
                            
                            if !steps[index].selectedIngredients.isEmpty {
                                Text("Uses \(steps[index].selectedIngredients.count) ingredient(s)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.footnote)
                            .foregroundStyle(.tertiary)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            Button {
                activeSheet = .step(.add)
            } label: {
                Label("Add More Steps", systemImage: "plus")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray6))
                    .foregroundColor(.orange)
                    .cornerRadius(8)
            }
        }
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
        
        // Save steps
        for step in steps {
            let newStep = Step(context: viewContext)
            newStep.recipe = recipe
            newStep.instructions = step.instructions
            newStep.order = step.order
            newStep.createdAt = Date()
            
            // Link ingredients to step
            for selectedIngredient in step.selectedIngredients {
                if let ri = recipe.recipeIngredientsArray.first(where: { 
                    $0.ingredient?.objectID == selectedIngredient.ingredient.objectID
                }) {
                    newStep.addToIngredients(ri)
                }
            }
        }
        
        try? viewContext.save()
    }
    
    private func formatTime(_ minutes: Int16) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }
    
    private func updateStepOrder() {
        for (index, _) in steps.enumerated() {
            steps[index].order = Int16(index)
        }
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
    case step(EditStepSheet)
    
    var id: String {
        switch self {
        case .imagePicker: return "imagePicker"
        case .ingredients: return "ingredients"
        case .step(let stepSheet): return "step-\(stepSheet.id)"
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    return AddRecipeView()
        .environment(\.managedObjectContext, context)
        .environmentObject(RecipeViewModel(viewContext: context))
} 
