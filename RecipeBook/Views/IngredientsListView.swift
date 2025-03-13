import SwiftUI
import CoreData

struct IngredientsListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
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
    @AccessibilityFocusState private var isEmptyStateFocused: Bool
    
    // Adaptive spacing based on dynamic type size
    private var verticalSpacing: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium:
            return 24
        case .large, .xLarge:
            return 28
        default:
            return 32
        }
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
                        HStack(spacing: 6) {
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
                    .buttonStyle(PressEffectButtonStyle())
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
                    if ingredients.isEmpty {
                        isEmptyStateFocused = true
                    } else {
                        isHeaderFocused = true
                    }
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
                        .contentShape(Rectangle())
                }
                .accessibilityHint("View details for \(ingredient.name ?? "ingredient")")
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
        .refreshable {
            // Refresh data if needed
            viewContext.refreshAllObjects()
        }
        .sheet(item: $editingIngredient) { ingredient in
            NavigationStack {
                IngredientFormView(mode: .edit(ingredient))
            }
        }
    }
    
    private var emptyIngredientsView: some View {
        VStack(spacing: verticalSpacing) {
            Spacer()
                .frame(height: 40)
            
            Image(systemName: "leaf.circle")
                .font(.system(size: 70))
                .foregroundColor(.orange)
                .accessibilityHidden(true)
            
            Text("No Ingredients Yet")
                .font(.title2)
                .fontWeight(.bold)
                .accessibilityFocused($isEmptyStateFocused)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("Add your first ingredient to get started")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, horizontalSizeClass == .compact ? 32 : 64)
                .fixedSize(horizontal: false, vertical: true)
            
            Button {
                showingAddSheet = true
            } label: {
                Label("Add Ingredient", systemImage: "plus")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 280)
                    .frame(height: 54) // Taller button for better hit target
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .contentShape(Rectangle())
            }
            .buttonStyle(PressEffectButtonStyle())
            .padding(.top, 16)
            .accessibilityHint("Adds a new ingredient to your collection")
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptySearchResultsView: some View {
        VStack(spacing: verticalSpacing) {
            Spacer()
                .frame(height: 40)
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .accessibilityHidden(true)
            
            Text("No Matching Ingredients")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            
            Text("Try a different search term or add a new ingredient")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, horizontalSizeClass == .compact ? 32 : 64)
                .fixedSize(horizontal: false, vertical: true)
            
            HStack(spacing: 16) {
                Button {
                    searchText = ""
                } label: {
                    Text("Clear Search")
                        .font(.headline)
                        .padding()
                        .frame(height: 54) // Taller button for better hit target
                        .frame(maxWidth: .infinity)
                        .background(Color.secondary.opacity(0.1))
                        .foregroundColor(.primary)
                        .cornerRadius(12)
                        .contentShape(Rectangle())
                }
                
                Button {
                    showingAddSheet = true
                } label: {
                    Text("Add New")
                        .font(.headline)
                        .padding()
                        .frame(height: 54) // Taller button for better hit target
                        .frame(maxWidth: .infinity)
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                        .contentShape(Rectangle())
                }
            }
            .padding(.top, 8)
            .padding(.horizontal, horizontalSizeClass == .compact ? 16 : 64)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Helper Functions
    
    private func deleteIngredient(_ ingredient: Ingredient) {
        withAnimation {
            viewContext.delete(ingredient)
            try? viewContext.save()
        }
    }
}

// MARK: - Supporting Views and Styles

struct IngredientRowView: View {
    let ingredient: Ingredient
    @Environment(\.colorScheme) private var colorScheme
    
    private var recipeCount: Int {
        ingredient.recipeIngredients?.count ?? 0
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Ingredient icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: "leaf")
                    .font(.system(size: 18))
                    .foregroundColor(.orange)
            }
            .accessibilityHidden(true)
            
            // Ingredient details
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name ?? "Unknown Ingredient")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let description = ingredient.desc, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            // Recipe count badge
            if recipeCount > 0 {
                Text("\(recipeCount)")
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(colorScheme == .dark ? Color.orange.opacity(0.3) : Color.orange.opacity(0.2))
                    )
                    .foregroundColor(colorScheme == .dark ? .orange : .orange.opacity(0.8))
                    .accessibilityLabel("Used in \(recipeCount) \(recipeCount == 1 ? "recipe" : "recipes")")
            }
        }
    }
}

// Use a different name to avoid conflict with ScaleButtonStyle in other files
struct PressEffectButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview
struct IngredientsListView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Standard preview
            IngredientsListView()
                .environment(\.managedObjectContext, createPreviewContext())
                .previewDisplayName("Light Mode")
            
            // Dark mode preview
            IngredientsListView()
                .environment(\.managedObjectContext, createPreviewContext())
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            // Accessibility preview with larger text
            IngredientsListView()
                .environment(\.managedObjectContext, createPreviewContext())
                .environment(\.dynamicTypeSize, .xxxLarge)
                .previewDisplayName("Large Text")
            
            // Empty state preview
            IngredientsListView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .previewDisplayName("Empty State")
        }
    }
    
    static func createPreviewContext() -> NSManagedObjectContext {
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
        
        return context
    }
} 
