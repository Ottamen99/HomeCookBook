import SwiftUI

struct IngredientDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let ingredient: Ingredient
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingDeleteErrorAlert = false
    
    var usedInRecipes: [Recipe] {
        let recipeIngredients = ingredient.recipeIngredients as? Set<RecipeIngredient> ?? []
        return recipeIngredients.compactMap { $0.recipe }
    }
    
    var canDelete: Bool {
        usedInRecipes.isEmpty
    }
    
    var body: some View {
        List {
            Section {
                if let description = ingredient.desc, !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Text(description)
                    }
                }
            }
            
            if !usedInRecipes.isEmpty {
                Section("Used in Recipes") {
                    ForEach(usedInRecipes) { recipe in
                        NavigationLink {
                            RecipeDetailView(recipe: recipe)
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(recipe.name ?? "")
                                    .font(.headline)
                                let quantity = recipe.recipeIngredients?
                                    .first { ($0 as? RecipeIngredient)?.ingredient == ingredient }
                                    .flatMap { $0 as? RecipeIngredient }
                                if let quantity {
                                    Text("\(String(format: "%.1f", quantity.quantity)) \(quantity.unit ?? "")")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            
            Section {
                Button("Delete Ingredient", role: .destructive) {
                    if canDelete {
                        showingDeleteAlert = true
                    } else {
                        showingDeleteErrorAlert = true
                    }
                }
            }
        }
        .navigationTitle(ingredient.name ?? "")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingEditSheet = true
                } label: {
                    Text("Edit")
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            IngredientFormView(mode: .edit(ingredient))
        }
        .alert("Delete Ingredient", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteIngredient()
            }
        } message: {
            Text("Are you sure you want to delete this ingredient? This action cannot be undone.")
        }
        .alert("Cannot Delete Ingredient", isPresented: $showingDeleteErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This ingredient cannot be deleted because it is used in \(usedInRecipes.count) recipe\(usedInRecipes.count == 1 ? "" : "s"). Please remove it from all recipes first.")
        }
    }
    
    private func deleteIngredient() {
        guard canDelete else { return }
        viewContext.delete(ingredient)
        try? viewContext.save()
        dismiss()
    }
} 