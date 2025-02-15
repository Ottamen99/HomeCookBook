import SwiftUI

struct IngredientDetailView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let ingredient: Ingredient
    
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    @State private var showingDeleteErrorAlert = false
    
    private var usedInRecipes: [Recipe] {
        let recipeIngredients = ingredient.recipeIngredients as? Set<RecipeIngredient> ?? []
        return recipeIngredients.compactMap { $0.recipe }.sorted { ($0.name ?? "") < ($1.name ?? "") }
    }
    
    private var canDelete: Bool {
        usedInRecipes.isEmpty
    }
    
    init(ingredient: Ingredient) {
        self.ingredient = ingredient
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.buttonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor.orange]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        
        UINavigationBar.appearance().tintColor = .orange
    }
    
    // Create a separate view for the toolbar buttons
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
                showingEditSheet = true
            } label: {
                Image(systemName: "pencil")
                    .foregroundColor(.black)
                    .padding()
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.1), radius: 5)
            }
        }
        .padding(.horizontal)
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(spacing: 24) {
                    // Ingredient icon
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .overlay {
                            Image(systemName: "leaf.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.orange)
                        }
                        .padding(.top, 40)
                    
                    // Name and description
                    VStack(spacing: 8) {
                        Text(ingredient.name ?? "")
                            .font(.title)
                            .fontWeight(.bold)
                        
                        if let description = ingredient.desc, !description.isEmpty {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                    
                    // Used in recipes section
                    if !usedInRecipes.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Used in Recipes")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            ForEach(usedInRecipes) { recipe in
                                NavigationLink {
                                    RecipeDetailView(recipe: recipe)
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(recipe.name ?? "")
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            
                                            if let quantity = recipe.recipeIngredients?
                                                .first(where: { ($0 as? RecipeIngredient)?.ingredient == ingredient }) as? RecipeIngredient {
                                                Text("\(String(format: "%.1f", quantity.quantity)) \(quantity.unit ?? "")")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14))
                                            .foregroundColor(.gray)
                                    }
                                    .padding()
                                    .background(Color(.systemBackground))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.orange.opacity(0.1), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding()
                    }
                }
                // Add padding at the bottom for the floating button
                Color.clear.frame(height: 100)
            }
            
            // Overlay toolbar at top
            VStack {
                toolbarButtons
                    .padding(.top, 8)
                
                Spacer()
                
                // Floating delete button
                VStack {
                    Button(action: {
                        if canDelete {
                            showingDeleteAlert = true
                        } else {
                            showingDeleteErrorAlert = true
                        }
                    }) {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Delete Ingredient")
                                .fontWeight(.semibold)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                    }
                    .padding()
                }
                .background(
                    Rectangle()
                        .fill(.white)
                        .shadow(color: .black.opacity(0.05), radius: 8, y: -4)
                )
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingEditSheet) {
            NavigationStack {
                IngredientFormView(mode: .edit(ingredient))
            }
        }
        .alert("Delete Ingredient", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                deleteIngredient()
            }
        } message: {
            Text("Are you sure you want to delete this ingredient? This action cannot be undone.")
        }
        .alert("Cannot Delete Ingredient", isPresented: $showingDeleteErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("This ingredient cannot be deleted because it is used in \(usedInRecipes.count) recipe\(usedInRecipes.count == 1 ? "" : "s"). Please remove it from all recipes first.")
        }
    }
    
    private func deleteIngredient() {
        viewContext.delete(ingredient)
        try? viewContext.save()
        dismiss()
    }
} 