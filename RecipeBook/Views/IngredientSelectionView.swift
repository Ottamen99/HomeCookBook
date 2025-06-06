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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    
                    // Ingredients grid
                    ingredientsGrid
                        .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Select Ingredients")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        saveWithHaptics()
                    }
                    .fontWeight(.semibold)
                }
            }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer,
                prompt: "Search ingredients"
            )
        }
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search ingredients", text: $searchText)
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
        }
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private var ingredientsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            ForEach(filteredIngredients) { ingredient in
                IngredientCell(
                    ingredient: ingredient,
                    isSelected: selectedIngredients.contains { $0.ingredient == ingredient },
                    onTap: { toggleIngredient(ingredient) }
                )
            }
        }
    }
    
    private func toggleIngredient(_ ingredient: Ingredient) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.prepare()
        
        withAnimation(.spring(response: 0.3)) {
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
        
        generator.impactOccurred()
    }
    
    private func saveWithHaptics() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        dismiss()
    }
}

// MARK: - IngredientCell
private struct IngredientCell: View {
    let ingredient: Ingredient
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            cellContent
        }
        .buttonStyle(.plain)
        .accessibilityLabel(ingredient.name ?? "")
        .accessibilityValue(isSelected ? "Selected" : "Not selected")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    private var cellContent: some View {
        VStack(spacing: 12) {
            ingredientIcon
            ingredientName
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 12)
        .background(cellBackground)
        .overlay(cellBorder)
    }
    
    private var ingredientIcon: some View {
        Circle()
            .fill(isSelected ? Color.orange.opacity(0.1) : .secondary.opacity(0.1))
            .frame(width: 60, height: 60)
            .overlay(iconImage)
    }
    
    private var iconImage: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: 24))
            .symbolRenderingMode(.hierarchical)
            .foregroundColor(isSelected ? .orange : .secondary)
    }
    
    private var ingredientName: some View {
        Text(ingredient.name ?? "")
            .font(.subheadline.weight(.medium))
            .foregroundColor(isSelected ? .orange : .primary)
            .lineLimit(2)
            .multilineTextAlignment(.center)
    }
    
    private var cellBackground: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(.regularMaterial)
    }
    
    private var cellBorder: some View {
        RoundedRectangle(cornerRadius: 12)
            .strokeBorder(isSelected ? Color.orange.opacity(0.3) : .clear, lineWidth: 1)
    }
}

#Preview {
    NavigationStack {
        IngredientSelectionView(selectedIngredients: .constant([]))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 
