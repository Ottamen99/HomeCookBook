import SwiftUI
import CoreData

struct AlmostAvailableRecipesView: View {
    @ObservedObject var viewModel: PantryViewModel
    
    var body: some View {
        List {
            if viewModel.almostAvailableRecipes.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "book")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        
                        Text("No Almost Available Recipes")
                            .font(.headline)
                        
                        Text("Add more ingredients to your pantry to see recipes you're close to making.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(viewModel.almostAvailableRecipes, id: \.recipe.objectID) { item in
                    NavigationLink {
                        RecipeDetailView(recipe: item.recipe)
                    } label: {
                        VStack(alignment: .leading, spacing: 8) {
                            RecipeRowView(recipe: item.recipe)
                            
                            Text("Missing ingredients:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                            ForEach(item.missing) { ingredient in
                                Label {
                                    Text("\(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit ?? "") \(ingredient.ingredient?.name ?? "")")
                                } icon: {
                                    Image(systemName: "circle.fill")
                                        .font(.system(size: 6))
                                }
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Almost Available")
    }
} 