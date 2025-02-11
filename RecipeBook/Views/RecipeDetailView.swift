import SwiftUI
import CoreData

struct RecipeDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let recipe: Recipe
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var servings: Int16
    @State private var refreshID = UUID()
    
    init(recipe: Recipe) {
        self.recipe = recipe
        _servings = State(initialValue: recipe.servings)
    }
    
    private var recipeImage: some View {
        Group {
            if let imageData = recipe.imageData,
               let uiImage = UIImage(data: imageData) {
                Section {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .listRowInsets(EdgeInsets())
            }
        }
    }
    
    private var timeView: some View {
        HStack {
            Image(systemName: "clock")
                .foregroundColor(.blue)
            Text("\(recipe.timeInMinutes) minutes")
        }
    }
    
    private var servingsView: some View {
        HStack {
            Image(systemName: "person.2")
                .foregroundColor(.blue)
            Stepper("Servings: \(servings)", value: $servings, in: 1...20)
        }
    }
    
    private var recipeDetails: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                timeView
                servingsView
            }
        }
    }
    
    private var recipeDescription: some View {
        Group {
            if let description = recipe.desc, !description.isEmpty {
                Section("Description") {
                    Text(description)
                        .lineSpacing(4)
                }
            }
        }
    }
    
    private func ingredientView(for recipeIngredient: RecipeIngredient) -> some View {
        let scaledQuantity = recipeIngredient.quantity * Double(servings) / Double(recipe.servings)
        return HStack(spacing: 12) {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 32, height: 32)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipeIngredient.ingredient?.name ?? "")
                    .font(.headline)
                Text(String(format: "%.2f %@", scaledQuantity, recipeIngredient.unit ?? ""))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var ingredientsSection: some View {
        Section("Ingredients") {
            ForEach(recipe.recipeIngredientsArray) { recipeIngredient in
                ingredientView(for: recipeIngredient)
            }
        }
    }
    
    private func stepView(for step: Step) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Step \(step.order + 1)")
                .font(.headline)
                .foregroundColor(.blue)
            
            Text(step.instructions ?? "")
            
            if let ingredients = step.ingredients as? Set<RecipeIngredient>, !ingredients.isEmpty {
                Text("Uses: " + ingredients.compactMap { $0.ingredient?.name }.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var stepsSection: some View {
        Group {
            if !recipe.stepsArray.isEmpty {
                Section("Instructions") {
                    ForEach(recipe.stepsArray) { step in
                        stepView(for: step)
                    }
                }
            }
        }
    }
    
    private var deleteSection: some View {
        Section {
            Button("Delete Recipe", role: .destructive) {
                showingDeleteAlert = true
            }
        }
    }
    
    var body: some View {
        List {
            recipeImage
            recipeDetails
            recipeDescription
            ingredientsSection
            stepsSection
            deleteSection
        }
        .id(refreshID)
        .navigationTitle(recipe.name ?? "Recipe Details")
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
            refreshID = UUID()
        } content: {
            EditRecipeView(recipe: recipe)
        }
        .alert("Delete Recipe", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteRecipe()
            }
        } message: {
            Text("Are you sure you want to delete this recipe? This action cannot be undone.")
        }
    }
    
    private func deleteRecipe() {
        viewContext.delete(recipe)
        try? viewContext.save()
        dismiss()
    }
} 