import SwiftUI

struct AddRecipeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
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
    
    var body: some View {
        NavigationView {
            Form {
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
                                        Text(unit.rawValue).tag(unit)
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
                        showingIngredientSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Ingredient")
                        }
                    }
                }
            }
            .navigationTitle("New Recipe")
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
            .sheet(isPresented: $showingIngredientSheet) {
                IngredientSelectionView(selectedIngredients: $selectedIngredients)
            }
        }
    }
    
    private func saveRecipe() {
        let recipe = Recipe(context: viewContext)
        recipe.name = name
        recipe.desc = description
        recipe.timeInMinutes = timeInMinutes
        recipe.servings = servings
        
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