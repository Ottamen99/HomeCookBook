import SwiftUI

struct AddIngredientView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var viewModel: RecipeViewModel
    
    @State private var name = ""
    @State private var description = ""
    
    private var ingredientIcon: some View {
        VStack(spacing: 24) {
            // Icon circle
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 100, height: 100)
                .overlay {
                    Image(systemName: "leaf.fill")
                        .foregroundColor(.blue)
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ingredientIcon
                    
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
                    Text("New Ingredient")
                        .font(.headline)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        viewModel.addIngredient(
                            name: name,
                            description: description
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Button {
                    viewModel.addIngredient(
                        name: name,
                        description: description
                    )
                    dismiss()
                } label: {
                    Text("Create Ingredient")
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