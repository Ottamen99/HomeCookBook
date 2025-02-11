import Foundation

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