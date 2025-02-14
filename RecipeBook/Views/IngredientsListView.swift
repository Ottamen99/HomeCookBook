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
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 16),
                    GridItem(.flexible(), spacing: 16)
                ], spacing: 16) {
                    ForEach(filteredIngredients) { ingredient in
                        IngredientCard(
                            ingredient: ingredient,
                            onTap: {
                                editingIngredient = ingredient
                            }
                        )
                        .id(ingredient.objectID)  // Force refresh when ingredient changes
                    }
                }
                .padding()
            }
            .navigationTitle("Ingredients")
            .searchable(text: $searchText, prompt: "Search ingredients")
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
                NavigationStack {
                    IngredientFormView(mode: .edit(ingredient))
                }
            }
        }
    }
}

private struct IngredientCard: View {
    let ingredient: Ingredient
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Icon circle
                Circle()
                    .fill(Color.blue.opacity(0.1))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "leaf.fill")
                            .foregroundColor(.blue)
                            .font(.system(size: 24))
                    }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(ingredient.name ?? "")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let description = ingredient.desc, !description.isEmpty {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    Image(systemName: "pencil")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                }
            }
            .padding()
            .frame(height: 160)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
} 