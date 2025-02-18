import SwiftUI
import CoreData

struct RecipeSelectionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let recipeBook: NSManagedObject
    
    @FetchRequest(
        entity: NSEntityDescription.entity(forEntityName: "Recipe", in: PersistenceController.shared.container.viewContext)!,
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
    private var recipes: FetchedResults<NSManagedObject>
    
    @State private var searchText = ""
    
    private var filteredRecipes: [NSManagedObject] {
        if searchText.isEmpty {
            return Array(recipes)
        }
        return recipes.filter { ($0.value(forKey: "name") as? String ?? "").localizedCaseInsensitiveContains(searchText) }
    }
    
    private var bookRecipes: Set<NSManagedObject> {
        recipeBook.value(forKey: "recipes") as? Set<NSManagedObject> ?? []
    }
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(filteredRecipes, id: \.self) { recipe in
                    let isSelected = bookRecipes.contains(recipe)
                    Button {
                        toggleRecipe(recipe)
                    } label: {
                        HStack {
                            Text(recipe.value(forKey: "name") as? String ?? "")
                            Spacer()
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search recipes")
            .navigationTitle("Add Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func toggleRecipe(_ recipe: NSManagedObject) {
        let recipeBooks = recipe.mutableSetValue(forKey: "recipeBooks")
        
        if bookRecipes.contains(recipe) {
            recipeBooks.remove(recipeBook)
        } else {
            recipeBooks.add(recipeBook)
        }
        
        recipeBook.setValue(Date(), forKey: "updatedAt")
        try? viewContext.save()
    }
} 