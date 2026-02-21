import Foundation
import SwiftData

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var title: String
    var amount: Double
    var date: Date
    var currency: String
    var notes: String
    var source: String // "manual" or "splitwise"
    var profileId: UUID
    
    var category: ExpenseCategory?
    
    init(
        title: String,
        amount: Double,
        date: Date,
        category: ExpenseCategory? = nil,
        currency: String = "INR",
        notes: String = "",
        source: String = "manual",
        profileId: UUID = UUID()
    ) {
        self.id = UUID()
        self.title = title
        self.amount = amount
        self.profileId = profileId
        self.date = date
        self.category = category
        self.currency = currency
        self.notes = notes
        self.source = source
    }
    
    var formattedAmount: String {
        let formatter = SharedFormatters.currencyFormatter(for: currency)
        return formatter.string(from: NSNumber(value: amount)) ?? "\(currency) \(amount)"
    }
    
    var monthKey: String {
        let formatter = SharedFormatters.dateFormatter(format: "yyyy-MM")
        return formatter.string(from: date)
    }
    
    var quarterKey: String {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: date)
        let month = calendar.component(.month, from: date)
        let quarter = (month - 1) / 3 + 1
        return "\(year)-Q\(quarter)"
    }
    
    var yearKey: String {
        let formatter = SharedFormatters.dateFormatter(format: "yyyy")
        return formatter.string(from: date)
    }
}
