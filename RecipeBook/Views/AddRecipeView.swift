import SwiftUI

struct AddRecipeView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: RecipeViewModel
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Ingredient.name, ascending: true)],
        animation: .default)
    private var ingredients: FetchedResults<Ingredient>
    
    @State private var name = ""
    @State private var description = ""
    @State private var timeInMinutes: Int16 = 30
    @State private var servings: Int16 = 2
    @State private var selectedIngredients: [SelectedIngredient] = []
    @State private var showingIngredientSheet = false
    @State private var image: UIImage?
    @State private var activeSheet: AddRecipeSheet?
    @State private var difficulty: Difficulty = .medium
    
    private var recipeImage: some View {
        VStack(spacing: 24) {
            // Circular image
            Group {
                if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 250, height: 250)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color(.systemGray6), lineWidth: 1))
                        .shadow(color: .black.opacity(0.1), radius: 8)
                } else {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 250, height: 250)
                        .overlay {
                            Image(systemName: "fork.knife.circle.fill")
                                .font(.system(size: 80))
                                .foregroundColor(.orange)
                        }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                Button {
                    activeSheet = .imagePicker
                } label: {
                    Image(systemName: "camera.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(.white, Color.orange)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .offset(x: -8, y: -8)
            }
            
            // Recipe name input
            TextField("Recipe Name", text: $name)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            // Stats row
            HStack(spacing: 20) {
                // Time
                HStack(spacing: 4) {
                    Button(action: {
                        if timeInMinutes > 1 {
                            timeInMinutes -= 1
                        }
                    }) {
                        Image(systemName: "minus")
                            .foregroundColor(.black)
                            .frame(width: 10, height: 10)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    VStack {
                        Text("\(timeInMinutes)")
                            .fontWeight(.bold)
                        Text("min")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 50)
                    
                    Button(action: {
                        if timeInMinutes < 480 {
                            timeInMinutes += 1
                        }
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.black)
                            .frame(width: 10, height: 10)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .font(.body)
                
                // Servings
                HStack(spacing: 4) {
                    Button(action: { 
                        if servings > 1 {
                            servings -= 1
                        }
                    }) {
                        Image(systemName: "minus")
                            .foregroundColor(.black)
                            .frame(width: 10, height: 10)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    VStack {
                        Text("\(servings)")
                            .fontWeight(.bold)
                        Text("serve")
                            .foregroundColor(.gray)
                    }
                    .frame(width: 50)
                    
                    Button(action: { 
                        if servings < 20 {
                            servings += 1
                        }
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.black)
                            .frame(width: 10, height: 10)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .font(.body)
                
                // Difficulty selector
                VStack(spacing: 4) {
                    Menu {
                        Picker("Difficulty", selection: $difficulty) {
                            ForEach(Difficulty.allCases, id: \.self) { level in
                                Label(level.rawValue, systemImage: level.icon)
                                    .foregroundColor(level.color)
                                    .tag(level)
                            }
                        }
                    } label: {
                        VStack {
                            Image(systemName: difficulty.icon)
                                .foregroundColor(difficulty.color)
                            Text(difficulty.rawValue)
                                .foregroundColor(.gray)
                        }
                        .frame(width: 70)
                    }
                }
            }
            .padding()
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.gray, lineWidth: 0.5)
            )
        }
        .padding(.top, 40)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    recipeImage
                    
                    // Description
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Description")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        TextField("Add a description", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
                    
                    // Ingredients
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Ingredients")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Button {
                                activeSheet = .ingredients
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundColor(.orange)
                            }
                        }
                        
                        ForEach($selectedIngredients) { $ingredient in
                            HStack {
                                Text(ingredient.ingredient.name ?? "")
                                    .font(.body)
                                    .lineLimit(1)
                                
                                Spacer()
                                
                                HStack(spacing: 8) {
                                    TextField("Qty", value: $ingredient.quantity, format: .number)
                                        .keyboardType(.decimalPad)
                                        .frame(width: 50)
                                        .multilineTextAlignment(.trailing)
                                    
                                    Picker("Unit", selection: $ingredient.unit) {
                                        ForEach(UnitOfMeasure.allCases, id: \.self) { unit in
                                            Text(unit.displayName).tag(unit)
                                        }
                                    }
                                    .foregroundColor(.orange)
                                    .pickerStyle(.menu)
                                    .frame(width: 120)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                    
                    // Add padding for the bottom button
                    Color.clear.frame(height: 100)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("New Recipe")
                        .font(.headline)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    saveRecipe()
                    dismiss()
                }) {
                    Text("Create Recipe")
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .disabled(name.isEmpty || selectedIngredients.isEmpty)
                .padding()
                .background(.white)
            }
        }
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .ingredients:
                IngredientSelectionView(selectedIngredients: $selectedIngredients)
            case .imagePicker:
                ImagePicker(image: $image)
            }
        }
    }
    
    private func saveRecipe() {
        let recipe = Recipe(context: viewContext)
        recipe.name = name
        recipe.desc = description
        recipe.timeInMinutes = timeInMinutes
        recipe.servings = servings
        recipe.difficulty = difficulty.rawValue
        
        // Save image data
        if let image = image {
            recipe.imageData = image.jpegData(compressionQuality: 0.8)
        } else {
            // Create default image
            let defaultImage = UIImage(systemName: "fork.knife.circle.fill")?
                .withTintColor(.orange)
                .withRenderingMode(.alwaysOriginal)
            recipe.imageData = defaultImage?.jpegData(compressionQuality: 1.0)
        }
        
        // Save ingredients
        for selected in selectedIngredients {
            let recipeIngredient = RecipeIngredient(context: viewContext)
            recipeIngredient.recipe = recipe
            recipeIngredient.ingredient = selected.ingredient
            recipeIngredient.quantity = selected.quantity
            recipeIngredient.unit = selected.unit.rawValue
        }
        
        try? viewContext.save()
    }
}

struct SelectedIngredient: Identifiable {
    let id = UUID()
    let ingredient: Ingredient
    var quantity: Double
    var unit: UnitOfMeasure
}

enum AddRecipeSheet: Identifiable {
    case imagePicker
    case ingredients
    
    var id: Int {
        switch self {
        case .imagePicker: return 0
        case .ingredients: return 1
        }
    }
} 
