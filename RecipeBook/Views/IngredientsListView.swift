import SwiftUI
import CoreData

struct IngredientsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Ingredient.name, order: .forward)],
        animation: .default
    ) private var ingredients: FetchedResults<Ingredient>
    
    @State private var showingAddSheet = false
    @State private var editingIngredient: Ingredient?
    @State private var searchText = ""
    
    private var filteredIngredients: [Ingredient] {
        if searchText.isEmpty {
            return Array(ingredients)
        }
        return ingredients.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(filteredIngredients) { ingredient in
                    Button {
                        editingIngredient = ingredient
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ingredient.name ?? "")
                                .font(.headline)
                                .id(ingredient.objectID)  // Force refresh when ingredient changes
                            if let description = ingredient.desc, !description.isEmpty {
                                Text(description)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .foregroundColor(.primary)
                }
            }
            .searchable(text: $searchText, prompt: "Search ingredients")
            .navigationTitle("Ingredients")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                IngredientFormView(mode: .add)
            }
            .sheet(item: $editingIngredient) { ingredient in
                NavigationView {
                    IngredientFormView(mode: .edit(ingredient))
                }
            }
        }
    }
} 