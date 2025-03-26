import SwiftUI
import CoreData

struct RecipeBooksGridView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingAddSheet = false
    @AccessibilityFocusState private var isEmptyStateFocused: Bool
    @State private var searchText = ""
    
    @FetchRequest(
        entity: NSEntityDescription.entity(forEntityName: "RecipeBook", in: PersistenceController.shared.container.viewContext)!,
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
        animation: .default)
    private var recipeBooks: FetchedResults<NSManagedObject>
    
    // Adaptive grid that responds to dynamic type size
    private var columns: [GridItem] {
        let minWidth: CGFloat = dynamicTypeSize > .large ? 180 : 160
        return [GridItem(.adaptive(minimum: minWidth), spacing: 16)]
    }
    
    // Add filtered recipe books computed property
    private var filteredRecipeBooks: [NSManagedObject] {
        if searchText.isEmpty {
            return Array(recipeBooks)
        }
        return recipeBooks.filter { book in
            guard let name = book.value(forKey: "name") as? String else { return false }
            return name.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if recipeBooks.isEmpty {
                    emptyStateView
                } else if filteredRecipeBooks.isEmpty && !searchText.isEmpty {
                    emptySearchResultsView
                } else {
                    recipeBooksGrid
                }
            }
            .scrollIndicators(.visible)
            .searchable(text: $searchText, prompt: "Search recipe books")
            .navigationTitle("Recipe Books")
            .toolbar {
                if !recipeBooks.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingAddSheet = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                Text("Add")
                            }
                            .font(.headline)
                            .foregroundColor(.orange)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.1))
                            )
                            .contentShape(Capsule())
                        }
                        .accessibilityLabel("Add Recipe Book")
                        .buttonStyle(PressEffectButtonStyle())
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationStack {
                    AddRecipeBookView()
                }
            }
            .onAppear {
                if recipeBooks.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isEmptyStateFocused = true
                    }
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)
            
            Image(systemName: "books.vertical.circle")
                .font(.system(size: 80))
                .foregroundColor(.orange)
                .accessibilityHidden(true)
            
            Text("No Recipe Books")
                .font(.title2.bold())
                .foregroundColor(.primary)
                .accessibilityFocused($isEmptyStateFocused)
            
            Text("Create your first recipe book to start organizing your recipes")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
            
            Button {
                showingAddSheet = true
            } label: {
                Label("Create Recipe Book", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.vertical, 14)
                    .frame(maxWidth: 280)
                    .frame(height: 54) // Taller button for better hit target
                    .background(Color.orange)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            }
            .accessibilityHint("Opens a form to create a new recipe book")
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 20)
    }
    
    private var recipeBooksGrid: some View {
        LazyVGrid(columns: columns, spacing: dynamicTypeSize > .large ? 20 : 16) {
            ForEach(filteredRecipeBooks, id: \.self) { book in
                NavigationLink(destination: RecipeBookDetailView(recipeBook: book)) {
                    RecipeBookTile(recipeBook: book)
                        .accessibilityElement(children: .combine)
                        .accessibilityLabel("\(book.value(forKey: "name") as? String ?? "Recipe Book"), \((book.value(forKey: "recipes") as? Set<NSManagedObject>)?.count ?? 0) recipes")
                }
                .buttonStyle(RecipeBookButtonStyle())
            }
        }
        .padding(16)
    }
    
    // Add empty search results view
    private var emptySearchResultsView: some View {
        VStack(spacing: 24) {
            Spacer()
                .frame(height: 40)
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .accessibilityHidden(true)
            
            Text("No Matching Recipe Books")
                .font(.title2.bold())
                .foregroundColor(.primary)
            
            Text("Try a different search term or create a new recipe book")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .fixedSize(horizontal: false, vertical: true)
            
            Button {
                searchText = ""
            } label: {
                Text("Clear Search")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: 200)
                    .background(Color.secondary.opacity(0.1))
                    .foregroundColor(.primary)
                    .cornerRadius(10)
            }
            .padding(.top, 8)
            
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Supporting Views and Styles

struct RecipeBookButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct RecipeBookTile: View {
    let recipeBook: NSManagedObject
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var recipeCount: Int {
        (recipeBook.value(forKey: "recipes") as? Set<NSManagedObject>)?.count ?? 0
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Book cover
            bookCoverView
            
            // Book details
            bookDetailsView
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(colorScheme == .dark ? 
                      Color(UIColor.secondarySystemBackground) : 
                      Color(UIColor.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var bookCoverView: some View {
        ZStack(alignment: .bottomTrailing) {
            Rectangle()
                .fill(Color.orange.opacity(0.15))
                .frame(height: dynamicTypeSize > .large ? 100 : 120)
            
            Image(systemName: "book.closed")
                .font(.system(size: 40))
                .foregroundColor(.orange.opacity(0.5))
                .padding(16)
            
            if recipeCount > 0 {
                Text("\(recipeCount)")
                    .font(.caption.bold())
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange)
                    )
                    .padding(8)
            }
        }
    }
    
    private var bookDetailsView: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(recipeBook.value(forKey: "name") as? String ?? "")
                .font(.headline)
                .foregroundColor(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.9)
            
            HStack {
                Text("\(recipeCount) \(recipeCount == 1 ? "recipe" : "recipes")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let createdAt = recipeBook.value(forKey: "createdAt") as? Date {
                    Text(formatDate(createdAt))
                        .font(.caption2)
                        .foregroundColor(.secondary.opacity(0.8))
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}

// MARK: - Preview
struct RecipeBooksGridView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Standard preview
            RecipeBooksGridView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .previewDisplayName("Light Mode")
            
            // Dark mode preview
            RecipeBooksGridView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
            
            // Accessibility preview with larger text
            RecipeBooksGridView()
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .environment(\.dynamicTypeSize, .xxxLarge)
                .previewDisplayName("Large Text")
        }
    }
} 
