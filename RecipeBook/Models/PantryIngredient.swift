import Foundation
import CoreData

@objc(PantryIngredient)
public class PantryIngredient: NSManagedObject, Identifiable {
    @NSManaged public var id: UUID
    @NSManaged public var quantity: Double
    @NSManaged public var unit: String?
    @NSManaged public var ingredient: Ingredient?
    @NSManaged public var dateAdded: Date
    
    public override func awakeFromInsert() {
        super.awakeFromInsert()
        id = UUID()
        dateAdded = Date()
    }
}

extension PantryIngredient {
    static var defaultFetchRequest: NSFetchRequest<PantryIngredient> {
        let request = NSFetchRequest<PantryIngredient>(entityName: "PantryIngredient")
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \PantryIngredient.dateAdded, ascending: false)
        ]
        return request
    }
} 