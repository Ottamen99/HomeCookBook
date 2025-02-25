import SwiftUI
import CoreData

struct AddRecipeBookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var description = ""
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Name")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("Recipe Book Name", text: $name)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextEditor(text: $description)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Recipe Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(Color.gray)
                            .cornerRadius(20)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveRecipeBook()
                    } label: {
                        Text("Add")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(name.isEmpty ? Color.gray : Color.orange)
                            .cornerRadius(20)
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveRecipeBook() {
        let entity = NSEntityDescription.entity(forEntityName: "RecipeBook", in: viewContext)!
        let recipeBook = NSManagedObject(entity: entity, insertInto: viewContext)
        
        recipeBook.setValue(UUID(), forKey: "id")
        recipeBook.setValue(name, forKey: "name")
        recipeBook.setValue(description, forKey: "desc")
        let now = Date()
        recipeBook.setValue(now, forKey: "createdAt")
        recipeBook.setValue(now, forKey: "updatedAt")
        
        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    AddRecipeBookView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 