import SwiftUI
import CoreData

struct AddRecipeBookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Recipe Book Name", text: $name)
                }
            }
            .navigationTitle("New Recipe Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        saveRecipeBook()
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