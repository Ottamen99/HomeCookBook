import SwiftUI

struct StepsSection: View {
    let recipe: Recipe
    let completedSteps: Set<Int>
    let currentStepIndex: Int
    let onStepComplete: (Step, Bool) -> Void
    let onStepSelect: (Step) -> Void
    
    private var sortedSteps: [Step] {
        recipe.stepsArray.sorted { $0.order < $1.order }
    }
    
    var body: some View {
        Section {
            ForEach(sortedSteps, id: \.self) { step in
                let isCompleted = completedSteps.contains(Int(step.order))
                let isActive = Int(step.order) == currentStepIndex
                let canComplete = canCompleteStep(step)
                
                StepTimelineView(
                    recipe: recipe,
                    step: step,
                    isCompleted: isCompleted,
                    isActive: isActive,
                    isFirst: step.order == 0,
                    isLast: step.order == recipe.stepsArray.count - 1,
                    onToggleComplete: { completed in
                        onStepComplete(step, completed)
                    },
                    canComplete: canComplete
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    onStepSelect(step)
                }
            }
        } header: {
            HStack {
                Text("Steps")
                Spacer()
                Text("\(completedSteps.count)/\(recipe.stepsArray.count)")
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func canCompleteStep(_ step: Step) -> Bool {
        // Can complete if it's the first step
        if step.order == 0 { return true }
        
        // Can complete if previous step is completed
        return completedSteps.contains(Int(step.order - 1))
    }
} 