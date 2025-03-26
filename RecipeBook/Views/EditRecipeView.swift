import SwiftUI
import CoreData

// Create a separate view model to offload state management
class EditRecipeViewModel: ObservableObject {
    @Published var name: String
    @Published var description: String
    @Published var timeInMinutes: Int16
    @Published var servings: Int16
    @Published var selectedIngredients: [SelectedIngredient]
    @Published var image: UIImage?
    @Published var steps: [RecipeStep] = []
    @Published var hasChanges = false
    @Published var difficulty: Difficulty
    
    let recipe: Recipe
    
    init(recipe: Recipe) {
        self.recipe = recipe
        self.name = recipe.name ?? ""
        self.description = recipe.desc ?? ""
        self.timeInMinutes = recipe.timeInMinutes
        self.servings = recipe.servings
        self.difficulty = Difficulty(rawValue: recipe.difficulty ?? Difficulty.easy.rawValue) ?? .easy
        
        // Initialize image if exists
        if let imageData = recipe.imageData {
            self.image = UIImage(data: imageData)
        }
        
        // Convert existing recipe ingredients to selected ingredients
        self.selectedIngredients = recipe.recipeIngredientsArray.map { ri -> SelectedIngredient in
            let unit = UnitOfMeasure(rawValue: ri.unit ?? "") ?? .grams
            return SelectedIngredient(
                ingredient: ri.ingredient!,
                quantity: ri.quantity,
                unit: unit
            )
        }
        
        // Convert existing steps to RecipeStep
        if let existingSteps = recipe.steps as? Set<Step> {
            self.steps = existingSteps.map { step in
                RecipeStep(step: step)
            }
        }
    }
    
    var sortedSteps: [RecipeStep] {
        steps.sorted { $0.order < $1.order }
    }
    
    func updateStepOrder() {
        for (index, _) in steps.enumerated() {
            steps[index].order = Int16(index)
        }
    }
    
    func formatTime(_ minutes: Int16) -> String {
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }
    
    func saveRecipe(viewContext: NSManagedObjectContext, completion: @escaping (Bool) -> Void) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        
        viewContext.perform {
            // Save basic recipe details
            self.recipe.name = self.name
            self.recipe.desc = self.description
            self.recipe.timeInMinutes = self.timeInMinutes
            self.recipe.servings = self.servings
            self.recipe.difficulty = self.difficulty.rawValue
            
            // Save image data
            if let image = self.image {
                self.recipe.imageData = image.jpegData(compressionQuality: 0.8)
            } else {
                self.recipe.imageData = nil
            }
            
            // Process recipe ingredients
            let existingIngredients = self.recipe.recipeIngredients as? Set<RecipeIngredient> ?? []
            existingIngredients.forEach { viewContext.delete($0) }
            
            // Add new recipe ingredients
            for selected in self.selectedIngredients {
                let ri = RecipeIngredient(context: viewContext)
                ri.recipe = self.recipe
                ri.ingredient = selected.ingredient
                ri.quantity = selected.quantity
                ri.unit = selected.unit.rawValue
            }
            
            // Process steps
            let existingSteps = self.recipe.steps as? Set<Step> ?? []
            existingSteps.forEach { viewContext.delete($0) }
            
            // Add new steps with simplified ingredient linking
            self.saveSteps(viewContext: viewContext)
            
            // Save all changes
            do {
                try viewContext.save()
                viewContext.refresh(self.recipe, mergeChanges: true)
                
                // Call completion on the main thread
                DispatchQueue.main.async {
                    generator.notificationOccurred(.success)
                    self.hasChanges = false
                    completion(true)
                }
            } catch {
                print("Error saving recipe: \(error)")
                
                // Call completion on the main thread
                DispatchQueue.main.async {
                    generator.notificationOccurred(.error)
                    completion(false)
                }
            }
        }
    }
    
    private func saveSteps(viewContext: NSManagedObjectContext) {
        // Create a dictionary for faster lookup
        var recipeIngredientDict: [String: RecipeIngredient] = [:]
        
        if let recipeIngredients = recipe.recipeIngredients as? Set<RecipeIngredient> {
            for ri in recipeIngredients {
                if let ingredient = ri.ingredient {
                    let key = "\(ingredient.objectID.uriRepresentation().absoluteString)-\(ri.quantity)-\(ri.unit ?? "")"
                    recipeIngredientDict[key] = ri
                }
            }
        }
        
        // Add new steps
        for step in steps {
            let newStep = Step(context: viewContext)
            newStep.recipe = recipe
            newStep.instructions = step.instructions
            newStep.order = step.order
            newStep.createdAt = Date()
            
            // Link ingredients to step - simplified
            for selectedIngredient in step.selectedIngredients {
                if let ri = recipe.recipeIngredientsArray.first(where: { 
                    $0.ingredient?.objectID == selectedIngredient.ingredient.objectID
                }) {
                    newStep.addToIngredients(ri)
                }
            }
        }
    }
    
    func deleteRecipe(viewContext: NSManagedObjectContext) -> Bool {
        let generator = UINotificationFeedbackGenerator()
        
        viewContext.delete(recipe)
        
        do {
            try viewContext.save()
            generator.notificationOccurred(.success)
            return true
        } catch {
            generator.notificationOccurred(.error)
            print("Error deleting recipe: \(error)")
            return false
        }
    }
    
    var isNewRecipe: Bool {
        // A recipe is considered new if it has no name or no ingredients/steps
        return recipe.name?.isEmpty ?? true || 
               (recipe.recipeIngredients?.count ?? 0) == 0 || 
               (recipe.steps?.count ?? 0) == 0
    }
}

// Main view with simplified structure
struct EditRecipeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var viewModel: EditRecipeViewModel
    @Binding var rootDismiss: Bool
    @Binding var refreshID: UUID
    
    @State private var activeSheet: EditRecipeSheet?
    @State private var showingDeleteAlert = false
    @State private var showUnsavedChangesAlert = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name
        case description
    }
    
    init(recipe: Recipe, rootDismiss: Binding<Bool>, refreshID: Binding<UUID>) {
        _viewModel = StateObject(wrappedValue: EditRecipeViewModel(recipe: recipe))
        _rootDismiss = rootDismiss
        _refreshID = refreshID
    }
    
    var body: some View {
        NavigationStack {
            // Use FormSections for better performance
            FormContent(
                viewModel: viewModel,
                activeSheet: $activeSheet,
                showingDeleteAlert: $showingDeleteAlert,
                focusedNameBinding: $focusedField
            )
            .navigationTitle("Edit Recipe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        if viewModel.hasChanges {
                            showUnsavedChangesAlert = true
                } else {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        // Show a loading indicator if needed
                        viewModel.saveRecipe(viewContext: viewContext) { success in
                            if success {
                                refreshID = UUID()
                                dismiss()
                            }
                            // Handle failure case if needed
                        }
                    }
                    .bold()
                    .disabled(viewModel.name.isEmpty || viewModel.selectedIngredients.isEmpty)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button("Done") {
                            focusedField = nil
                        }
                    }
                }
            }
            .sheets(activeSheet: $activeSheet, viewModel: viewModel)
            .alerts(
                showingDeleteAlert: $showingDeleteAlert,
                showUnsavedChangesAlert: $showUnsavedChangesAlert,
                viewModel: viewModel,
                viewContext: viewContext,
                dismiss: dismiss,
                rootDismiss: $rootDismiss
            )
        }
    }
}

// Extracted form content to reduce nesting
struct FormContent: View {
    @ObservedObject var viewModel: EditRecipeViewModel
    @Binding var activeSheet: EditRecipeSheet?
    @Binding var showingDeleteAlert: Bool
    var focusedNameBinding: FocusState<EditRecipeView.Field?>.Binding
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Image and name in a section
                ImageNameSection(
                    image: $viewModel.image,
                    name: $viewModel.name,
                    focusedFieldBinding: focusedNameBinding,
                    onImageTap: { activeSheet = .imagePicker }
                )
                
                // Description section
                VStack(alignment: .leading) {
                    Text("Description").font(.headline)
                    TextEditor(text: $viewModel.description)
                        .frame(minHeight: 100)
                        .padding(4)
                        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemGray6)))
                        .focused(focusedNameBinding, equals: .description)
                }
                .padding(.horizontal)
                
                // Recipe stats with difficulty
                RecipeStatsSection(
                    timeInMinutes: $viewModel.timeInMinutes,
                    servings: $viewModel.servings,
                    difficulty: $viewModel.difficulty,
                    formatTime: viewModel.formatTime
                )
                
                // Ingredients section
                IngredientsListSection(
                    ingredients: $viewModel.selectedIngredients,
                    onAddTap: { activeSheet = .ingredients }
                )
                
                // Steps section
                RecipeStepsSection(
                    steps: viewModel.sortedSteps,
                    onAddTap: { activeSheet = .step(.add) },
                    onStepTap: { step in activeSheet = .step(.edit(step)) }
                )
                
                // Delete button
                if !viewModel.isNewRecipe {
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                        } label: {
                        Label("Delete Recipe", systemImage: "trash")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(8)
                    }
                    .padding(.horizontal)
                }
                
                Spacer(minLength: 40)
            }
            .padding(.vertical)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - View Modifiers and Extensions
// These are extracted to improve compilation times

extension View {
    func sheets(activeSheet: Binding<EditRecipeSheet?>, viewModel: EditRecipeViewModel) -> some View {
        sheet(item: activeSheet) { sheet in
            SheetContent(sheet: sheet, viewModel: viewModel, activeSheet: activeSheet)
        }
    }
    
    func alerts(
        showingDeleteAlert: Binding<Bool>,
        showUnsavedChangesAlert: Binding<Bool>,
        viewModel: EditRecipeViewModel,
        viewContext: NSManagedObjectContext,
        dismiss: DismissAction,
        rootDismiss: Binding<Bool>
    ) -> some View {
        self
            .alert("Delete Recipe", isPresented: showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if viewModel.deleteRecipe(viewContext: viewContext) {
                        dismiss()
                        rootDismiss.wrappedValue = true
                    }
                }
            } message: {
                Text("Are you sure you want to delete this recipe? This action cannot be undone.")
            }
            .alert("Unsaved Changes", isPresented: showUnsavedChangesAlert) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
    }
}

// MARK: - Sheet Content View
struct SheetContent: View {
    let sheet: EditRecipeSheet
    @ObservedObject var viewModel: EditRecipeViewModel
    @Binding var activeSheet: EditRecipeSheet?
    
    var body: some View {
        switch sheet {
        case .ingredients:
            NavigationStack {
                IngredientSelectionView(selectedIngredients: $viewModel.selectedIngredients)
            }
        case .imagePicker:
            ImagePicker(image: $viewModel.image)
        case .step(let stepSheet):
            NavigationStack {
                switch stepSheet {
                case .add:
                    StepFormView(
                        step: nil,
                        recipeIngredients: viewModel.selectedIngredients
                    ) { newStep in
                        viewModel.steps.append(newStep)
                        viewModel.updateStepOrder()
                        viewModel.hasChanges = true
                        activeSheet = nil
                    }
                case .edit(let step):
                    StepFormView(
                        step: step,
                        recipeIngredients: viewModel.selectedIngredients
                    ) { newStep in
                        if let index = viewModel.steps.firstIndex(where: { $0.id == step.id }) {
                            viewModel.steps[index] = newStep
                        }
                        viewModel.updateStepOrder()
                        viewModel.hasChanges = true
                        activeSheet = nil
                    }
                }
            }
        }
    }
}

// MARK: - Section Components

// Add this after the EditStepSheet enum
struct ImageNameSection: View {
    @Binding var image: UIImage?
    @Binding var name: String
    var focusedFieldBinding: FocusState<EditRecipeView.Field?>.Binding
    let onImageTap: () -> Void
    
    var body: some View {
        Section {
            VStack(spacing: 16) {
                // Recipe image with edit button
                ZStack(alignment: .bottomTrailing) {
                    if let image = image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .contentShape(Rectangle())
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemGray5))
                            .frame(height: 250)
                            .frame(maxWidth: .infinity)
                            .overlay {
                                VStack(spacing: 8) {
                                    Image(systemName: "photo.fill")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.secondary)
                                    Text("Add Photo")
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .contentShape(Rectangle())
                    }

                    Button {
                        onImageTap()
                    } label: {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 44, height: 44)
                            .overlay {
                                Image(systemName: image == nil ? "camera.fill" : "pencil")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                            .shadow(radius: 3)
                            .padding(8)
                    }
                }
                .onTapGesture {
                    onImageTap()
                }
                
                // Recipe name field
                TextField("Recipe Name", text: $name)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .padding(.vertical, 8)
                    .focused(focusedFieldBinding, equals: .name)
            }
            .listRowInsets(EdgeInsets())
            .padding(.horizontal)
            .padding(.bottom, 8)
            .listRowBackground(Color.clear)
        }
    }
}

struct RecipeStatsSection: View {
    @Binding var timeInMinutes: Int16
    @Binding var servings: Int16
    @Binding var difficulty: Difficulty
    let formatTime: (Int16) -> String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header
            Label("Recipe Details", systemImage: "stopwatch")
                .font(.headline)
                .foregroundStyle(.primary)
                .padding(.horizontal)
            
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
            .padding(.horizontal)
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
                        .foregroundStyle(.secondary)
                        .frame(width: 44, alignment: .leading)
                }
                .frame(width: 164, alignment: .trailing)
            }
        }
        .padding(.leading, 16)
        .frame(height: 54)
    }
}

struct IngredientsListSection: View {
    @Binding var ingredients: [SelectedIngredient]
    let onAddTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: "list.bullet")
                Text("Ingredients").font(.headline)
            }
            .padding(.horizontal)
            
            if ingredients.isEmpty {
                Button {
                    onAddTap()
                } label: {
                    HStack {
                        Text("Add ingredients")
                        Spacer()
                        Image(systemName: "plus.circle.fill")
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                .padding(.horizontal)
                        } else {
                VStack(spacing: 8) {
                    ForEach($ingredients) { $ingredient in
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                            Text(ingredient.ingredient.name ?? "")
                                        .font(.body)
                            }
                            
                            Spacer()
                                    
                            HStack(spacing: 4) {
                                    TextField("Qty", value: $ingredient.quantity, format: .number)
                                    .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                    .frame(width: 50)
                                    
                                Picker("Unit", selection: $ingredient.unit) {
                                    ForEach(UnitOfMeasure.allCases, id: \.self) { unit in
                                        Text(unit.displayName).tag(unit)
                                    }
                                }
                                .pickerStyle(.menu)
                                .labelsHidden()
                                .frame(width: 65)
                            }
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                    }
                    
                            Button {
                        onAddTap()
                            } label: {
                        Label("Add More Ingredients", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct RecipeStepsSection: View {
    let steps: [RecipeStep]
    let onAddTap: () -> Void
    let onStepTap: (RecipeStep) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            // Header
            HStack {
                Image(systemName: "list.number")
                Text("Steps").font(.headline)
            }
            .padding(.horizontal)
            
            // Content based on whether steps exist
            Group {
                if steps.isEmpty {
                    emptyStepsView
                } else {
                    stepsListView
                }
            }
        }
    }
    
    // Empty state view
    private var emptyStepsView: some View {
        Button {
            onAddTap()
        } label: {
            HStack {
                Text("Add preparation steps")
                Spacer()
                Image(systemName: "plus.circle.fill")
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding(.horizontal)
    }
    
    // Steps list view - extracted to reduce complexity
    private var stepsListView: some View {
        VStack(spacing: 8) {
            // Steps list
            ForEach(steps.indices, id: \.self) { index in
                stepView(for: index)
            }
            
            // Add more button
            addMoreButton
        }
        .padding(.horizontal)
    }
    
    // Single step view
    private func stepView(for index: Int) -> some View {
        Button {
            onStepTap(steps[index])
        } label: {
            HStack(alignment: .top, spacing: 16) {
                // Step number
                stepNumberView(index: index)
                
                // Step content
                stepContentView(index: index)
                
                Spacer()
                
                // Chevron
                Image(systemName: "chevron.right")
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    // Step number circle
    private func stepNumberView(index: Int) -> some View {
        Text("\(index + 1)")
            .font(.system(.headline, design: .rounded))
            .foregroundColor(.white)
            .frame(width: 28, height: 28)
            .background(Circle().fill(Color.accentColor))
    }
    
    // Step content (instructions and ingredients count)
    private func stepContentView(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(steps[index].instructions)
                .foregroundColor(.primary)
                .multilineTextAlignment(.leading)
                .lineLimit(4)
            
            if steps[index].selectedIngredients.count > 0 {
                Text(ingredientsText(for: steps[index]))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    // Helper to generate ingredients text
    private func ingredientsText(for step: RecipeStep) -> String {
        let count = step.selectedIngredients.count
        return "Uses \(count) ingredient\(count > 1 ? "s" : "")"
    }
    
    // Add more button
    private var addMoreButton: some View {
        Button {
            onAddTap()
        } label: {
            Label("Add More Steps", systemImage: "plus")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
        }
    }
}

// Simplified preview for faster compilation
struct EditRecipeView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let recipe = Recipe(context: context)
        recipe.name = "Sample Recipe"
        
        return EditRecipeView(
            recipe: recipe,
            rootDismiss: .constant(false),
            refreshID: .constant(UUID())
        )
        .environment(\.managedObjectContext, context)
    }
}

// Add this enum definition after the EditRecipeView struct

enum EditRecipeSheet: Identifiable {
    case ingredients
    case imagePicker
    case step(EditStepSheet)
    
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

enum EditStepSheet: Identifiable {
    case add
    case edit(RecipeStep)
    
    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let step):
            return "edit-\(step.id)"
        }
    }
} 
