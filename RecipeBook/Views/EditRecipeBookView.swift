import SwiftUI
import CoreData

struct EditRecipeBookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    let recipeBook: NSManagedObject
    
    @State private var name: String
    
    init(recipeBook: NSManagedObject) {
        self.recipeBook = recipeBook
        _name = State(initialValue: recipeBook.value(forKey: "name") as? String ?? "")
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Recipe Book Name", text: $name)
                }
            }
            .navigationTitle("Edit Recipe Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRecipeBook()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
    
    private func saveRecipeBook() {
        recipeBook.setValue(name, forKey: "name")
        recipeBook.setValue(Date(), forKey: "updatedAt")
        
        try? viewContext.save()
        dismiss()
    }
}

#Preview {
    let context = PersistenceController.preview.container.viewContext
    let book = NSEntityDescription.insertNewObject(forEntityName: "RecipeBook", into: context) 
    book.setValue("Sample Book", forKey: "name")
    book.setValue(Date(), forKey: "createdAt")
    book.setValue(Date(), forKey: "updatedAt")
    
    return EditRecipeBookView(recipeBook: book)
        .environment(\.managedObjectContext, context)
} 
