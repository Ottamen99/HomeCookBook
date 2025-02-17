import SwiftUI

struct IngredientSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @Binding var selectedIngredients: [SelectedIngredient]
    @State private var searchText = ""
    @State private var showingAddSheet = false
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ingredient.name, ascending: true)],
        animation: .default)
    private var ingredients: FetchedResults<Ingredient>
    
    private var filteredIngredients: [Ingredient] {
        if searchText.isEmpty {
            return Array(ingredients)
        }
        return ingredients.filter { ($0.name ?? "").localizedCaseInsensitiveContains(searchText) }
    }
    
    private var toolbarButtons: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.1), radius: 5)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Text("Done")
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.orange)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.1), radius: 5)
            }
        }
        .padding(.horizontal)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 16) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                        
                        TextField("Search ingredients", text: $searchText)
                            .textFieldStyle(.plain)
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.top, 80)
                    
                    // Ingredients grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 12) {
                        ForEach(filteredIngredients) { ingredient in
                            let isSelected = selectedIngredients.contains { $0.ingredient == ingredient }
                            
                            Button {
                                toggleIngredient(ingredient)
                            } label: {
                                VStack(spacing: 12) {
                                    Circle()
                                        .fill(isSelected ? Color.orange.opacity(0.1) : Color.gray.opacity(0.1))
                                        .frame(width: 60, height: 60)
                                        .overlay {
                                            Image(systemName: "leaf.fill")
                                                .foregroundColor(isSelected ? .orange : .gray)
                                                .font(.system(size: 24))
                                        }
                                    
                                    Text(ingredient.name ?? "")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(isSelected ? .orange : .gray)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(isSelected ? Color.orange.opacity(0.2) : Color.gray.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                    }
                    .padding()
                }
            }
            
            // Overlay toolbar at top
            VStack {
                toolbarButtons
                    .padding(.top, 8)
                
                Spacer()
            }
        }
        .navigationBarHidden(true)
    }
    
    private func toggleIngredient(_ ingredient: Ingredient) {
        if let index = selectedIngredients.firstIndex(where: { $0.ingredient == ingredient }) {
            selectedIngredients.remove(at: index)
        } else {
            selectedIngredients.append(SelectedIngredient(
                ingredient: ingredient,
                quantity: 1,
                unit: .grams
            ))
        }
    }
} 