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
    
    init() {
        // Configure navigation bar button appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.orange]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    private var filteredIngredients: [Ingredient] {
        if searchText.isEmpty {
            return Array(ingredients)
        }
        return ingredients.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredIngredients) { ingredient in
                    NavigationLink {
                        IngredientDetailView(ingredient: ingredient)
                            .toolbar(.hidden, for: .tabBar)
                    } label: {
                        IngredientRowView(ingredient: ingredient)
                    }
                    .listRowInsets(EdgeInsets())
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            deleteIngredient(ingredient)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
            .navigationTitle("Ingredients")
            .searchable(text: $searchText, prompt: "Search ingredients")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundColor(.orange)
                            .font(.system(size: 17, weight: .semibold))
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
    
    private func deleteIngredient(_ ingredient: Ingredient) {
        withAnimation {
            viewContext.delete(ingredient)
            try? viewContext.save()
        }
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    // Create sample ingredients
    let flour = Ingredient(context: context)
    flour.name = "Flour"
    flour.desc = "All-purpose flour"
    
    let sugar = Ingredient(context: context)
    sugar.name = "Sugar"
    sugar.desc = "Granulated sugar"
    
    let butter = Ingredient(context: context)
    butter.name = "Butter"
    butter.desc = "Unsalted butter"
    
    // Create a sample recipe to show "Used in X recipes"
    let recipe = Recipe(context: context)
    recipe.name = "Cookies"
    
    let recipeIngredient = RecipeIngredient(context: context)
    recipeIngredient.ingredient = flour
    recipeIngredient.recipe = recipe
    recipeIngredient.quantity = 250
    recipeIngredient.unit = "grams"
    
    try? context.save()
    
    return IngredientsListView()
        .environment(\.managedObjectContext, context)
} 