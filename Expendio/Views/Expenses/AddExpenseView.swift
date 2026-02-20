import SwiftUI
import SwiftData

struct AddExpenseView: View {
    let profileId: UUID
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var categories: [ExpenseCategory]
    @Environment(\.themeAccent) private var themeAccent
    
    @State private var title = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var selectedCategory: ExpenseCategory?
    @State private var currency = "INR"
    @State private var notes = ""
    @State private var isAnimating = false
    
    let currencies = ["INR", "USD", "EUR", "GBP", "JPY", "AUD", "CAD"]
    
    init(profileId: UUID) {
        self.profileId = profileId
        let pid = profileId
        _categories = Query(filter: #Predicate<ExpenseCategory> { $0.profileId == pid })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                Image(systemName: "plus.circle.fill").font(.system(size: 36)).foregroundColor(themeAccent)
                    .scaleEffect(isAnimating ? 1.0 : 0.8).animation(.spring(response: 0.5, dampingFraction: 0.6), value: isAnimating)
                Text("New Expense").font(.system(size: 20, weight: .bold)).foregroundColor(AppTheme.textPrimary)
            }.frame(maxWidth: .infinity).padding(.vertical, 24).background(themeAccent.opacity(0.08))
            
            ScrollView {
                VStack(spacing: 20) {
                    formField(label: "Title", icon: "textformat") { TextField("e.g. Grocery shopping", text: $title).textFieldStyle(.plain).font(.system(size: 14)).foregroundColor(AppTheme.textPrimary) }
                    HStack(spacing: 12) {
                        formField(label: "Amount", icon: "indianrupeesign") { TextField("0.00", text: $amount).textFieldStyle(.plain).font(.system(size: 14)).foregroundColor(AppTheme.textPrimary) }
                        formField(label: "Currency", icon: "dollarsign.circle") { Picker("", selection: $currency) { ForEach(currencies, id: \.self) { Text($0).tag($0) } }.labelsHidden().frame(maxWidth: .infinity, alignment: .leading) }.frame(width: 140)
                    }
                    formField(label: "Date", icon: "calendar") { DatePicker("", selection: $date, displayedComponents: .date).labelsHidden().datePickerStyle(.field) }
                    formField(label: "Category", icon: "tag") { Picker("", selection: $selectedCategory) { Text("Select category").tag(nil as ExpenseCategory?); ForEach(categories, id: \.id) { cat in Label(cat.name, systemImage: cat.icon).tag(cat as ExpenseCategory?) } }.labelsHidden().frame(maxWidth: .infinity, alignment: .leading) }
                    formField(label: "Notes", icon: "note.text") { TextField("Optional notes...", text: $notes, axis: .vertical).textFieldStyle(.plain).font(.system(size: 14)).foregroundColor(AppTheme.textPrimary).lineLimit(3) }
                }.padding(24)
            }
            
            Divider().overlay(AppTheme.border.opacity(0.3))
            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }.font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textSecondary).padding(.horizontal, 20).padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.dynamicSurfaceElevated)).buttonStyle(.plain)
                Spacer()
                Button { saveExpense() } label: { HStack(spacing: 6) { Image(systemName: "checkmark"); Text("Save Expense") }.gradientButton() }.buttonStyle(.plain).disabled(title.isEmpty || amount.isEmpty).opacity(title.isEmpty || amount.isEmpty ? 0.5 : 1.0)
            }.padding(20)
        }.frame(width: 500, height: 580).background(AppTheme.dynamicBackground).onAppear { isAnimating = true }
    }
    
    private func formField<Content: View>(label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) { Image(systemName: icon).font(.system(size: 12)).foregroundColor(themeAccent); Text(label).font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.textSecondary) }
            content().padding(.horizontal, 12).padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.dynamicSurfaceElevated).overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.dynamicBorder, lineWidth: 1)))
        }
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount) else { return }
        let expense = Expense(title: title, amount: amountValue, date: date, category: selectedCategory, currency: currency, notes: notes, source: "manual", profileId: profileId)
        modelContext.insert(expense); try? modelContext.save(); dismiss()
    }
}
