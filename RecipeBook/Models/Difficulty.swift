import SwiftUI

enum Difficulty: String, CaseIterable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"
    
    var icon: String {
        switch self {
        case .easy: return "tortoise"
        case .medium: return "hare"
        case .hard: return "flame"
        }
    }
    
    var color: Color {
        switch self {
        case .easy: return .green
        case .medium: return .orange
        case .hard: return .red
        }
    }
} 
