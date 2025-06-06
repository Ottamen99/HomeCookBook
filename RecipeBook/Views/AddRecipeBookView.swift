import SwiftUI
import CoreData

struct AddRecipeBookView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var name = ""
    @State private var description = ""
    @State private var isNameFieldFocused = false
    @State private var isDescriptionFieldFocused = false
    @FocusState private var focusedField: Field?
    
    // For keyboard handling
    @FocusState private var isInputActive: Bool
    
    // Character limit for description
    private let descriptionLimit = 200
    
    // Adaptive spacing based on dynamic type size
    private var verticalSpacing: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small, .medium:
            return 24
        case .large, .xLarge:
            return 28
        default:
            return 32
        }
    }
    
    // Computed property to check if form is valid
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // Enum for focus management
    enum Field: Hashable {
        case name, description
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: verticalSpacing) {
                    nameSection
                    descriptionSection
                }
                .padding(.horizontal, horizontalSizeClass == .compact ? 16 : 24)
                .padding(.vertical, 20)
            }
            .scrollDismissesKeyboard(.interactively)
            .scrollIndicators(.visible)
            .background(Color(.systemGroupedBackground))
            .navigationTitle("New Recipe Book")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    cancelButton
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    addButton
                }
                
                ToolbarItem(placement: .keyboard) {
                    keyboardToolbar
                }
            }
            .onSubmit {
                switch focusedField {
                case .name:
                    focusedField = .description
                case .description:
                    if isFormValid {
                        saveRecipeBook()
                    }
                case .none:
                    break
                }
            }
        }
    }
    
    // MARK: - Component Views
    
    private var nameSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Name")
                .font(.headline)
                .foregroundColor(.secondary)
                .accessibilityAddTraits(.isHeader)
            
            TextField("Recipe Book Name", text: $name)
                .font(.body)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isNameFieldFocused ? Color.orange : Color.clear, lineWidth: 2)
                )
                .focused($focusedField, equals: .name)
                .onChange(of: focusedField) { 
                    isNameFieldFocused = (focusedField == .name)
                }
                .submitLabel(.next)
                .accessibilityLabel("Recipe book name")
                .accessibilityHint("Enter a name for your recipe book")
        }
    }
    
    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Description")
                .font(.headline)
                .foregroundColor(.secondary)
                .accessibilityAddTraits(.isHeader)
            
            descriptionEditor
            
            Text("Optional - Describe what this collection is about")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 4)
        }
    }
    
    private var descriptionEditor: some View {
        ZStack(alignment: .bottomTrailing) {
            TextEditor(text: $description)
                .font(.body)
                .padding(8)
                .frame(minHeight: 120)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isDescriptionFieldFocused ? Color.orange : Color.clear, lineWidth: 2)
                )
                .focused($focusedField, equals: .description)
                .onChange(of: focusedField) { 
                    isDescriptionFieldFocused = (focusedField == .description)
                }
                .onChange(of: description) { 
                    if description.count > descriptionLimit {
                        description = String(description.prefix(descriptionLimit))
                    }
                }
                .accessibilityLabel("Recipe book description")
                .accessibilityHint("Enter an optional description for your recipe book")
            
            // Character counter
            characterCounter
        }
    }
    
    private var characterCounter: some View {
        Text("\(description.count)/\(descriptionLimit)")
            .font(.caption)
            .foregroundColor(description.count > descriptionLimit * Int(0.8) ? .orange : .secondary)
            .padding(8)
            .accessibilityLabel("Character count: \(description.count) of \(descriptionLimit) maximum")
    }
    
    private var cancelButton: some View {
        Button {
            dismiss()
        } label: {
            Text("Cancel")
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color(.systemGray5))
                )
                .contentShape(Capsule())
        }
        .buttonStyle(ButtonScaleEffect())
        .accessibilityLabel("Cancel creating recipe book")
    }
    
    private var addButton: some View {
        Button {
            saveRecipeBook()
        } label: {
            Text("Add")
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(isFormValid ? Color.orange : Color.gray)
                )
                .contentShape(Capsule())
        }
        .disabled(!isFormValid)
        .buttonStyle(ButtonScaleEffect())
        .accessibilityLabel("Add recipe book")
        .accessibilityHint(isFormValid ? "Creates a new recipe book with the entered information" : "Enter a name to enable this button")
    }
    
    private var keyboardToolbar: some View {
        HStack {
            Spacer()
            
            Button("Done") {
                isInputActive = false
                focusedField = nil
            }
            .font(.headline)
            .foregroundColor(.orange)
            .frame(height: 44)
            .contentShape(Rectangle())
        }
    }
    
    // MARK: - Helper Functions
    
    private func saveRecipeBook() {
        let entity = NSEntityDescription.entity(forEntityName: "RecipeBook", in: viewContext)!
        let recipeBook = NSManagedObject(entity: entity, insertInto: viewContext)
        
        recipeBook.setValue(UUID(), forKey: "id")
        recipeBook.setValue(name.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "name")
        recipeBook.setValue(description.trimmingCharacters(in: .whitespacesAndNewlines), forKey: "desc")
        let now = Date()
        recipeBook.setValue(now, forKey: "createdAt")
        recipeBook.setValue(now, forKey: "updatedAt")
        
        do {
            try viewContext.save()
            dismiss()
        } catch {
            // Handle error
            print("Error saving recipe book: \(error)")
        }
    }
}

// Use a different name to avoid conflict with existing button styles
struct ButtonScaleEffect: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

// MARK: - Preview
struct AddRecipeBookView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Standard preview
            NavigationStack {
                AddRecipeBookView()
                    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            }
            .previewDisplayName("Light Mode")
            
            // Dark mode preview
            NavigationStack {
                AddRecipeBookView()
                    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            }
            .preferredColorScheme(.dark)
            .previewDisplayName("Dark Mode")
            
            // Accessibility preview with larger text
            NavigationStack {
                AddRecipeBookView()
                    .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            }
            .environment(\.dynamicTypeSize, .xxxLarge)
            .previewDisplayName("Large Text")
        }
    }
} 
