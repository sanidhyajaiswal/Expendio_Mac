import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var categories: [ExpenseCategory]
    
    @State private var searchText = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var showAddSheet = false
    @State private var editingExpenseId: UUID?
    @State private var hoveredExpenseId: UUID?
    
    // Editing state
    @State private var editTitle = ""
    @State private var editAmount = ""
    @State private var editDate = Date()
    @State private var editCategory: ExpenseCategory?
    @State private var editNotes = ""
    
    private var filteredExpenses: [Expense] {
        expenses.filter { expense in
            let matchesSearch = searchText.isEmpty ||
                expense.title.localizedCaseInsensitiveContains(searchText) ||
                expense.notes.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil ||
                expense.category?.id == selectedCategory?.id
            
            return matchesSearch && matchesCategory
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerBar
            
            // Filter Bar
            filterBar
            
            // Table
            if filteredExpenses.isEmpty {
                emptyState
            } else {
                expenseTable
            }
        }
        .background(AppTheme.background)
        .sheet(isPresented: $showAddSheet) {
            AddExpenseView()
        }
    }
    
    // MARK: - Header
    private var headerBar: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Expenses")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("\(filteredExpenses.count) expense\(filteredExpenses.count == 1 ? "" : "s")")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
            }
            
            Spacer()
            
            Button {
                showAddSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Add Expense")
                }
                .gradientButton()
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 32)
        .padding(.top, 28)
        .padding(.bottom, 16)
    }
    
    // MARK: - Filter Bar
    private var filterBar: some View {
        HStack(spacing: 12) {
            // Search
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(AppTheme.textMuted)
                
                TextField("Search expenses...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textPrimary)
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppTheme.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.surfaceElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(AppTheme.border.opacity(0.5), lineWidth: 1)
                    )
            )
            .frame(maxWidth: 300)
            
            // Category Filter
            Menu {
                Button("All Categories") {
                    selectedCategory = nil
                }
                Divider()
                ForEach(categories, id: \.id) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Label(category.name, systemImage: category.icon)
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                    Text(selectedCategory?.name ?? "All Categories")
                        .lineLimit(1)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10))
                }
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(AppTheme.surfaceElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(AppTheme.border.opacity(0.5), lineWidth: 1)
                        )
                )
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 16)
    }
    
    // MARK: - Expense Table
    private var expenseTable: some View {
        VStack(spacing: 0) {
            // Table Header
            HStack(spacing: 0) {
                Text("DATE")
                    .frame(width: 110, alignment: .leading)
                Text("TITLE")
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text("CATEGORY")
                    .frame(width: 160, alignment: .leading)
                Text("AMOUNT")
                    .frame(width: 120, alignment: .trailing)
                Text("NOTES")
                    .frame(width: 150, alignment: .leading)
                    .padding(.leading, 16)
                Text("")
                    .frame(width: 80)
            }
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(AppTheme.textMuted)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(AppTheme.surface.opacity(0.5))
            
            Divider().overlay(AppTheme.border.opacity(0.3))
            
            // Table Rows
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredExpenses, id: \.id) { expense in
                        if editingExpenseId == expense.id {
                            editingRow(expense)
                        } else {
                            displayRow(expense)
                        }
                        
                        Divider().overlay(AppTheme.border.opacity(0.15))
                    }
                }
            }
        }
        .glassCard(padding: 0)
        .padding(.horizontal, 32)
        .padding(.bottom, 32)
    }
    
    // MARK: - Display Row
    private func displayRow(_ expense: Expense) -> some View {
        HStack(spacing: 0) {
            // Date
            Text(expense.date, format: .dateTime.month(.abbreviated).day().year())
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
                .frame(width: 110, alignment: .leading)
            
            // Title
            HStack(spacing: 8) {
                if expense.source == "splitwise" {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.accentSecondary)
                }
                Text(expense.title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Category
            HStack(spacing: 6) {
                if let cat = expense.category {
                    Circle()
                        .fill(cat.color)
                        .frame(width: 8, height: 8)
                    Text(cat.name)
                        .lineLimit(1)
                } else {
                    Text("Uncategorized")
                }
            }
            .font(.system(size: 13))
            .foregroundColor(AppTheme.textSecondary)
            .frame(width: 160, alignment: .leading)
            
            // Amount
            Text(expense.formattedAmount)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.danger)
                .frame(width: 120, alignment: .trailing)
            
            // Notes
            Text(expense.notes.isEmpty ? "—" : expense.notes)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textMuted)
                .lineLimit(1)
                .frame(width: 150, alignment: .leading)
                .padding(.leading, 16)
            
            // Actions
            HStack(spacing: 8) {
                Button {
                    startEditing(expense)
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.surfaceElevated)
                        )
                }
                .buttonStyle(.plain)
                .opacity(hoveredExpenseId == expense.id ? 1 : 0)
                
                Button {
                    deleteExpense(expense)
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.danger)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.danger.opacity(0.1))
                        )
                }
                .buttonStyle(.plain)
                .opacity(hoveredExpenseId == expense.id ? 1 : 0)
            }
            .frame(width: 80)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(
            hoveredExpenseId == expense.id
                ? AppTheme.surfaceElevated.opacity(0.4)
                : Color.clear
        )
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.1)) {
                hoveredExpenseId = isHovered ? expense.id : nil
            }
        }
    }
    
    // MARK: - Editing Row
    private func editingRow(_ expense: Expense) -> some View {
        HStack(spacing: 0) {
            // Date
            DatePicker("", selection: $editDate, displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.field)
                .frame(width: 110, alignment: .leading)
            
            // Title
            TextField("Title", text: $editTitle)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppTheme.textPrimary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.surfaceElevated)
                )
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Category
            Picker("", selection: $editCategory) {
                Text("None").tag(nil as ExpenseCategory?)
                ForEach(categories, id: \.id) { cat in
                    Label(cat.name, systemImage: cat.icon)
                        .tag(cat as ExpenseCategory?)
                }
            }
            .labelsHidden()
            .frame(width: 160)
            
            // Amount
            TextField("0", text: $editAmount)
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(AppTheme.danger)
                .multilineTextAlignment(.trailing)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.surfaceElevated)
                )
                .frame(width: 120)
            
            // Notes
            TextField("Notes", text: $editNotes)
                .textFieldStyle(.plain)
                .font(.system(size: 12))
                .foregroundColor(AppTheme.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(AppTheme.surfaceElevated)
                )
                .frame(width: 150)
                .padding(.leading, 16)
            
            // Save/Cancel
            HStack(spacing: 6) {
                Button {
                    saveEdit(expense)
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.success)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.success.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
                
                Button {
                    editingExpenseId = nil
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppTheme.danger)
                        .frame(width: 28, height: 28)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(AppTheme.danger.opacity(0.15))
                        )
                }
                .buttonStyle(.plain)
            }
            .frame(width: 80)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 8)
        .background(AppTheme.accent.opacity(0.05))
    }
    
    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "tray")
                .font(.system(size: 48))
                .foregroundColor(AppTheme.textMuted)
            
            Text("No expenses found")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.textSecondary)
            
            Text("Add your first expense or import from Splitwise")
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textMuted)
            
            Button {
                showAddSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text("Add Expense")
                }
                .gradientButton()
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Actions
    private func startEditing(_ expense: Expense) {
        editTitle = expense.title
        editAmount = String(format: "%.2f", expense.amount)
        editDate = expense.date
        editCategory = expense.category
        editNotes = expense.notes
        
        withAnimation(.easeInOut(duration: 0.2)) {
            editingExpenseId = expense.id
        }
    }
    
    private func saveEdit(_ expense: Expense) {
        expense.title = editTitle
        expense.amount = Double(editAmount) ?? expense.amount
        expense.date = editDate
        expense.category = editCategory
        expense.notes = editNotes
        
        try? modelContext.save()
        
        withAnimation(.easeInOut(duration: 0.2)) {
            editingExpenseId = nil
        }
    }
    
    private func deleteExpense(_ expense: Expense) {
        withAnimation {
            modelContext.delete(expense)
            try? modelContext.save()
        }
    }
}
