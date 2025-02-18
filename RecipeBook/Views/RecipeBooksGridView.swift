import SwiftUI
import CoreData

struct RecipeBooksGridView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var showingAddSheet = false
    
    @FetchRequest(
        entity: NSEntityDescription.entity(forEntityName: "RecipeBook", in: PersistenceController.shared.container.viewContext)!,
        sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)],
        animation: .default)
    private var recipeBooks: FetchedResults<NSManagedObject>
    
    private let columns = [
        GridItem(.adaptive(minimum: 160), spacing: 16)
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                if recipeBooks.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "books.vertical.circle")
                            .font(.system(size: 64))
                            .foregroundColor(.orange)
                        
                        Text("No Recipe Books")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Create your first recipe book to start organizing your recipes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        Button {
                            showingAddSheet = true
                        } label: {
                            Label("Create Recipe Book", systemImage: "plus.circle.fill")
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.orange)
                                .cornerRadius(12)
                        }
                        .padding(.horizontal)
                        .padding(.top)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 60)
                } else {
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(recipeBooks, id: \.self) { book in
                            NavigationLink {
                                // TODO: Implement RecipeBookDetailView
                                Text(book.value(forKey: "name") as? String ?? "")
                            } label: {
                                RecipeBookTile(recipeBook: book)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Recipe Books")
            .toolbar {
                if !recipeBooks.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingAddSheet = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddRecipeBookView()
            }
        }
    }
}

struct RecipeBookTile: View {
    let recipeBook: NSManagedObject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Circle()
                .fill(Color.orange.opacity(0.1))
                .frame(height: 100)
                .overlay {
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 32))
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipeBook.value(forKey: "name") as? String ?? "")
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text("\((recipeBook.value(forKey: "recipes") as? Set<NSManagedObject>)?.count ?? 0) recipes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let updatedAt = recipeBook.value(forKey: "updatedAt") as? Date {
                        Text(updatedAt, style: .relative)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

#Preview {
    RecipeBooksGridView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 