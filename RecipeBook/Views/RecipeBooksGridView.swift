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
                                RecipeBookDetailView(recipeBook: book)
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
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipeBook.value(forKey: "name") as? String ?? "")
                    .font(.headline)
                    .foregroundColor(.orange)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    Text("\((recipeBook.value(forKey: "recipes") as? Set<NSManagedObject>)?.count ?? 0) recipes")
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
            .padding(.horizontal, 8)
            .padding(.vertical, 12)
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