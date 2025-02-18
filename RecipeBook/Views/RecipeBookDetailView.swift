import SwiftUI
import CoreData

struct RecipeBookDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    let recipeBook: NSManagedObject
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingAddRecipesSheet = false
    
    private var recipes: Set<NSManagedObject> {
        recipeBook.value(forKey: "recipes") as? Set<NSManagedObject> ?? []
    }
    
    var body: some View {
        List {
            Section {
                HStack {
                    Text("\(recipes.count) recipes")
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Button {
                        showingAddRecipesSheet = true
                    } label: {
                        Label("Add Recipes", systemImage: "plus.circle.fill")
                            .labelStyle(.iconOnly)
                            .foregroundColor(.orange)
                    }
                }
            }
            
            if !recipes.isEmpty {
                Section("Recipes") {
                    ForEach(Array(recipes), id: \.self) { recipe in
                        NavigationLink {
                            Text(recipe.value(forKey: "name") as? String ?? "")
                        } label: {
                            Text(recipe.value(forKey: "name") as? String ?? "")
                        }
                        .swipeActions(edge: .trailing) {
                            Button(role: .destructive) {
                                removeRecipe(recipe)
                            } label: {
                                Label("Remove", systemImage: "trash")
                            }
                        }
                    }
                }
            }
            
            Section("Created") {
                if let createdAt = recipeBook.value(forKey: "createdAt") as? Date {
                    Text(createdAt.formatted(date: .long, time: .shortened))
                        .foregroundStyle(.secondary)
                }
            }
            
            Section("Last Updated") {
                if let updatedAt = recipeBook.value(forKey: "updatedAt") as? Date {
                    Text(updatedAt.formatted(date: .long, time: .shortened))
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle(recipeBook.value(forKey: "name") as? String ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        showingDeleteAlert = true
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .foregroundColor(.orange)
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            EditRecipeBookView(recipeBook: recipeBook)
        }
        .sheet(isPresented: $showingAddRecipesSheet) {
            RecipeSelectionView(recipeBook: recipeBook)
        }
        .alert("Delete Recipe Book", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                deleteRecipeBook()
            }
        } message: {
            Text("Are you sure you want to delete this recipe book? This action cannot be undone.")
        }
    }
    
    private func removeRecipe(_ recipe: NSManagedObject) {
        let recipeBooks = recipe.mutableSetValue(forKey: "recipeBooks")
        recipeBooks.remove(recipeBook)
        
        recipeBook.setValue(Date(), forKey: "updatedAt")
        try? viewContext.save()
    }
    
    private func deleteRecipeBook() {
        viewContext.delete(recipeBook)
        try? viewContext.save()
    }
} 