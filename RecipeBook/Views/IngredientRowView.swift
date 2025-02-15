import SwiftUI

struct IngredientRowView: View {
    let ingredient: Ingredient
    
    var body: some View {
        HStack(spacing: 12) {
            // Ingredient icon
            Circle()
                .fill(Color.orange.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 16))
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(ingredient.name ?? "")
                    .font(.headline)
                Text("Used in \(ingredient.recipeIngredients?.count ?? 0) recipes")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let ingredient = Ingredient(context: context)
    ingredient.name = "Sample Ingredient"
    
    return NavigationStack {
        List {
            IngredientRowView(ingredient: ingredient)
                .listRowInsets(EdgeInsets())
        }
        .listStyle(.plain)
    }
} 