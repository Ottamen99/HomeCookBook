import SwiftUI

enum IngredientFormMode {
    case add
    case edit(Ingredient)
}

struct IngredientFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let mode: IngredientFormMode
    
    @State private var name: String
    @State private var description: String
    @State private var showingDeleteErrorAlert = false
    
    init(mode: IngredientFormMode) {
        self.mode = mode
        
        switch mode {
        case .add:
            _name = State(initialValue: "")
            _description = State(initialValue: "")
        case .edit(let ingredient):
            _name = State(initialValue: ingredient.name ?? "")
            _description = State(initialValue: ingredient.desc ?? "")
        }
    }
    
    private var title: String {
        switch mode {
        case .add: return "New Ingredient"
        case .edit: return "Edit Ingredient"
        }
    }
    
    private var buttonTitle: String {
        switch mode {
        case .add: return "Create Ingredient"
        case .edit: return "Save Changes"
        }
    }
    
    var body: some View {
        NavigationStack {
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
                    
                    // Name input
                    TextField("Ingredient Name", text: $name)
                        .font(.title)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    // Description section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Description")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        TextField("Add a description", text: $description, axis: .vertical)
                            .lineLimit(3...6)
                            .textFieldStyle(.roundedBorder)
                    }
                    .padding()
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
                    Text(title)
                        .font(.headline)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button(action: {
                    save()
                    dismiss()
                }) {
                    Text(buttonTitle)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.black)
                        .cornerRadius(12)
                }
                .disabled(name.isEmpty)
                .padding()
                .background(.white)
            }
        }
    }
    
    private func save() {
        switch mode {
        case .add:
            let ingredient = Ingredient(context: viewContext)
            ingredient.name = name
            ingredient.desc = description
            
        case .edit(let ingredient):
            ingredient.name = name
            ingredient.desc = description
        }
        
        try? viewContext.save()
    }
} 