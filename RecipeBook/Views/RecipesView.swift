import SwiftUI
import CoreData

struct RecipesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recipe.name, ascending: true)],
        animation: .default)
    private var recipes: FetchedResults<Recipe>
    
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var selectedRecipe: Recipe?
    @State private var showingDeleteAlert = false
    @State private var scrollViewProxy: ScrollViewProxy? = nil
    @State private var isSearching = false
    @AccessibilityFocusState private var isHeaderFocused: Bool
    
    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return Array(recipes)
        }
        return recipes.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchText) }
    }
    
    init() {
        // Configure navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.orange]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                ZStack(alignment: .bottom) {
                    // Main content
                    VStack(spacing: 0) {
                        if filteredRecipes.isEmpty && !searchText.isEmpty {
                            emptySearchResultsView
                        } else if filteredRecipes.isEmpty {
                            emptyRecipesView
                        } else {
                            recipesList(proxy: proxy)
                        }
                    }
                    
                    // Floating action button for adding recipes
                    floatingAddButton
                }
                .onAppear {
                    scrollViewProxy = proxy
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isHeaderFocused = true
                    }
                }
                .refreshable {
                    await refresh()
                }
                .searchable(text: $searchText, prompt: "Search recipes")
                .navigationTitle("Recipes")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        if filteredRecipes.count > 5 {
                            Button {
                                withAnimation {
                                    if let firstRecipe = filteredRecipes.first {
                                        let id = getRecipeID(recipe: firstRecipe)
                                        scrollViewProxy?.scrollTo(id, anchor: .top)
                                    }
                                }
                            } label: {
                                Label("Scroll to Top", systemImage: "arrow.up")
                                    .labelStyle(.iconOnly)
                                    .imageScale(.medium)
                            }
                            .accessibilityLabel("Scroll to top")
                        }
                    }
                }
                .sheet(isPresented: $showingAddSheet) {
                    AddRecipeView()
                }
                .alert("Delete Recipe", isPresented: $showingDeleteAlert) {
                    Button("Cancel", role: .cancel) {}
                    Button("Delete", role: .destructive) {
                        if let recipe = selectedRecipe {
                            deleteRecipe(recipe)
                        }
                    }
                } message: {
                    Text("Are you sure you want to delete this recipe? This action cannot be undone.")
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    private func recipesList(proxy: ScrollViewProxy) -> some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(filteredRecipes) { recipe in
                    RecipeNavigationLink(recipe: recipe, onDelete: {
                        selectedRecipe = recipe
                        showingDeleteAlert = true
                    })
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
        }
        .scrollIndicators(.visible)
        .safeAreaInset(edge: .bottom) {
            Color.clear.frame(height: 80)
        }
    }
    
    private var emptyRecipesView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "book.closed")
                .font(.system(size: 70))
                .foregroundColor(.orange)
                .accessibilityHidden(true)
            
            Text("No Recipes Yet")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Add your first recipe to get started")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                showingAddSheet = true
            } label: {
                Label("Add Recipe", systemImage: "plus")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 16)
            .accessibilityHint("Adds a new recipe to your collection")
            
            Spacer()
        }
        .padding()
        .accessibilityFocused($isHeaderFocused)
    }
    
    private var emptySearchResultsView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .accessibilityHidden(true)
            
            Text("No Matching Recipes")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Try a different search term or add a new recipe")
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Button {
                searchText = ""
            } label: {
                Text("Clear Search")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.secondary.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
    }
    
    private var floatingAddButton: some View {
        Button {
            showingAddSheet = true
        } label: {
            Image(systemName: "plus")
                .font(.title2.weight(.semibold))
                .foregroundColor(.white)
                .frame(width: 56, height: 56)
                .background(Color.orange)
                .clipShape(Circle())
                .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
        }
        .padding(.bottom, 16)
        .accessibilityLabel("Add Recipe")
    }
    
    // MARK: - Helper Functions
    
    private func getRecipeID(recipe: Recipe) -> String {
        let objectID = recipe.objectID.uriRepresentation().absoluteString
        return objectID.isEmpty ? (recipe.name ?? UUID().uuidString) : objectID
    }
    
    private func deleteRecipe(_ recipe: Recipe) {
        withAnimation {
            viewContext.delete(recipe)
            try? viewContext.save()
        }
    }
    
    private func refresh() async {
        do {
            try await Task.sleep(nanoseconds: 1 * 1_000_000_000)
            // Any additional refresh logic would go here
        } catch {
            print("Refresh task cancelled")
        }
    }
}

// MARK: - Supporting Views

struct RecipeNavigationLink: View {
    let recipe: Recipe
    let onDelete: () -> Void
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationLink {
            RecipeDetailView(recipe: recipe)
                .toolbar(.hidden, for: .tabBar)
        } label: {
            recipeCard
        }
        .buttonStyle(.plain)
        .id(getRecipeID())
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
            
            Button {
                // Share functionality could be added here
            } label: {
                Label("Share Recipe", systemImage: "square.and.arrow.up")
            }
        }
    }
    
    private var recipeCard: some View {
        HStack(alignment: .center, spacing: 16) {
            // Recipe image
            recipeImage
                .frame(width: 80, height: 80)
                .background(Color.orange.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            
            // Recipe details
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name ?? "")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .lineLimit(1)
                
                if let description = recipe.desc, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 16) {
                    Label("\(recipe.timeInMinutes) min", systemImage: "clock")
                    Label("\(recipe.servings) servings", systemImage: "person.2")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.trailing, 4)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(colorScheme == .dark ? Color(UIColor.secondarySystemBackground) : .white)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
    
    private var recipeImage: some View {
        Group {
            if let imageData = recipe.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "fork.knife")
                    .font(.system(size: 30))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.orange.opacity(0.1))
            }
        }
    }
    
    private func getRecipeID() -> String {
        let objectID = recipe.objectID.uriRepresentation().absoluteString
        return objectID.isEmpty ? (recipe.name ?? UUID().uuidString) : objectID
    }
}

#Preview {
    NavigationStack {
        RecipesView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 
