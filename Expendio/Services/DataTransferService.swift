import Foundation
import SwiftData

struct AppDataExport: Codable {
    let profiles: [ProfileExport]
    let categories: [CategoryExport]
    let expenses: [ExpenseExport]
}

struct ProfileExport: Codable {
    let id: UUID
    let name: String
    let colorHex: String
}

struct CategoryExport: Codable {
    let id: UUID
    let name: String
    let icon: String
    let colorHex: String
    let profileId: UUID
}

struct ExpenseExport: Codable {
    let id: UUID
    let title: String
    let amount: Double
    let date: Date
    let currency: String
    let notes: String
    let source: String
    let profileId: UUID
    let categoryId: UUID?
}

@MainActor
final class DataTransferService {
    static let shared = DataTransferService()
    
    private init() {}
    
    func exportData(from context: ModelContext) throws -> Data {
        let profiles = try context.fetch(FetchDescriptor<Profile>())
        let categories = try context.fetch(FetchDescriptor<ExpenseCategory>())
        let expenses = try context.fetch(FetchDescriptor<Expense>())
        
        let profileExports = profiles.map { ProfileExport(id: $0.id, name: $0.name, colorHex: $0.colorHex) }
        let categoryExports = categories.map { CategoryExport(id: $0.id, name: $0.name, icon: $0.icon, colorHex: $0.colorHex, profileId: $0.profileId) }
        let expenseExports = expenses.map { expense in
            ExpenseExport(
                id: expense.id,
                title: expense.title,
                amount: expense.amount,
                date: expense.date,
                currency: expense.currency,
                notes: expense.notes,
                source: expense.source,
                profileId: expense.profileId,
                categoryId: expense.category?.id
            )
        }
        
        let exportData = AppDataExport(profiles: profileExports, categories: categoryExports, expenses: expenseExports)
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        encoder.dateEncodingStrategy = .iso8601
        
        return try encoder.encode(exportData)
    }
    
    func importData(from data: Data, into context: ModelContext) throws {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let importData = try decoder.decode(AppDataExport.self, from: data)
        
        // 1. Delete all existing data
        let existingProfiles = try context.fetch(FetchDescriptor<Profile>())
        for profile in existingProfiles {
            context.delete(profile)
        }
        
        let existingCategories = try context.fetch(FetchDescriptor<ExpenseCategory>())
        for category in existingCategories {
            context.delete(category)
        }
        
        let existingExpenses = try context.fetch(FetchDescriptor<Expense>())
        for expense in existingExpenses {
            context.delete(expense)
        }
        
        // Ensure deletions are saved before inserting new ones with matching constraints (like UUIDs)
        try context.save()
        
        // 2. Insert Imported Data
        var categoryMap: [UUID: ExpenseCategory] = [:]
        
        for profileDTO in importData.profiles {
            let profile = Profile(name: profileDTO.name, colorHex: profileDTO.colorHex)
            profile.id = profileDTO.id
            context.insert(profile)
        }
        
        for categoryDTO in importData.categories {
            let category = ExpenseCategory(name: categoryDTO.name, icon: categoryDTO.icon, colorHex: categoryDTO.colorHex, profileId: categoryDTO.profileId)
            category.id = categoryDTO.id
            categoryMap[category.id] = category
            context.insert(category)
        }
        
        for expenseDTO in importData.expenses {
            let category = expenseDTO.categoryId.flatMap { categoryMap[$0] }
            let expense = Expense(
                title: expenseDTO.title,
                amount: expenseDTO.amount,
                date: expenseDTO.date,
                category: category,
                currency: expenseDTO.currency,
                notes: expenseDTO.notes,
                source: expenseDTO.source,
                profileId: expenseDTO.profileId
            )
            expense.id = expenseDTO.id
            context.insert(expense)
        }
        
        try context.save()
    }
}
