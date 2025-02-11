import Foundation
import CoreData

extension Recipe {
    var recipeIngredientsArray: [RecipeIngredient] {
        let set = recipeIngredients as? Set<RecipeIngredient> ?? []
        return Array(set).sorted { ($0.ingredient?.name ?? "") < ($1.ingredient?.name ?? "") }
    }
    
    var stepsArray: [Step] {
        let set = steps as? Set<Step> ?? []
        return Array(set).sorted { 
            if $0.order == $1.order {
                return ($0.createdAt ?? Date()) < ($1.createdAt ?? Date())
            }
            return $0.order < $1.order
        }
    }
} 