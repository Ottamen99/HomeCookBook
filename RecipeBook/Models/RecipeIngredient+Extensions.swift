import CoreData

extension RecipeIngredient {
    // Store original quantity as a temporary computed property
    @objc var originalQuantity: Double {
        get {
            // If we haven't stored an original quantity, return the current quantity
            if let stored = self.value(forKey: "originalQuantity") as? Double {
                return stored
            }
            return self.quantity
        }
        set {
            self.setValue(newValue, forKey: "originalQuantity")
        }
    }
} 