import SwiftUI
import CoreData

struct RecipesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Recipe.name, ascending: true)],
        animation: .default)
    private var recipes: FetchedResults<Recipe>
    
    @State private var showingAddSheet = false
    @State private var searchText = ""
    @State private var selectedRecipe: Recipe?
    @State private var showingDeleteAlert = false
    
    var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return Array(recipes)
        }
        return recipes.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchText) }
    }
    
    init() {
        // Configure navigation bar button appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.orange]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredRecipes) { recipe in
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                            .toolbar(.hidden, for: .tabBar)
                    } label: {
                        RecipeRowView(recipe: recipe)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            selectedRecipe = recipe
                            showingDeleteAlert = true
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.inset)
            .navigationTitle("Recipes")
            .searchable(text: $searchText, prompt: "Search recipes")
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
    
    private func deleteRecipe(_ recipe: Recipe) {
        withAnimation {
            viewContext.delete(recipe)
            try? viewContext.save()
        }
    }
}

struct RecipeRowView: View {
    @ObservedObject var recipe: Recipe
    
    var body: some View {
        HStack(spacing: 12) {
            // Recipe image with consistent format
            Group {
                if let imageData = recipe.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Image(systemName: "fork.knife.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.orange)
                }
            }
            .frame(width: 60, height: 60)
            .background(Color.orange.opacity(0.1))
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name ?? "")
                    .font(.headline)
                HStack(spacing: 12) {
                    Label("\(recipe.timeInMinutes) min", systemImage: "clock")
                    Label("\(recipe.servings) servings", systemImage: "person.2")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
} 
