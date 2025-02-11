import SwiftUI
import CoreData

struct AddPantryIngredientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: PantryViewModel
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ingredient.name, ascending: true)],
        animation: .default
    ) private var ingredients: FetchedResults<Ingredient>
    
    @State private var selectedIngredient: Ingredient?
    @State private var quantity: Double = 1.0
    @State private var unit: String = "pieces"
    @State private var searchText = ""
    
    var filteredIngredients: [Ingredient] {
        if searchText.isEmpty {
            return Array(ingredients)
        }
        return ingredients.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Select Ingredient") {
                    ForEach(filteredIngredients) { ingredient in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(ingredient.name ?? "")
                                    .font(.headline)
                                if let description = ingredient.desc, !description.isEmpty {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            if selectedIngredient == ingredient {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedIngredient = ingredient
                        }
                    }
                }
                
                if let selectedIngredient = selectedIngredient {
                    Section("Quantity") {
                        HStack {
                            TextField("Quantity", value: $quantity, format: .number)
                                .keyboardType(.decimalPad)
                            
                            Picker("Unit", selection: $unit) {
                                ForEach(["g", "kg", "ml", "l", "pieces", "cups", "tbsp", "tsp"], id: \.self) { unit in
                                    Text(unit).tag(unit)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Add to Pantry")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search ingredients")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Add") {
                        addIngredient()
                    }
                    .disabled(selectedIngredient == nil)
                }
            }
        }
    }
    
    private func addIngredient() {
        guard let selectedIngredient = selectedIngredient else { return }
        
        withAnimation {
            let pantryIngredient = PantryIngredient(context: viewContext)
            pantryIngredient.ingredient = selectedIngredient
            pantryIngredient.quantity = quantity
            pantryIngredient.unit = unit
            
            try? viewContext.save()
            viewModel.updateRecipeAvailability()
            dismiss()
        }
    }
} 