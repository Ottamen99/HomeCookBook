import Foundation

enum UnitOfMeasure: String, CaseIterable {
    case grams = "g"
    case kilograms = "kg"
    case milliliters = "ml"
    case liters = "L"
    case pieces = "pcs"
    case tablespoons = "tbsp"
    case teaspoons = "tsp"
    case cups = "cups"
    
    var displayName: String {
        switch self {
        case .grams: return "Grams"
        case .kilograms: return "Kilograms"
        case .milliliters: return "Milliliters"
        case .liters: return "Liters"
        case .pieces: return "Pieces"
        case .tablespoons: return "Tablespoons"
        case .teaspoons: return "Teaspoons"
        case .cups: return "Cups"
        }
    }
} 