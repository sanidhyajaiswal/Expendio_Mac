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
            // Header
            HStack {
                Text("New Expense")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                DialogCloseButton(action: { dismiss() })
            }
            .padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 20) {
                    formField(label: "Title", icon: "textformat") { 
                        TextField("e.g. Grocery shopping", text: $title)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    
                    HStack(spacing: 12) {
                        formField(label: "Amount", icon: "indianrupeesign") { 
                            TextField("0.00", text: $amount)
                                .textFieldStyle(.plain)
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        
                        formField(label: "Currency", icon: "dollarsign.circle", hasBackground: false) { 
                            Menu {
                                ForEach(currencies, id: \.self) { c in Button(c) { currency = c } }
                            } label: {
                                HStack {
                                    Text(currency)
                                        .font(.system(size: 15))
                                        .foregroundColor(AppTheme.textPrimary)
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(AppTheme.textMuted)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.dynamicSurfaceElevated))
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(width: 140)
                    }
                    
                    HStack(spacing: 12) {
                        formField(label: "Category", icon: "tag", hasBackground: false) { 
                            Menu {
                                Button("Select category") { selectedCategory = nil }
                                ForEach(categories, id: \.id) { cat in 
                                    Button { selectedCategory = cat } label: { Label(cat.name, systemImage: cat.icon) }
                                }
                            } label: {
                                HStack {
                                    if let cat = selectedCategory {
                                        Text(cat.name)
                                            .font(.system(size: 15))
                                            .foregroundColor(AppTheme.textPrimary)
                                    } else {
                                        Text("Select category")
                                            .font(.system(size: 15))
                                            .foregroundColor(AppTheme.textMuted)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.up.chevron.down")
                                        .font(.system(size: 10))
                                        .foregroundColor(AppTheme.textMuted)
                                }
                                .padding(.horizontal, 12).padding(.vertical, 10)
                                .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.dynamicSurfaceElevated))
                            }
                            .buttonStyle(.plain)
                        }
                        
                        formField(label: "Date", icon: "calendar") { 
                            DatePicker("", selection: $date, displayedComponents: .date)
                                .labelsHidden()
                                .datePickerStyle(.compact)
                                .environment(\.colorScheme, .dark)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    
                    formField(label: "Notes", icon: "note.text") { 
                        TextField("Optional notes...", text: $notes, axis: .vertical)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.textPrimary)
                            .lineLimit(3)
                    }
                }
                .padding(.horizontal, 24).padding(.bottom, 24)
            }
            
            // Buttons
            HStack(spacing: 12) {
                Button { dismiss() } label: {
                    Text("Cancel")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.danger)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.dynamicSurfaceElevated))
                }.buttonStyle(.plain)

                Button { saveExpense() } label: {
                    Text("Save Expense")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(themeAccent))
                }
                .buttonStyle(.plain)
                .disabled(title.isEmpty || amount.isEmpty)
                .opacity(title.isEmpty || amount.isEmpty ? 0.5 : 1.0)
            }
            .padding(24)
        }
        .frame(width: 440, height: 500)
        .background(AppTheme.dynamicBackground)
        .onAppear { isAnimating = true }
    }
    
    private func formField<Content: View>(label: String, icon: String, hasBackground: Bool = true, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) { 
                Image(systemName: icon).font(.system(size: 12)).foregroundColor(themeAccent)
                Text(label).font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.textSecondary) 
            }
            if hasBackground {
                content()
                    .padding(.horizontal, 12).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.dynamicSurfaceElevated))
            } else {
                content()
            }
        }
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount) else { return }
        let expense = Expense(title: title, amount: amountValue, date: date, category: selectedCategory, currency: currency, notes: notes, source: "manual", profileId: profileId)
        modelContext.insert(expense); try? modelContext.save(); dismiss()
    }
}
