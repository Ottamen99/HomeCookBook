import SwiftUI

struct IngredientRowView: View {
    @ObservedObject var ingredient: Ingredient
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 16) {
            // Ingredient icon
            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 50, height: 50)
                
                Image(systemName: "leaf.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.orange)
            }
            
            // Ingredient details
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name ?? "")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                if let description = ingredient.desc, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                // Show recipe count if used in recipes
                if let recipeIngredients = ingredient.recipeIngredients, recipeIngredients.count > 0 {
                    Text("Used in \(recipeIngredients.count) \(recipeIngredients.count == 1 ? "recipe" : "recipes")")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 2)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.trailing, 4)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // Ensure the entire row is tappable
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    
    // Create sample ingredient
    let flour = Ingredient(context: context)
    flour.name = "Flour"
    flour.desc = "All-purpose flour"
    
    // Create a sample recipe to show "Used in X recipes"
    let recipe = Recipe(context: context)
    recipe.name = "Cookies"
    
    let recipeIngredient = RecipeIngredient(context: context)
    recipeIngredient.ingredient = flour
    recipeIngredient.recipe = recipe
    recipeIngredient.quantity = 250
    recipeIngredient.unit = "grams"
    
    try? context.save()
    
    return IngredientRowView(ingredient: flour)
        .previewLayout(.sizeThatFits)
        .padding()
        .environment(\.managedObjectContext, context)
} 