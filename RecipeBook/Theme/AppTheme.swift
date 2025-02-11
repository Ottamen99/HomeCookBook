import SwiftUI

enum AppTheme {
    static let backgroundColor = Color(UIColor.systemBackground)
    static let secondaryBackground = Color(.systemGray6)
    static let accentColor = Color.green
    static let textColor = Color(.label)
    static let secondaryTextColor = Color(.secondaryLabel)
    
    static let cardBackground = Color(red: 28/255, green: 28/255, blue: 30/255)
    static let cardCornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 12
    
    struct CardStyle: ViewModifier {
        func body(content: Content) -> some View {
            content
                .padding(AppTheme.cardPadding)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.cardCornerRadius)
        }
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(AppTheme.CardStyle())
    }
} 