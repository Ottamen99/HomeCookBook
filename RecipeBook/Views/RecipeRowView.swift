import SwiftUI

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
                    .foregroundColor(.orange)
                
                if let description = recipe.desc, !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
                
                HStack(spacing: 12) {
                    Label("\(recipe.timeInMinutes) min", systemImage: "clock")
                    Label("\(recipe.servings) servings", systemImage: "person.2")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let recipe = Recipe(context: context)
    recipe.name = "Spaghetti Carbonara"
    recipe.desc = "A classic Italian pasta dish"
    recipe.timeInMinutes = 30
    recipe.servings = 4
    
    return RecipeRowView(recipe: recipe)
        .previewLayout(.sizeThatFits)
        .padding()
} 