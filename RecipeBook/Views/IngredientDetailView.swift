import SwiftUI

struct IngredientDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let ingredient: Ingredient
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingDeleteErrorAlert = false
    
    private var usedInRecipes: [Recipe] {
        let recipeIngredients = ingredient.recipeIngredients as? Set<RecipeIngredient> ?? []
        return recipeIngredients.compactMap { $0.recipe }.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    private var canDelete: Bool {
        usedInRecipes.isEmpty
    }
    
    private var iconBackground: Color {
        colorScheme == .dark ? Color.orange.opacity(0.2) : Color.orange.opacity(0.1)
    }
    
    init(ingredient: Ingredient) {
        self.ingredient = ingredient
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.orange]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        UINavigationBar.appearance().tintColor = .orange
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Header section with icon and name
                headerSection
                
                // Description section
                if let description = ingredient.desc, !description.isEmpty {
                    descriptionSection(description)
                }
                
                // Used in recipes section
                if !usedInRecipes.isEmpty {
                    recipesSection
                }
                
                Spacer(minLength: 40)
                
                // Delete button
                if canDelete {
                    deleteButton
                } else {
                    cannotDeleteMessage
                }
            }
            .padding()
        }
        .navigationTitle("Ingredient Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .tint(.orange)
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                IngredientFormView(mode: .edit(ingredient))
            }
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
            Text("This ingredient is used in \(usedInRecipes.count) recipe\(usedInRecipes.count == 1 ? "" : "s"). Please remove it from all recipes first.")
        }
    }
    
    // MARK: - View Components
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(iconBackground)
                .frame(width: 120, height: 120)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.orange)
                        .symbolEffect(.pulse, value: showingEditSheet)
                }
                .shadow(color: Color.orange.opacity(0.2), radius: 10, x: 0, y: 5)
                .accessibilityHidden(true)
                .padding(.top, 10)
            
            Text(ingredient.name ?? "")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .accessibilityAddTraits(.isHeader)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func descriptionSection(_ description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("About")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 1)
                .accessibilityAddTraits(.isHeader)
            
            Text(description)
                .font(.body)
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }
    
    private var recipesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Used in \(usedInRecipes.count) Recipe\(usedInRecipes.count == 1 ? "" : "s")")
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.horizontal, 9)
                .accessibilityAddTraits(.isHeader)
            
            ForEach(usedInRecipes) { recipe in
                NavigationLink(destination: RecipeDetailView(recipe: recipe)) {
                    recipeRow(recipe)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 8)
    }
    
    private func recipeRow(_ recipe: Recipe) -> some View {
        HStack(spacing: 12) {
            // Recipe icon
            Circle()
                .fill(Color.orange.opacity(0.1))
                .frame(width: 50, height: 50)
                .overlay {
                    Image(systemName: "fork.knife")
                        .foregroundColor(.orange)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name ?? "")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let quantity = recipe.recipeIngredients?
                    .first(where: { ($0 as? RecipeIngredient)?.ingredient == ingredient }) as? RecipeIngredient {
                    Text("\(formatQuantity(quantity.quantity)) \(quantity.unit ?? "")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .contentShape(Rectangle())
    }
    
    private var deleteButton: some View {
        Button(action: {
            showingDeleteAlert = true
        }) {
            Label("Delete Ingredient", systemImage: "trash")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(10)
        }
        .padding(.horizontal, 8)
        .accessibilityIdentifier("DeleteIngredientButton")
    }
    
    private var cannotDeleteMessage: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
            
            Text("This ingredient is used in recipes and cannot be deleted")
                .font(.callout)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
                .background(Color.orange.opacity(0.05).cornerRadius(10))
        )
        .padding(.horizontal, 8)
    }
    
    // MARK: - Helper Methods
    
    private func formatQuantity(_ value: Double) -> String {
        // If it's a whole number, show as integer
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(value))"
        } else {
            // Otherwise show with 1 decimal place
            return String(format: "%.1f", value)
        }
    }
    
    private func deleteIngredient() {
        let generator = UINotificationFeedbackGenerator()
        
        viewContext.delete(ingredient)
        
        do {
            try viewContext.save()
            generator.notificationOccurred(.success)
            dismiss()
        } catch {
            generator.notificationOccurred(.error)
            print("Error deleting ingredient: \(error.localizedDescription)")
        }
    }
}

// MARK: - Previews

struct IngredientDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            IngredientDetailView(ingredient: createSampleIngredient())
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
        .previewDisplayName("Ingredient Detail")
        
        NavigationStack {
            IngredientDetailView(ingredient: createSampleIngredientWithRecipes())
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
        }
        .previewDisplayName("Ingredient with Recipes")
        
        NavigationStack {
            IngredientDetailView(ingredient: createSampleIngredient())
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .preferredColorScheme(.dark)
        }
        .previewDisplayName("Dark Mode")
    }
    
    static func createSampleIngredient() -> Ingredient {
        let context = PersistenceController.preview.container.viewContext
        let ingredient = Ingredient(context: context)
        ingredient.name = "Flour"
        ingredient.desc = "All-purpose flour is a versatile ingredient used in baking. It's made from wheat and has a moderate protein content, making it suitable for cakes, cookies, bread, and more."
        return ingredient
    }
    
    static func createSampleIngredientWithRecipes() -> Ingredient {
        let context = PersistenceController.preview.container.viewContext
        let ingredient = Ingredient(context: context)
        ingredient.name = "Butter"
        ingredient.desc = "A dairy product made from churning cream or milk. Used in baking and cooking for flavor and texture."
        
        // Create recipe 1
        let recipe1 = Recipe(context: context)
        recipe1.name = "Chocolate Chip Cookies"
        
        // Create recipe ingredient 1
        let recipeIngredient1 = RecipeIngredient(context: context)
        recipeIngredient1.ingredient = ingredient
        recipeIngredient1.recipe = recipe1
        recipeIngredient1.quantity = 125
        recipeIngredient1.unit = "g"
        
        // Create recipe 2
        let recipe2 = Recipe(context: context)
        recipe2.name = "Butter Cake"
        
        // Create recipe ingredient 2
        let recipeIngredient2 = RecipeIngredient(context: context)
        recipeIngredient2.ingredient = ingredient
        recipeIngredient2.recipe = recipe2
        recipeIngredient2.quantity = 200
        recipeIngredient2.unit = "g"
        
        return ingredient
    }
} 