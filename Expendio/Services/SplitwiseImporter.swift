import Foundation
import SwiftData

struct ParsedExpense {
    let date: Date
    let description: String
    let category: String
    let cost: Double
    let currency: String
}

class SplitwiseImporter {
    
    enum ImportError: LocalizedError {
        case fileNotFound
        case invalidFormat
        case noData
        case parsingFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound: return "CSV file not found."
            case .invalidFormat: return "Invalid CSV format. Expected Splitwise export columns."
            case .noData: return "No expense data found in the file."
            case .parsingFailed(let detail): return "Parsing failed: \(detail)"
            }
        }
    }
    
    // MARK: - Parse CSV
    static func parseCSV(at url: URL) throws -> [ParsedExpense] {
        let content: String
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw ImportError.fileNotFound
        }
        
        let lines = content.components(separatedBy: .newlines)
            .filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        
        guard lines.count > 1 else { throw ImportError.noData }
        
        // Parse header
        let header = parseCSVLine(lines[0]).map { $0.lowercased().trimmingCharacters(in: .whitespaces) }
        
        guard let dateIndex = header.firstIndex(of: "date"),
              let descIndex = header.firstIndex(of: "description"),
              let costIndex = header.firstIndex(of: "cost") else {
            throw ImportError.invalidFormat
        }
        
        let categoryIndex = header.firstIndex(of: "category")
        let currencyIndex = header.firstIndex(of: "currency")
        
        // Parse data rows
        var expenses: [ParsedExpense] = []
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        let dateFormats = ["yyyy-MM-dd", "yyyy/MM/dd", "MM/dd/yyyy", "dd/MM/yyyy"]
        
        for i in 1..<lines.count {
            let fields = parseCSVLine(lines[i])
            
            guard fields.count > max(dateIndex, descIndex, costIndex) else { continue }
            
            let dateString = fields[dateIndex].trimmingCharacters(in: .whitespaces)
            let description = fields[descIndex].trimmingCharacters(in: .whitespaces)
            let costString = fields[costIndex].trimmingCharacters(in: .whitespaces)
            
            // Skip total/balance rows
            if description.lowercased().contains("total balance") ||
               description.lowercased().contains("settle all") {
                continue
            }
            
            // Parse date
            var parsedDate: Date?
            for format in dateFormats {
                dateFormatter.dateFormat = format
                if let date = dateFormatter.date(from: dateString) {
                    parsedDate = date
                    break
                }
            }
            guard let date = parsedDate else { continue }
            
            // Parse cost
            let cleanCost = costString.replacingOccurrences(of: ",", with: "")
            guard let cost = Double(cleanCost), cost > 0 else { continue }
            
            // Category
            let category: String
            if let catIdx = categoryIndex, fields.count > catIdx {
                category = fields[catIdx].trimmingCharacters(in: .whitespaces)
            } else {
                category = "Other"
            }
            
            // Currency
            let currency: String
            if let curIdx = currencyIndex, fields.count > curIdx {
                currency = fields[curIdx].trimmingCharacters(in: .whitespaces)
            } else {
                currency = "INR"
            }
            
            expenses.append(ParsedExpense(
                date: date,
                description: description,
                category: category,
                cost: cost,
                currency: currency
            ))
        }
        
        guard !expenses.isEmpty else { throw ImportError.noData }
        return expenses
    }
    
    // MARK: - Import into SwiftData
    static func importExpenses(
        _ parsed: [ParsedExpense],
        into context: ModelContext,
        categories: [ExpenseCategory],
        profileId: UUID
    ) -> Int {
        var imported = 0
        
        for item in parsed {
            // Find matching category
            let matchedCategory = categories.first { cat in
                cat.name.lowercased().contains(item.category.lowercased()) ||
                item.category.lowercased().contains(cat.name.lowercased())
            } ?? categories.first { $0.name == "Other" }
            
            // Check for duplicates
            let itemTitle = item.description
            let itemCost = item.cost
            let descriptor = FetchDescriptor<Expense>(
                predicate: #Predicate<Expense> { expense in
                    expense.title == itemTitle &&
                    expense.amount == itemCost &&
                    expense.source == "splitwise"
                }
            )
            
            if let existing = try? context.fetch(descriptor), !existing.isEmpty {
                // Check if any have the same date
                let hasSameDate = existing.contains { Calendar.current.isDate($0.date, inSameDayAs: item.date) }
                if hasSameDate { continue }
            }
            
            let expense = Expense(
                title: item.description,
                amount: item.cost,
                date: item.date,
                category: matchedCategory,
                currency: item.currency,
                source: "splitwise",
                profileId: profileId
            )
            
            context.insert(expense)
            imported += 1
        }
        
        try? context.save()
        return imported
    }
    
    // MARK: - CSV Line Parser (handles quoted fields)
    private static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        
        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current)
        
        return fields
    }
    
    // MARK: - Category Mapping
    static let splitwiseCategoryMap: [String: String] = [
        "food and drink": "Food & Dining",
        "dining out": "Food & Dining",
        "groceries": "Groceries",
        "transportation": "Transport",
        "taxi": "Transport",
        "parking": "Transport",
        "entertainment": "Entertainment",
        "movies": "Entertainment",
        "music": "Entertainment",
        "games": "Entertainment",
        "utilities": "Utilities",
        "electricity": "Utilities",
        "water": "Utilities",
        "internet": "Utilities",
        "phone": "Utilities",
        "rent": "Rent & Housing",
        "mortgage": "Rent & Housing",
        "household supplies": "Shopping",
        "clothing": "Shopping",
        "general": "Other",
        "other": "Other",
        "life": "Other",
        "liquor": "Food & Dining",
        "sports": "Entertainment",
        "medical expenses": "Health",
        "education": "Education",
        "books": "Education",
        "travel": "Travel",
        "hotel": "Travel",
        "plane": "Travel",
        "bus/train": "Transport",
        "gas/fuel": "Transport",
        "cleaning": "Rent & Housing",
        "maintenance": "Rent & Housing",
        "pets": "Other",
        "gifts": "Shopping",
        "insurance": "Utilities",
    ]
}
