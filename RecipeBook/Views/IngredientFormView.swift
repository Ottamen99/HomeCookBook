import SwiftUI

enum IngredientFormMode {
    case add
    case edit(Ingredient)
}

struct IngredientFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    
    let mode: IngredientFormMode
    
    @State private var name = ""
    @State private var description = ""
    @State private var showingDeleteErrorAlert = false
    
    var title: String {
        switch mode {
        case .add: return "New Ingredient"
        case .edit: return "Edit Ingredient"
        }
    }
    
    var canDelete: Bool {
        if case .edit(let ingredient) = mode {
            return (ingredient.recipeIngredients?.count ?? 0) == 0
        }
        return false
    }
    
    init(mode: IngredientFormMode) {
        self.mode = mode
        if case .edit(let ingredient) = mode {
            _name = State(initialValue: ingredient.name ?? "")
            _description = State(initialValue: ingredient.desc ?? "")
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section {
                    TextField("Name", text: $name)
                    TextField("Description", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                if case .edit = mode {
                    Section {
                        Button("Delete Ingredient", role: .destructive) {
                            if canDelete {
                                if case .edit(let ingredient) = mode {
                                    viewContext.delete(ingredient)
                                    try? viewContext.save()
                                    dismiss()
                                }
                            } else {
                                showingDeleteErrorAlert = true
                            }
                        }
                    }
                }
            }
            .navigationTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .alert("Cannot Delete Ingredient", isPresented: $showingDeleteErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                if case .edit(let ingredient) = mode {
                    Text("This ingredient cannot be deleted because it is used in \((ingredient.recipeIngredients?.count ?? 0)) recipe\(ingredient.recipeIngredients?.count == 1 ? "" : "s"). Please remove it from all recipes first.")
                }
            }
        }
    }
    
    private func save() {
        viewContext.perform {
            do {
                switch mode {
                case .add:
                    let ingredient = Ingredient(context: viewContext)
                    ingredient.name = name
                    ingredient.desc = description
                case .edit(let ingredient):
                    ingredient.name = name
                    ingredient.desc = description
                    
                    // Refresh related objects
                    if let recipeIngredients = ingredient.recipeIngredients as? Set<RecipeIngredient> {
                        for recipeIngredient in recipeIngredients {
                            viewContext.refresh(recipeIngredient, mergeChanges: true)
                            if let recipe = recipeIngredient.recipe {
                                viewContext.refresh(recipe, mergeChanges: true)
                            }
                        }
                    }
                }
                
                try viewContext.save()
                
                // Refresh the entire view context
                viewContext.refreshAllObjects()
                
                DispatchQueue.main.async {
                    dismiss()
                }
            } catch {
                print("Error saving ingredient: \(error)")
            }
        }
    }
} 