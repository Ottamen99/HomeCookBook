import SwiftUI
import CoreData

struct EditRecipeBookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let recipeBook: NSManagedObject
    
    @State private var name: String
    @State private var description: String
    
    init(recipeBook: NSManagedObject) {
        self.recipeBook = recipeBook
        _name = State(initialValue: recipeBook.value(forKey: "name") as? String ?? "")
        _description = State(initialValue: recipeBook.value(forKey: "desc") as? String ?? "")
    }
    
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
            .navigationTitle("Edit Recipe Book")
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
                        Text("Save")
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
        recipeBook.setValue(name, forKey: "name")
        recipeBook.setValue(description, forKey: "desc")
        recipeBook.setValue(Date(), forKey: "updatedAt")
        
        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let book = NSEntityDescription.insertNewObject(forEntityName: "RecipeBook", into: context) 
    book.setValue("Sample Book", forKey: "name")
    book.setValue("A collection of favorite recipes", forKey: "desc")
    book.setValue(Date(), forKey: "createdAt")
    book.setValue(Date(), forKey: "updatedAt")
    
    return EditRecipeBookView(recipeBook: book)
        .environment(\.managedObjectContext, context)
} 
