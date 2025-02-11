import SwiftUI

enum StepSheet: Identifiable {
    case add
    case edit(RecipeStep)
    
    var id: String {
        switch self {
        case .add:
            return "add"
        case .edit(let step):
            return "edit-\(step.id)"
        }
    }
}

struct StepsSection: View {
    @Binding var steps: [RecipeStep]
    let recipeIngredients: [SelectedIngredient]
    @State private var activeSheet: StepSheet?
    
    var body: some View {
        Section("Steps") {
            ForEach($steps) { $step in
                StepRowView(step: $step, recipeIngredients: recipeIngredients) {
                    activeSheet = .edit(step)
                }
            }
            .onMove { from, to in
                steps.move(fromOffsets: from, toOffset: to)
                updateStepOrder()
            }
            .onDelete { indexSet in
                steps.remove(atOffsets: indexSet)
                updateStepOrder()
            }
            
            Button {
                activeSheet = .add
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Add Step")
                }
            }
        }
        .sheet(item: $activeSheet) { sheet in
            NavigationView {
                switch sheet {
                case .add:
                    StepFormView(
                        step: nil,
                        recipeIngredients: recipeIngredients
                    ) { newStep in
                        steps.append(newStep)
                        updateStepOrder()
                        activeSheet = nil
                    }
                case .edit(let step):
                    StepFormView(
                        step: step,
                        recipeIngredients: recipeIngredients
                    ) { newStep in
                        if let index = steps.firstIndex(where: { $0.id == step.id }) {
                            steps[index] = newStep
                        }
                        updateStepOrder()
                        activeSheet = nil
                    }
                }
            }
        }
    }
    
    private func updateStepOrder() {
        for (index, step) in steps.enumerated() {
            steps[index].order = Int16(index)
        }
    }
} 