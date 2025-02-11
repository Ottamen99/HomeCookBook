import SwiftUI

struct EditPantryIngredientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let ingredient: PantryIngredient
    @ObservedObject var viewModel: PantryViewModel
    
    @State private var quantity: Double
    @State private var unit: String
    
    init(ingredient: PantryIngredient, viewModel: PantryViewModel) {
        self.ingredient = ingredient
        self.viewModel = viewModel
        _quantity = State(initialValue: ingredient.quantity)
        _unit = State(initialValue: ingredient.unit ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text(ingredient.ingredient?.name ?? "")
                        .font(.headline)
                }
                
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
            .navigationTitle("Edit Ingredient")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        updateIngredient()
                    }
                }
            }
        }
    }
    
    private func updateIngredient() {
        ingredient.quantity = quantity
        ingredient.unit = unit
        
        try? viewContext.save()
        viewModel.updateRecipeAvailability()
        dismiss()
    }
} 