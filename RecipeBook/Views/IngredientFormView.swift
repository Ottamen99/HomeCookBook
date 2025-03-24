import SwiftUI

enum IngredientFormMode {
    case add
    case edit(Ingredient)
}

struct IngredientFormView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    let mode: IngredientFormMode
    
    @State private var name: String
    @State private var description: String
    @State private var hasChanges: Bool = false
    @State private var showUnsavedChangesAlert = false
    @FocusState private var focusedField: Field?
    
    enum Field: Hashable {
        case name
        case description
    }
    
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
    
    private var formTitle: String {
        switch mode {
        case .add: return "New Ingredient"
        case .edit: return "Edit Ingredient"
        }
    }
    
    private var iconBackground: Color {
        let opacity = colorScheme == .dark ? 0.2 : 0.1
        return Color.orange.opacity(opacity)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                iconAndNameSection
                
                descriptionSection
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(formTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelButton
                saveButton
                keyboardToolbar
            }
            .alert("Unsaved Changes", isPresented: $showUnsavedChangesAlert) {
                Button("Discard Changes", role: .destructive) {
                    dismiss()
                }
                Button("Keep Editing", role: .cancel) {}
            } message: {
                Text("You have unsaved changes. Are you sure you want to discard them?")
            }
            .onAppear {
                if case .add = mode {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        focusedField = .name
                    }
                }
            }
        }
    }
    
    private var iconAndNameSection: some View {
        Section {
            VStack(spacing: 24) {
                ingredientIcon
                
                nameInput
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets(top: 16, leading: 0, bottom: 16, trailing: 0))
        }
    }
    
    private var ingredientIcon: some View {
        Circle()
            .fill(iconBackground)
            .frame(width: 110, height: 110)
            .overlay {
                Image(systemName: "leaf.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 42, weight: .medium))
                    .symbolEffect(.pulse, options: .repeat(3), value: focusedField == .name)
            }
            .shadow(color: Color.orange.opacity(0.2), radius: 10, x: 0, y: 5)
            .accessibilityHidden(true)
            .padding(.top, 8)
    }
    
    private var nameInput: some View {
        VStack(spacing: 8) {
            TextField("Ingredient Name", text: $name)
                .font(.title2.weight(.medium))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 4)
                .focused($focusedField, equals: .name)
                .submitLabel(.next)
                .onChange(of: name) { _ in 
                    hasChanges = true
                }
                .onSubmit {
                    focusedField = .description
                }
            
            if name.isEmpty {
                Text("Required")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var descriptionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                descriptionHeader
                
                descriptionEditor
            }
            .padding(.vertical, 8)
        }
        .headerProminence(.increased)
    }
    
    private var descriptionHeader: some View {
        HStack {
            Text("Tell us about this ingredient")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(description.count) characters")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
    }
    
    private var descriptionEditor: some View {
        TextEditor(text: $description)
            .frame(minHeight: 120)
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.systemGray6))
            )
            .focused($focusedField, equals: .description)
            .submitLabel(.done)
            .onChange(of: description) { _ in 
                hasChanges = true
            }
            .accessibilityLabel("Ingredient description")
    }
    
    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                if hasChanges {
                    showUnsavedChangesAlert = true
                } else {
                    dismiss()
                }
            }
        }
    }
    
    private var saveButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button {
                withAnimation {
                    save()
                }
            } label: {
                Text("Save")
                    .fontWeight(.semibold)
            }
            .disabled(name.isEmpty)
        }
    }
    
    private var keyboardToolbar: some ToolbarContent {
        ToolbarItem(placement: .keyboard) {
            HStack {
                Button {
                    if focusedField == .description {
                        focusedField = .name
                    } else {
                        focusedField = .description
                    }
                } label: {
                    Image(systemName: focusedField == .name ? "arrow.down" : "arrow.up")
                }
                
                Spacer()
                
                Button("Done") {
                    focusedField = nil
                }
                .fontWeight(.semibold)
            }
            .padding(.horizontal, 8)
        }
    }
    
    private func save() {
        let generator = UINotificationFeedbackGenerator()
        
        if name.isEmpty {
            generator.notificationOccurred(.error)
            return
        }
        
        switch mode {
        case .add:
            let ingredient = Ingredient(context: viewContext)
            ingredient.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            ingredient.desc = description.trimmingCharacters(in: .whitespacesAndNewlines)
            
        case .edit(let ingredient):
            ingredient.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            ingredient.desc = description.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        do {
            try viewContext.save()
            generator.notificationOccurred(.success)
            dismiss()
        } catch {
            generator.notificationOccurred(.error)
            print("Error saving ingredient: \(error.localizedDescription)")
        }
    }
}

struct BackgroundDismissKeyboard: UIViewRepresentable {
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        let tapGesture = UITapGestureRecognizer(target: context.coordinator,
                                               action: #selector(Coordinator.handleTap))
        view.addGestureRecognizer(tapGesture)
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject {
        @objc func handleTap() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                         to: nil,
                                         from: nil,
                                         for: nil)
        }
    }
}

// MARK: - Previews
struct IngredientFormView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Preview for Add mode - Light theme
            IngredientFormView(mode: .add)
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .previewDisplayName("Add Ingredient - Light")
            
            // Preview for Edit mode - Light theme
            IngredientFormView(mode: .edit(createSampleIngredient()))
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .previewDisplayName("Edit Ingredient - Light")
            
            // Preview for Add mode - Dark theme
            IngredientFormView(mode: .add)
                .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
                .preferredColorScheme(.dark)
                .previewDisplayName("Add Ingredient - Dark")
        }
    }
    
    // Helper method to create a sample ingredient for the edit mode preview
    static func createSampleIngredient() -> Ingredient {
        let context = PersistenceController.preview.container.viewContext
        let ingredient = Ingredient(context: context)
        ingredient.name = "Flour"
        ingredient.desc = "All-purpose flour is a versatile ingredient used in baking. It's made from wheat and has a moderate protein content, making it suitable for cakes, cookies, bread, and more."
        return ingredient
    }
} 
