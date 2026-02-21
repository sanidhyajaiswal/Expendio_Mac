import SwiftUI
import SwiftData

enum DateFilter: Equatable {
    case allTime
    case thisMonth
    case lastMonth
    case thisYear
    case customMonth(Date)
    case customYear(Date)
    
    var title: String {
        switch self {
        case .allTime: return "All Time"
        case .thisMonth: return "This Month"
        case .lastMonth: return "Last Month"
        case .thisYear: return "This Year"
        case .customMonth(let d): return d.formatted(.dateTime.month().year())
        case .customYear(let d): return d.formatted(.dateTime.year())
        }
    }
    
    var dateRange: Range<Date>? {
        let cal = Calendar.current
        let now = Date()
        switch self {
        case .allTime: return nil
        case .thisMonth:
            guard let start = cal.dateInterval(of: .month, for: now)?.start,
                  let end = cal.dateInterval(of: .month, for: now)?.end else { return nil }
            return start..<end
        case .lastMonth:
            guard let lastMonthDate = cal.date(byAdding: .month, value: -1, to: now),
                  let start = cal.dateInterval(of: .month, for: lastMonthDate)?.start,
                  let end = cal.dateInterval(of: .month, for: lastMonthDate)?.end else { return nil }
            return start..<end
        case .thisYear:
            guard let start = cal.dateInterval(of: .year, for: now)?.start,
                  let end = cal.dateInterval(of: .year, for: now)?.end else { return nil }
            return start..<end
        case .customMonth(let d):
            guard let start = cal.dateInterval(of: .month, for: d)?.start,
                  let end = cal.dateInterval(of: .month, for: d)?.end else { return nil }
            return start..<end
        case .customYear(let d):
            guard let start = cal.dateInterval(of: .year, for: d)?.start,
                  let end = cal.dateInterval(of: .year, for: d)?.end else { return nil }
            return start..<end
        }
    }
}
struct ExpenseListView: View {
    let profileId: UUID
    @Environment(\.modelContext) private var modelContext
    @Query private var expenses: [Expense]
    @Query private var categories: [ExpenseCategory]
    @Environment(\.themeAccent) private var themeAccent

    @State private var searchText = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var selectedDateFilter: DateFilter = .allTime
    @State private var showAddSheet = false
    @State private var showImportSheet = false
    @State private var editingExpenseId: UUID?
    @State private var hoveredExpenseId: UUID?
    @State private var editTitle = ""
    @State private var editAmount = ""
    @State private var editDate = Date()
    @State private var editCategory: ExpenseCategory?
    @State private var editNotes = ""

    // Multi-select
    @State private var selectedIds: Set<UUID> = []
    @State private var showDeleteSelectedConfirm = false
    @State private var isHeaderHovered = false

    init(profileId: UUID, initialCategory: ExpenseCategory? = nil, initialDateFilter: DateFilter = .allTime) {
        self.profileId = profileId
        let pid = profileId
        _expenses = Query(filter: #Predicate<Expense> { $0.profileId == pid }, sort: \Expense.date, order: .reverse)
        _categories = Query(filter: #Predicate<ExpenseCategory> { $0.profileId == pid })
        _selectedCategory = State(initialValue: initialCategory)
        _selectedDateFilter = State(initialValue: initialDateFilter)
    }

    private var filteredExpenses: [Expense] {
        expenses.filter { expense in
            let matchesSearch = searchText.isEmpty
                || expense.title.localizedCaseInsensitiveContains(searchText)
                || expense.notes.localizedCaseInsensitiveContains(searchText)
            let matchesCat = selectedCategory == nil || expense.category?.id == selectedCategory?.id
            let matchesDate = selectedDateFilter.dateRange?.contains(expense.date) ?? true
            return matchesSearch && matchesCat && matchesDate
        }
    }

    private var allSelected: Bool {
        !filteredExpenses.isEmpty && filteredExpenses.allSatisfy { selectedIds.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            filterBar
            if filteredExpenses.isEmpty { emptyState } else { expenseTable }
        }
        .background(AppTheme.dynamicBackground)
        .sheet(isPresented: $showAddSheet) { AddExpenseView(profileId: profileId) }
        .sheet(isPresented: $showImportSheet) { ImportView(profileId: profileId) }
        .confirmationDialog(
            "Delete \(selectedIds.count) expense\(selectedIds.count == 1 ? "" : "s")?",
            isPresented: $showDeleteSelectedConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteSelected() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This action cannot be undone.") }
        .confirmationDialog(
            "Delete \(selectedIds.count) expense\(selectedIds.count == 1 ? "" : "s")?",
            isPresented: $showDeleteSelectedConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteSelected() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This action cannot be undone.") }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Expenses").font(.system(size: 28, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                Text("\(filteredExpenses.count) expense\(filteredExpenses.count == 1 ? "" : "s")").font(.system(size: 14)).foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }.padding(.horizontal, 32).padding(.top, 32).padding(.bottom, 24)
    }

    // MARK: - Filter Bar
    private var filterBar: some View {
        HStack(alignment: .center, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(AppTheme.textMuted)
                TextField("Search expenses...", text: $searchText)
                    .textFieldStyle(.plain).font(.system(size: 13)).foregroundColor(AppTheme.textPrimary)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(AppTheme.textMuted)
                    }.buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .frame(height: 36)
            .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.dynamicSurfaceElevated))
            .frame(maxWidth: 300)

            HStack(spacing: 12) {
                Menu {
                    Button("All Time") { selectedDateFilter = .allTime }
                    Button("This Month") { selectedDateFilter = .thisMonth }
                    Button("Last Month") { selectedDateFilter = .lastMonth }
                    Button("This Year") { selectedDateFilter = .thisYear }
                    if case .customMonth = selectedDateFilter {
                        Divider()
                        Button(selectedDateFilter.title) {}
                    } else if case .customYear = selectedDateFilter {
                        Divider()
                        Button(selectedDateFilter.title) {}
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                        Text(selectedDateFilter.title).lineLimit(1)
                        Image(systemName: "chevron.down").font(.system(size: 10))
                    }
                    .font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.dynamicSurfaceElevated))
                }.buttonStyle(.plain)

                Menu {
                    Button("All Categories") { selectedCategory = nil }; Divider()
                    ForEach(categories, id: \.id) { cat in
                        Button { selectedCategory = cat } label: { Label(cat.name, systemImage: cat.icon) }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                        Text(selectedCategory?.name ?? "All Categories").lineLimit(1)
                        Image(systemName: "chevron.down").font(.system(size: 10))
                    }
                    .font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textSecondary)
                    .padding(.horizontal, 12)
                    .frame(height: 36)
                    .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.dynamicSurfaceElevated))
                }.buttonStyle(.plain)
            }
            
            Spacer()
            
            if !selectedIds.isEmpty {
                Button { showDeleteSelectedConfirm = true } label: {
                    HStack(spacing: 6) { Image(systemName: "trash").font(.system(size: 12, weight: .bold)); Text("Delete") }
                        .font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.danger)
                        .padding(.horizontal, 16)
                        .frame(height: 36)
                        .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.danger.opacity(0.15)))
                }.buttonStyle(.plain)
            }
            
            Button { showImportSheet = true } label: {
                HStack(spacing: 6) { Image(systemName: "square.and.arrow.down").font(.system(size: 12, weight: .bold)); Text("Import") }
                    .font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textPrimary)
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.dynamicSurfaceElevated))
            }.buttonStyle(.plain)

            Button { showAddSheet = true } label: {
                HStack(spacing: 6) { Image(systemName: "plus").font(.system(size: 12, weight: .bold)); Text("Add") }
                    .font(.system(size: 13, weight: .medium)).foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .frame(height: 36)
                    .background(RoundedRectangle(cornerRadius: 8).fill(themeAccent))
            }.buttonStyle(.plain)
        }.padding(.horizontal, 32).padding(.bottom, 16)
    }

    // MARK: - Table
    private var expenseTable: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section(header: tableHeader) {
                    ForEach(filteredExpenses, id: \.id) { expense in
                        if editingExpenseId == expense.id {
                            editingRow(expense)
                        } else {
                            expenseRow(expense)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 32).padding(.bottom, 32)
    }

    private var tableHeader: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Image(systemName: allSelected ? "checkmark.square.fill" : "square")
                    .foregroundColor(allSelected ? themeAccent : AppTheme.textMuted)
                    .font(.system(size: 15))
                    .frame(width: 24)
                    .padding(.trailing, 12)
                    .opacity(allSelected || isHeaderHovered ? 1 : 0)
                    .onTapGesture {
                        withAnimation {
                            if allSelected { selectedIds.removeAll() }
                            else { selectedIds = Set(filteredExpenses.map(\.id)) }
                        }
                    }
                Text("DATE").frame(width: 100, alignment: .leading)
                Text("TITLE").frame(maxWidth: .infinity, alignment: .leading)
                Text("CATEGORY").frame(width: 120, alignment: .leading)
                Text("AMOUNT").frame(width: 80, alignment: .trailing)
                Spacer().frame(width: 48)
                Text("NOTES").frame(width: 140, alignment: .leading)
                Spacer().frame(width: 64) // To match actions button column in row
            }
            .font(.system(size: 11, weight: .bold)) // Stronger header font like Notion
            .foregroundColor(AppTheme.textMuted)
            .padding(.horizontal, 20).padding(.vertical, 12)
            .background(AppTheme.dynamicBackground)
            .onHover { h in withAnimation(.easeInOut(duration: 0.1)) { isHeaderHovered = h } }

            Divider().overlay(AppTheme.dynamicBorder)
        }
    }

    // MARK: - Expense Row
    private func expenseRow(_ expense: Expense) -> some View {
        let isSelected = selectedIds.contains(expense.id)
        return HStack(spacing: 0) {
            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                .foregroundColor(isSelected ? themeAccent : AppTheme.textMuted)
                .font(.system(size: 15))
                .frame(width: 24)
                .padding(.trailing, 12)
                .opacity(isSelected || hoveredExpenseId == expense.id ? 1 : 0)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.12)) {
                        if isSelected { selectedIds.remove(expense.id) } else { selectedIds.insert(expense.id) }
                    }
                }

            Text(expense.date, format: .dateTime.month(.abbreviated).day().year())
                .font(.system(size: 13)).foregroundColor(AppTheme.textSecondary).frame(width: 100, alignment: .leading)
            HStack(spacing: 8) {
                if expense.source == "splitwise" { Image(systemName: "arrow.down.circle.fill").font(.system(size: 12)).foregroundColor(AppTheme.accentSecondary) }
                Text(expense.title).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textPrimary).lineLimit(1)
            }.frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 6) {
                if let cat = expense.category { Circle().fill(cat.color).frame(width: 8, height: 8); Text(cat.name).lineLimit(1) }
                else { Text("Uncategorized") }
            }.frame(width: 120, alignment: .leading)
            Text(expense.formattedAmount).font(.system(size: 13, weight: .semibold)).foregroundColor(AppTheme.danger).frame(width: 80, alignment: .trailing)
            Spacer().frame(width: 48)
            Text(expense.notes.isEmpty ? "—" : expense.notes).font(.system(size: 12)).foregroundColor(AppTheme.textMuted).lineLimit(1).frame(width: 140, alignment: .leading)
            HStack(spacing: 8) {
                Button { startEditing(expense) } label: {
                    Image(systemName: "pencil").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                        .frame(width: 28, height: 28).background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.surfaceElevated))
                }.buttonStyle(.plain).opacity(hoveredExpenseId == expense.id ? 1 : 0)
            }.frame(width: 64, alignment: .trailing)
        }
        .padding(.horizontal, 20).padding(.vertical, 8)
        .background(isSelected ? themeAccent.opacity(0.08) : (hoveredExpenseId == expense.id ? AppTheme.dynamicSurfaceElevated : Color.clear))
        .contentShape(Rectangle())
        .onHover { h in withAnimation(.easeInOut(duration: 0.1)) { hoveredExpenseId = h ? expense.id : nil } }
    }

    // MARK: - Editing Row
    private func editingRow(_ expense: Expense) -> some View {
        HStack(spacing: 0) {
            Spacer().frame(width: 24).padding(.trailing, 12)
            DatePicker("", selection: $editDate, displayedComponents: .date).labelsHidden().datePickerStyle(.field).frame(width: 100, alignment: .leading)
            TextField("Title", text: $editTitle).textFieldStyle(.plain).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textPrimary).padding(.horizontal, 8).padding(.vertical, 4).background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.dynamicSurfaceElevated)).frame(maxWidth: .infinity, alignment: .leading)
            Picker("", selection: $editCategory) {
                Text("None").tag(nil as ExpenseCategory?)
                ForEach(categories, id: \.id) { cat in Label(cat.name, systemImage: cat.icon).tag(cat as ExpenseCategory?) }
            }.labelsHidden().frame(width: 120, alignment: .leading)
            TextField("0", text: $editAmount).textFieldStyle(.plain).font(.system(size: 13, weight: .semibold)).foregroundColor(AppTheme.danger).multilineTextAlignment(.trailing).padding(.horizontal, 8).padding(.vertical, 4).background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.dynamicSurfaceElevated)).frame(width: 80, alignment: .trailing)
            Spacer().frame(width: 48)
            TextField("Notes", text: $editNotes).textFieldStyle(.plain).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary).padding(.horizontal, 8).padding(.vertical, 4).background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.dynamicSurfaceElevated)).frame(width: 140, alignment: .leading)
            HStack(spacing: 6) {
                Button { saveEdit(expense) } label: { Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(AppTheme.success).frame(width: 28, height: 28).background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.success.opacity(0.15))) }.buttonStyle(.plain)
                Button { editingExpenseId = nil } label: { Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundColor(AppTheme.danger).frame(width: 28, height: 28).background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.danger.opacity(0.15))) }.buttonStyle(.plain)
            }.frame(width: 64, alignment: .trailing)
        }.padding(.horizontal, 20).padding(.vertical, 8).background(themeAccent.opacity(0.05))
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "tray").font(.system(size: 48)).foregroundColor(AppTheme.textMuted)
            Text("No expenses found").font(.system(size: 18, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
            Text("Add your first expense or import from Splitwise").font(.system(size: 14)).foregroundColor(AppTheme.textMuted)
            Button { showAddSheet = true } label: { HStack(spacing: 6) { Image(systemName: "plus"); Text("Add Expense") }.gradientButton() }.buttonStyle(.plain).padding(.top, 8)
            Spacer()
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Actions
    private func startEditing(_ e: Expense) {
        editTitle = e.title
        editAmount = String(format: "%.2f", e.amount)
        editDate = e.date
        editCategory = e.category
        editNotes = e.notes
        withAnimation { editingExpenseId = e.id }
    }
    private func saveEdit(_ e: Expense) {
        e.title = editTitle
        e.amount = Double(editAmount) ?? e.amount
        e.date = editDate
        e.category = editCategory
        e.notes = editNotes
        do {
            try modelContext.save()
        } catch {
            print("Failed to save expense edit: \(error)")
        }
        withAnimation { editingExpenseId = nil }
    }
    private func deleteExpense(_ e: Expense) { withAnimation { modelContext.delete(e); try? modelContext.save() } }

    private func deleteSelected() {
        let toDelete = expenses.filter { selectedIds.contains($0.id) }
        withAnimation {
            toDelete.forEach { modelContext.delete($0) }
            try? modelContext.save()
            selectedIds.removeAll()
        }
    }
}
