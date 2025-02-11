import SwiftUI
import CoreData

struct AvailableRecipesView: View {
    @ObservedObject var viewModel: PantryViewModel
    
    var body: some View {
        List {
            if viewModel.availableRecipes.isEmpty {
                Section {
                    VStack(spacing: 12) {
                        Image(systemName: "book.closed")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        
                        Text("No Available Recipes")
                            .font(.headline)
                        
                        Text("Add more ingredients to your pantry to see recipes you can make.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
                    .listRowBackground(Color.clear)
                }
            } else {
                ForEach(viewModel.availableRecipes) { recipe in
                    NavigationLink {
                        RecipeDetailView(recipe: recipe)
                    } label: {
                        RecipeRowView(recipe: recipe)
                    }
                }
            }
        }
        .navigationTitle("Available Recipes")
    }
} 