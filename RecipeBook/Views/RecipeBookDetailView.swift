import SwiftUI
import CoreData

struct RecipeBookDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let recipeBook: NSManagedObject
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingAddRecipesSheet = false
    @State private var refreshID = UUID()
    @AccessibilityFocusState private var isEmptyRecipesFocused: Bool
    
    private var recipes: Set<NSManagedObject> {
        guard !recipeBook.isDeleted && recipeBook.managedObjectContext != nil else {
            return []
        }
        return recipeBook.value(forKey: "recipes") as? Set<NSManagedObject> ?? []
    }
    
    private var sortedRecipes: [NSManagedObject] {
        Array(recipes).sorted { 
            ($0.value(forKey: "name") as? String ?? "") < ($1.value(forKey: "name") as? String ?? "")
        }
    }
    
    // Adaptive spacing based on dynamic type size
    private var verticalSpacing: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium:
            return 24
        case .large, .xLarge:
            return 28
        default:
            return 32
        }
    }
    
    private var toolbarButtons: some View {
        HStack {
            Button(action: { dismiss() }) {
                Label("Back", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(width: 44, height: 44) // Proper hit target size
                    .contentShape(Rectangle())
                    .accessibilityLabel("Go back")
            }
            
            Spacer()
            
            Menu {
                Button {
                    showingEditSheet = true
                } label: {
                    Label("Edit", systemImage: "pencil")
                }
                .accessibilityIdentifier("editButton")
                
                Button(role: .destructive) {
                    showingDeleteAlert = true
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .accessibilityIdentifier("deleteButton")
            } label: {
                Label("More Options", systemImage: "ellipsis.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 22))
                    .foregroundColor(.orange)
                    .frame(width: 44, height: 44) // Proper hit target size
                    .contentShape(Rectangle())
                    .accessibilityLabel("More options")
            }
        }
        .padding(.horizontal)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            toolbarButtons
                .padding(.top, 8)
                .padding(.bottom, 8)
            
            ScrollView {
                VStack(spacing: verticalSpacing) {
                    // Header
                    headerSection
                    
                    // Recipes list
                    recipesSection
                }
                .padding(.bottom, 20)
            }
            .scrollIndicators(.visible)
        }
        .id(refreshID)
        .navigationBarHidden(true)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingEditSheet, onDismiss: {
            viewContext.refresh(recipeBook, mergeChanges: true)
            refreshID = UUID()
        }) {
            NavigationStack {
                EditRecipeBookView(recipeBook: recipeBook)
            }
        }
        .sheet(isPresented: $showingAddRecipesSheet, onDismiss: {
            viewContext.refresh(recipeBook, mergeChanges: true)
            refreshID = UUID()
        }) {
            NavigationStack {
                RecipeSelectionView(recipeBook: recipeBook)
            }
        }
        .alert("Delete Recipe Book", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteRecipeBook()
            }
        } message: {
            Text("Are you sure you want to delete this recipe book? This action cannot be undone.")
        }
        .onAppear {
            if recipes.isEmpty {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isEmptyRecipesFocused = true
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    private var headerSection: some View {
        VStack(spacing: dynamicTypeSize > .large ? 16 : 12) {
            Text(recipeBook.value(forKey: "name") as? String ?? "")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal)
            
            Text(recipeBook.value(forKey: "desc") as? String ?? "A collection of your favorite recipes")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, horizontalSizeClass == .compact ? 24 : 32)
            
            // Stats row - adaptive layout for different text sizes
            statsRow
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
    
    private var statsRow: some View {
        Group {
            if dynamicTypeSize > .xLarge {
                // Vertical layout for very large text sizes
                VStack(spacing: 16) {
                    Stat(value: "\(recipes.count)", label: "Recipes")
                    
                    if let createdAt = recipeBook.value(forKey: "createdAt") as? Date {
                        Stat(value: createdAt.formatted(date: .abbreviated, time: .omitted), label: "Created")
                    }
                    
                    if let updatedAt = recipeBook.value(forKey: "updatedAt") as? Date {
                        Stat(value: updatedAt.formatted(date: .abbreviated, time: .omitted), label: "Last Update")
                    }
                }
            } else {
                // Horizontal layout for normal text sizes
                HStack(spacing: 24) {
                    Stat(value: "\(recipes.count)", label: "Recipes")
                    
                    if let createdAt = recipeBook.value(forKey: "createdAt") as? Date {
                        Stat(value: createdAt.formatted(date: .abbreviated, time: .omitted), label: "Created")
                    }
                    
                    if let updatedAt = recipeBook.value(forKey: "updatedAt") as? Date {
                        Stat(value: updatedAt.formatted(date: .abbreviated, time: .omitted), label: "Last Update")
                    }
                }
            }
        }
        .padding(.top, 8)
    }
    
    private var recipesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recipes")
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                
                Spacer()
                
                Button {
                    showingAddRecipesSheet = true
                } label: {
                    Label("Manage Recipes", systemImage: "plus.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.orange)
                        .clipShape(Capsule())
                        .contentShape(Capsule())
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                }
                .accessibilityLabel("Add recipes to this book")
                .buttonStyle(ScaleButtonStyle())
            }
            .padding(.horizontal)
            
            if recipes.isEmpty {
                emptyRecipesView
            } else {
                recipesList
            }
        }
    }
    
    private var emptyRecipesView: some View {
        VStack(spacing: 16) {
            Image(systemName: "book")
                .font(.system(size: 50))
                .foregroundColor(.orange.opacity(0.7))
                .padding(.bottom, 8)
                .accessibilityHidden(true)
            
            Text("No recipes yet")
                .font(.headline)
                .foregroundColor(.secondary)
                .accessibilityFocused($isEmptyRecipesFocused)
            
            Text("Tap the 'Manage Recipes' button to add recipes to this book")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
            
            Button {
                showingAddRecipesSheet = true
            } label: {
                Label("Add Recipes", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.orange)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
            }
            .padding(.top, 8)
            .buttonStyle(ScaleButtonStyle())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 32)
    }
    
    private var recipesList: some View {
        LazyVStack(spacing: 0) {
            ForEach(sortedRecipes, id: \.self) { recipe in
                let castedRecipe = recipe as! Recipe
                NavigationLink {
                    RecipeDetailView(recipe: castedRecipe)
                } label: {
                    RecipeRowView(recipe: castedRecipe)
                        .padding(.horizontal)
                        .contentShape(Rectangle())
                }
                .buttonStyle(RecipeRowButtonStyle())
                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                    Button(role: .destructive) {
                        withAnimation {
                            removeRecipe(recipe)
                        }
                    } label: {
                        Label("Remove", systemImage: "minus.circle.fill")
                    }
                    .tint(.red)
                    .accessibilityLabel("Remove from recipe book")
                }
                
                if recipe != sortedRecipes.last {
                    Divider()
                        .padding(.horizontal)
                }
            }
        }
    }
    
    private func removeRecipe(_ recipe: NSManagedObject) {
        withAnimation {
            let recipeBooks = recipe.mutableSetValue(forKey: "recipeBooks")
            recipeBooks.remove(recipeBook)
            
            recipeBook.setValue(Date(), forKey: "updatedAt")
            
            do {
                try viewContext.save()
                viewContext.refresh(recipeBook, mergeChanges: true)
                refreshID = UUID()
            } catch {
                print("Error removing recipe: \(error)")
            }
        }
    }
    
    private func deleteRecipeBook() {
        guard !recipeBook.isDeleted && recipeBook.managedObjectContext != nil else {
            dismiss()
            return
        }
        
        viewContext.delete(recipeBook)
        try? viewContext.save()
        dismiss()
    }
}

// MARK: - Supporting Views and Styles

struct Stat: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label): \(value)")
        .frame(minWidth: 80)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct RecipeRowButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(configuration.isPressed ? Color.gray.opacity(0.1) : Color.clear)
            .contentShape(Rectangle())
    }
}

// MARK: - Preview
struct RecipeBookDetailView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Standard preview
            NavigationStack {
                RecipeBookDetailView(recipeBook: createPreviewRecipeBook())
                    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            }
            .previewDisplayName("Light Mode")
            
            // Dark mode preview
            NavigationStack {
                RecipeBookDetailView(recipeBook: createPreviewRecipeBook())
                    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
            
            // Accessibility preview with larger text
            NavigationStack {
                RecipeBookDetailView(recipeBook: createPreviewRecipeBook())
                    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            }
            .environment(\.dynamicTypeSize, .xxxLarge)
            .previewDisplayName("Large Text")
        }
    }
    
    static func createPreviewRecipeBook() -> NSManagedObject {
        let context = PersistenceController.preview.container.viewContext
        let recipeBook = NSEntityDescription.insertNewObject(forEntityName: "RecipeBook", into: context)
        recipeBook.setValue("Italian Favorites", forKey: "name")
        recipeBook.setValue("A collection of classic Italian recipes", forKey: "desc")
        recipeBook.setValue(Date(), forKey: "createdAt")
        recipeBook.setValue(Date(), forKey: "updatedAt")
        return recipeBook
    }
} 
