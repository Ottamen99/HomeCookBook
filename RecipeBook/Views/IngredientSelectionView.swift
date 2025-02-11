import SwiftUI

struct IngredientSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ingredient.name, ascending: true)],
        animation: .default)
    private var ingredients: FetchedResults<Ingredient>
    @Binding var selectedIngredients: [SelectedIngredient]
    
    @State private var searchText = ""
    
    var filteredIngredients: [Ingredient] {
        if searchText.isEmpty {
            return Array(ingredients)
        }
        return ingredients.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredIngredients) { ingredient in
                    let isSelected = selectedIngredients.contains { $0.ingredient == ingredient }
                    Button {
                        if isSelected {
                            selectedIngredients.removeAll { $0.ingredient == ingredient }
                        } else {
                            selectedIngredients.append(SelectedIngredient(
                                ingredient: ingredient,
                                quantity: 0,
                                unit: .grams
                            ))
                        }
                    } label: {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(ingredient.name ?? "")
                                    .font(.headline)
                                if let description = ingredient.desc {
                                    Text(description)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .navigationTitle("Select Ingredients")
            .searchable(text: $searchText, prompt: "Search ingredients")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
} 