import SwiftUI

struct StepsSection: View {
    let recipe: Recipe
    let steps: [Step]
    let completedSteps: Set<Int>
    let currentStepIndex: Int
    let onStepComplete: (Step, Bool) -> Void
    let onStepSelect: (Step) -> Void
    
    private func canCompleteStep(_ step: Step) -> Bool {
        if step.order == 0 {
            return true
        }
        return completedSteps.contains(Int(step.order - 1))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(steps) { step in
                StepTimelineView(
                    recipe: recipe,
                    step: step,
                    isCompleted: completedSteps.contains(Int(step.order)),
                    isActive: currentStepIndex == step.order,
                    isFirst: step.order == 0,
                    isLast: step.order == steps.count - 1,
                    onToggleComplete: { completed in
                        onStepComplete(step, completed)
                    },
                    canComplete: canCompleteStep(step)
                )
                .onTapGesture {
                    onStepSelect(step)
                }
            }
        }
        .padding()
        .backgroundStyle()
    }
} 