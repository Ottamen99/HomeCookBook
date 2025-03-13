import SwiftUI
import CoreData

struct IngredientsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    @FetchRequest(
        sortDescriptors: [SortDescriptor(\Ingredient.name, order: .forward)],
        animation: .default
    ) private var ingredients: FetchedResults<Ingredient>
    
    @State private var showingAddSheet = false
    @State private var editingIngredient: Ingredient?
    @State private var searchText = ""
    @State private var showingDeleteAlert = false
    @State private var selectedIngredient: Ingredient?
    @AccessibilityFocusState private var isHeaderFocused: Bool
    
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
            ZStack {
                if ingredients.isEmpty {
                    emptyIngredientsView
                } else if filteredIngredients.isEmpty {
                    emptySearchResultsView
                } else {
                    ingredientsList
                }
            }
            .navigationTitle("Ingredients")
            .navigationBarTitleDisplayMode(.large)
            .searchable(text: $searchText, prompt: "Search ingredients")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus")
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
                    .accessibilityLabel("Add new ingredient")
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    IngredientFormView(mode: .add)
                }
            }
            .alert("Delete Ingredient", isPresented: $showingDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    if let ingredient = selectedIngredient {
                        deleteIngredient(ingredient)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this ingredient? This action cannot be undone.")
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isHeaderFocused = true
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    private var ingredientsList: some View {
        List {
            ForEach(filteredIngredients) { ingredient in
                NavigationLink {
                    IngredientDetailView(ingredient: ingredient)
                        .toolbar(.hidden, for: .tabBar)
                } label: {
                    IngredientRowView(ingredient: ingredient)
                        .padding(.vertical, 8) // Increased padding for better hit target
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        selectedIngredient = ingredient
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                    .accessibilityLabel("Delete \(ingredient.name ?? "ingredient")")
                }
                .swipeActions(edge: .leading, allowsFullSwipe: false) {
                    Button {
                        editingIngredient = ingredient
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    .tint(.blue)
                    .accessibilityLabel("Edit \(ingredient.name ?? "ingredient")")
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollIndicators(.visible)
        .sheet(item: $editingIngredient) { ingredient in
            NavigationStack {
                IngredientFormView(mode: .edit(ingredient))
            }
        }
    }
    
    private var emptyIngredientsView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "leaf.circle")
                .font(.system(size: 70))
                .foregroundColor(.orange)
                .accessibilityHidden(true)
            
            Text("No Ingredients Yet")
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityFocused($isHeaderFocused)
            
            Text("Add your first ingredient to get started")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                showingAddSheet = true
            } label: {
                Label("Add Ingredient", systemImage: "plus")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 220)
                    .frame(height: 54) // Taller button for better hit target
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .padding(.top, 16)
            .accessibilityHint("Adds a new ingredient to your collection")
            
            Spacer()
        }
        .padding()
    }
    
    private var emptySearchResultsView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .accessibilityHidden(true)
            
            Text("No Matching Ingredients")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Try a different search term or add a new ingredient")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                searchText = ""
            } label: {
                Text("Clear Search")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 220)
                    .frame(height: 54) // Taller button for better hit target
                    .background(Color.secondary.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(12)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Helper Functions
    
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
