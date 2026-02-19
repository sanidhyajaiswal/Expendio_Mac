import Foundation
import SwiftUI
import SwiftData

@Model
final class ExpenseCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    var colorHex: String
    var profileId: UUID
    
    @Relationship(deleteRule: .nullify, inverse: \Expense.category)
    var expenses: [Expense] = []
    
    init(name: String, icon: String, colorHex: String, profileId: UUID = UUID()) {
        self.id = UUID()
        self.name = name
        self.icon = icon
        self.colorHex = colorHex
        self.profileId = profileId
    }
    
    var color: Color {
        Color(hex: colorHex)
    }
    
    static let defaults: [(name: String, icon: String, color: String)] = [
        ("Food & Dining", "fork.knife", "#FF6B6B"),
        ("Transport", "car.fill", "#4ECDC4"),
        ("Shopping", "bag.fill", "#A78BFA"),
        ("Entertainment", "film.fill", "#F59E0B"),
        ("Utilities", "bolt.fill", "#3B82F6"),
        ("Health", "heart.fill", "#EC4899"),
        ("Rent & Housing", "house.fill", "#8B5CF6"),
        ("Education", "book.fill", "#10B981"),
        ("Travel", "airplane", "#F97316"),
        ("Subscriptions", "creditcard.fill", "#6366F1"),
        ("Groceries", "cart.fill", "#14B8A6"),
        ("Other", "ellipsis.circle.fill", "#6B7280"),
    ]
}
