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
    
    private var ingredientIcon: some View {
        VStack(spacing: 24) {
            // Icon circle
            Circle()
                .fill(Color.orange.opacity(0.1))
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 40))
                }
                .padding(.top, 40)
            
            // Name input
            TextField("Ingredient Name", text: $name)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
        }
    }
    
    private var buttonTitle: String {
        switch mode {
        case .add: return "Create Ingredient"
        case .edit: return "Save Changes"
        }
    }
    
    private var toolbarButtons: some View {
        HStack {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
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
        NavigationStack {
            ZStack(alignment: .top) {
                ScrollView {
                    VStack(spacing: 24) {
                        ingredientIcon
                        
                        // Description section
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Description")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            TextEditor(text: $description)
                                .frame(minHeight: 100, maxHeight: 200)
                                .scrollContentBackground(.hidden)
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                        .padding()
                    }
                }
                .navigationBarHidden(true)
                
                VStack {
                    toolbarButtons
                        .padding(.top, 8)
                    
                    Spacer()
                    
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
