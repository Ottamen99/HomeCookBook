import SwiftUI
import CoreData

struct PantryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \PantryIngredient.dateAdded, ascending: false)],
        animation: .default
    ) private var pantryIngredients: FetchedResults<PantryIngredient>
    
    @State private var showingAddIngredient = false
    @State private var searchText = ""
    
    @StateObject private var viewModel: PantryViewModel
    
    init() {
        _viewModel = StateObject(wrappedValue: PantryViewModel(viewContext: PersistenceController.shared.container.viewContext))
    }
    
    var filteredIngredients: [PantryIngredient] {
        if searchText.isEmpty {
            return Array(pantryIngredients)
        }
        return pantryIngredients.filter { ($0.ingredient?.name ?? "").localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            List {
                // Recipe Suggestions Section
                Section {
                    NavigationLink {
                        AvailableRecipesView(viewModel: viewModel)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Available Recipes", systemImage: "checkmark.circle.fill")
                                .font(.headline)
                            Text("Recipes you can make with your ingredients")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    NavigationLink {
                        AlmostAvailableRecipesView(viewModel: viewModel)
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Label("Almost Available", systemImage: "circle.dotted")
                                .font(.headline)
                            Text("Recipes that need just a few more ingredients")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                
                // Pantry Ingredients Section
                Section("My Ingredients") {
                    ForEach(filteredIngredients) { pantryIngredient in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(pantryIngredient.ingredient?.name ?? "")
                                    .font(.headline)
                                Text("\(String(format: "%.1f", pantryIngredient.quantity)) \(pantryIngredient.unit ?? "")")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                showingEditIngredient(pantryIngredient)
                            } label: {
                                Image(systemName: "pencil")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .onDelete(perform: deleteIngredients)
                }
            }
            .navigationTitle("My Pantry")
            .searchable(text: $searchText, prompt: "Search ingredients")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddIngredient = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddIngredient) {
                AddPantryIngredientView(viewModel: viewModel)
            }
        }
    }
    
    private func deleteIngredients(offsets: IndexSet) {
        withAnimation {
            offsets.map { pantryIngredients[$0] }.forEach(viewContext.delete)
            try? viewContext.save()
            viewModel.updateRecipeAvailability()
        }
    }
    
    private func showingEditIngredient(_ ingredient: PantryIngredient) {
        // Show edit sheet
    }
}
