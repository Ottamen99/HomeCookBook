import SwiftUI

struct DifficultyPill: View {
    let difficulty: Difficulty
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: difficulty.icon)
                .font(.caption)
            Text(difficulty.rawValue.capitalized)
                .font(.subheadline)
                .lineLimit(1)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(difficulty.color)
        .clipShape(Capsule())
    }
} 