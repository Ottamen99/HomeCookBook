import SwiftUI
import CoreData

struct RecipeBookDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let recipeBook: NSManagedObject
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingAddRecipesSheet = false
    @State private var refreshID = UUID()
    
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
    
    private var toolbarButtons: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.black)
                    .frame(width: 20, height: 20)
                    .padding(8)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 5)
            }
            
            Spacer()
            
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
                Image(systemName: "ellipsis.circle.fill")
                    .foregroundColor(.orange)
                    .frame(width: 20, height: 20)
                    .padding(8)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 5)
            }
        }
        .padding(.horizontal)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            toolbarButtons
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 16) {
                        Text(recipeBook.value(forKey: "name") as? String ?? "")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(recipeBook.value(forKey: "desc") as? String ?? "A collection of your favorite recipes")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // Stats row
                        HStack(spacing: 24) {
                            Stat(value: "\(recipes.count)", label: "Recipes")
                            
                            if let createdAt = recipeBook.value(forKey: "createdAt") as? Date {
                                Stat(value: createdAt.formatted(date: .abbreviated, time: .omitted), label: "Created")
                            }
                            
                            if let updatedAt = recipeBook.value(forKey: "updatedAt") as? Date {
                                Stat(value: updatedAt.formatted(date: .abbreviated, time: .omitted), label: "Last Update")
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal)
                    
                    // Recipes list
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Recipes")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                showingAddRecipesSheet = true
                            } label: {
                                Label("Add Recipes", systemImage: "plus.circle.fill")
                                    .font(.system(size: 14))
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.orange)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .padding(.horizontal)
                        
                        if recipes.isEmpty {
                            VStack(spacing: 12) {
                                Text("No recipes yet")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                        } else {
                            ForEach(sortedRecipes, id: \.self) { recipe in
                                NavigationLink {
                                    if let recipe = recipe as? Recipe {
                                        RecipeDetailView(recipe: recipe)
                                    }
                                } label: {
                                    RecipeRowView(recipe: recipe as! Recipe)
                                        .padding(.horizontal)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        withAnimation {
                                            removeRecipe(recipe)
                                        }
                                    } label: {
                                        Label("Remove", systemImage: "minus.circle.fill")
                                    }
                                    .tint(.red)
                                }
                                
                                if recipe != sortedRecipes.last {
                                    Divider()
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }
                }
            }
        }
        .id(refreshID)
        .navigationBarHidden(true)
        .background(Color(.systemBackground))
        .sheet(isPresented: $showingEditSheet, onDismiss: {
            viewContext.refresh(recipeBook, mergeChanges: true)
            refreshID = UUID()
        }) {
            EditRecipeBookView(recipeBook: recipeBook)
        }
        .sheet(isPresented: $showingAddRecipesSheet, onDismiss: {
            viewContext.refresh(recipeBook, mergeChanges: true)
            refreshID = UUID()
        }) {
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

struct Stat: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
} 
