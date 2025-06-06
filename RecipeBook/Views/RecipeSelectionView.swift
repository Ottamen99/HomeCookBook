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
    @State private var showToast = false
    @State private var toastMessage = ""
    
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
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredRecipes, id: \.self) { recipe in
                        let isSelected = bookRecipes.contains(recipe)
                        RecipeSelectionCard(
                            recipe: recipe,
                            isSelected: isSelected,
                            action: {
                                withAnimation {
                                    toggleRecipe(recipe)
                                    showToastMessage(for: recipe, isAdding: !isSelected)
                                }
                            }
                        )
                    }
                }
                .padding()
                
                if showToast {
                    Text(toastMessage)
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.75))
                        .cornerRadius(8)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .background(Color(.systemGroupedBackground))
            .searchable(text: $searchText, prompt: "Search recipes")
            .navigationTitle("Add Recipes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray)
                            .cornerRadius(20)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Done")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.orange)
                            .cornerRadius(20)
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
    
    private func showToastMessage(for recipe: NSManagedObject, isAdding: Bool) {
        let recipeName = recipe.value(forKey: "name") as? String ?? ""
        toastMessage = isAdding ? "Added \(recipeName)" : "Removed \(recipeName)"
        withAnimation {
            showToast = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            withAnimation {
                showToast = false
            }
        }
    }
}

struct RecipeSelectionCard: View {
    let recipe: NSManagedObject
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "photo")
                            .foregroundColor(.gray)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(recipe.value(forKey: "name") as? String ?? "")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    if let description = recipe.value(forKey: "desc") as? String {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .orange : .gray.opacity(0.5))
                    .imageScale(.large)
                    .padding(.trailing, 4)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.orange : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
} 
