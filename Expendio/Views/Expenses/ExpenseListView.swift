import SwiftUI
import SwiftData

struct ExpenseListView: View {
    let profileId: UUID
    @Environment(\.modelContext) private var modelContext
    @Query private var expenses: [Expense]
    @Query private var categories: [ExpenseCategory]

    @State private var searchText = ""
    @State private var selectedCategory: ExpenseCategory?
    @State private var showAddSheet = false
    @State private var editingExpenseId: UUID?
    @State private var hoveredExpenseId: UUID?
    @State private var editTitle = ""
    @State private var editAmount = ""
    @State private var editDate = Date()
    @State private var editCategory: ExpenseCategory?
    @State private var editNotes = ""

    // Multi-select
    @State private var selectedIds: Set<UUID> = []
    @State private var isSelectMode = false
    @State private var showDeleteAllConfirm = false
    @State private var showDeleteSelectedConfirm = false

    init(profileId: UUID) {
        self.profileId = profileId
        let pid = profileId
        _expenses = Query(filter: #Predicate<Expense> { $0.profileId == pid }, sort: \Expense.date, order: .reverse)
        _categories = Query(filter: #Predicate<ExpenseCategory> { $0.profileId == pid })
    }

    private var filteredExpenses: [Expense] {
        expenses.filter { expense in
            let matchesSearch = searchText.isEmpty
                || expense.title.localizedCaseInsensitiveContains(searchText)
                || expense.notes.localizedCaseInsensitiveContains(searchText)
            let matchesCat = selectedCategory == nil || expense.category?.id == selectedCategory?.id
            return matchesSearch && matchesCat
        }
    }

    private var allSelected: Bool {
        !filteredExpenses.isEmpty && filteredExpenses.allSatisfy { selectedIds.contains($0.id) }
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            if isSelectMode { selectionToolbar }
            filterBar
            if filteredExpenses.isEmpty { emptyState } else { expenseTable }
        }
        .background(AppTheme.background)
        .sheet(isPresented: $showAddSheet) { AddExpenseView(profileId: profileId) }
        .confirmationDialog(
            "Delete \(selectedIds.count) expense\(selectedIds.count == 1 ? "" : "s")?",
            isPresented: $showDeleteSelectedConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) { deleteSelected() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This action cannot be undone.") }
        .confirmationDialog(
            "Delete all \(filteredExpenses.count) expense\(filteredExpenses.count == 1 ? "" : "s")?",
            isPresented: $showDeleteAllConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete All", role: .destructive) { deleteAll() }
            Button("Cancel", role: .cancel) {}
        } message: { Text("This will permanently delete all visible expenses. This action cannot be undone.") }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Expenses").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary)
                Text("\(filteredExpenses.count) expense\(filteredExpenses.count == 1 ? "" : "s")").font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
            }
            Spacer()

            // Select / Cancel
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isSelectMode.toggle()
                    if !isSelectMode { selectedIds.removeAll() }
                }
            } label: {
                Text(isSelectMode ? "Cancel" : "Select")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelectMode ? AppTheme.danger : AppTheme.textSecondary)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.surfaceElevated))
            }.buttonStyle(.plain)

            // Delete All menu
            Menu {
                Button(role: .destructive) { showDeleteAllConfirm = true } label: {
                    Label("Delete All Expenses", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.system(size: 18))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 36, height: 36)
                    .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.surfaceElevated))
            }.menuStyle(.borderlessButton).frame(width: 36)

            Button { showAddSheet = true } label: {
                HStack(spacing: 6) { Image(systemName: "plus"); Text("Add Expense") }.gradientButton()
            }.buttonStyle(.plain)
        }.padding(.horizontal, 32).padding(.top, 28).padding(.bottom, 12)
    }

    // MARK: - Selection Toolbar
    private var selectionToolbar: some View {
        HStack(spacing: 16) {
            // Select All toggle
            Button {
                withAnimation {
                    if allSelected {
                        selectedIds.removeAll()
                    } else {
                        selectedIds = Set(filteredExpenses.map(\.id))
                    }
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: allSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(allSelected ? AppTheme.accent : AppTheme.textSecondary)
                    Text(allSelected ? "Deselect All" : "Select All")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }.buttonStyle(.plain)

            if !selectedIds.isEmpty {
                Text("\(selectedIds.count) selected")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.accent)

                Spacer()

                Button {
                    showDeleteSelectedConfirm = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                        Text("Delete Selected")
                    }
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14).padding(.vertical, 8)
                    .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.danger))
                }.buttonStyle(.plain)
            } else {
                Spacer()
                Text("Tap rows to select")
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textMuted)
            }
        }
        .padding(.horizontal, 32).padding(.vertical, 10)
        .background(AppTheme.accent.opacity(0.06))
        .overlay(Rectangle().fill(AppTheme.accent.opacity(0.15)).frame(height: 1), alignment: .bottom)
        .transition(.move(edge: .top).combined(with: .opacity))
    }

    // MARK: - Filter Bar
    private var filterBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass").foregroundColor(AppTheme.textMuted)
                TextField("Search expenses...", text: $searchText)
                    .textFieldStyle(.plain).font(.system(size: 13)).foregroundColor(AppTheme.textPrimary)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill").foregroundColor(AppTheme.textMuted)
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal, 12).padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.surfaceElevated)
                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border.opacity(0.5), lineWidth: 1)))
            .frame(maxWidth: 300)

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
                .padding(.horizontal, 12).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.surfaceElevated)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border.opacity(0.5), lineWidth: 1)))
            }
            Spacer()
        }.padding(.horizontal, 32).padding(.bottom, 16)
    }

    // MARK: - Table
    private var expenseTable: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                if isSelectMode {
                    // Column header checkbox
                    Image(systemName: allSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(allSelected ? AppTheme.accent : AppTheme.textMuted)
                        .font(.system(size: 15))
                        .frame(width: 36)
                        .onTapGesture {
                            withAnimation {
                                if allSelected { selectedIds.removeAll() }
                                else { selectedIds = Set(filteredExpenses.map(\.id)) }
                            }
                        }
                }
                Text("DATE").frame(width: 110, alignment: .leading)
                Text("TITLE").frame(maxWidth: .infinity, alignment: .leading)
                Text("CATEGORY").frame(width: 160, alignment: .leading)
                Text("AMOUNT").frame(width: 120, alignment: .trailing)
                Text("NOTES").frame(width: 150, alignment: .leading).padding(.leading, 16)
                if !isSelectMode { Text("").frame(width: 80) }
            }
            .font(.system(size: 11, weight: .semibold)).foregroundColor(AppTheme.textMuted)
            .padding(.horizontal, 20).padding(.vertical, 10)
            .background(AppTheme.surface.opacity(0.5))

            Divider().overlay(AppTheme.border.opacity(0.3))

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(filteredExpenses, id: \.id) { expense in
                        if isSelectMode {
                            selectableRow(expense)
                        } else if editingExpenseId == expense.id {
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
        .padding(.horizontal, 32).padding(.bottom, 32)
    }

    // MARK: - Selectable Row
    private func selectableRow(_ expense: Expense) -> some View {
        let isSelected = selectedIds.contains(expense.id)
        return HStack(spacing: 0) {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isSelected ? AppTheme.accent : AppTheme.textMuted)
                .font(.system(size: 15))
                .frame(width: 36)

            Text(expense.date, format: .dateTime.month(.abbreviated).day().year())
                .font(.system(size: 13)).foregroundColor(AppTheme.textSecondary).frame(width: 110, alignment: .leading)
            HStack(spacing: 8) {
                if expense.source == "splitwise" {
                    Image(systemName: "arrow.down.circle.fill").font(.system(size: 12)).foregroundColor(AppTheme.accentSecondary)
                }
                Text(expense.title).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textPrimary).lineLimit(1)
            }.frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 6) {
                if let cat = expense.category { Circle().fill(cat.color).frame(width: 8, height: 8); Text(cat.name).lineLimit(1) }
                else { Text("Uncategorized") }
            }.font(.system(size: 13)).foregroundColor(AppTheme.textSecondary).frame(width: 160, alignment: .leading)
            Text(expense.formattedAmount).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(AppTheme.danger).frame(width: 120, alignment: .trailing)
            Text(expense.notes.isEmpty ? "—" : expense.notes).font(.system(size: 12)).foregroundColor(AppTheme.textMuted).lineLimit(1).frame(width: 150, alignment: .leading).padding(.leading, 16)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(isSelected ? AppTheme.accent.opacity(0.08) : (hoveredExpenseId == expense.id ? AppTheme.surfaceElevated.opacity(0.4) : Color.clear))
        .contentShape(Rectangle())
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.12)) {
                if isSelected { selectedIds.remove(expense.id) } else { selectedIds.insert(expense.id) }
            }
        }
        .onHover { h in withAnimation(.easeInOut(duration: 0.1)) { hoveredExpenseId = h ? expense.id : nil } }
    }

    // MARK: - Display Row
    private func displayRow(_ expense: Expense) -> some View {
        HStack(spacing: 0) {
            Text(expense.date, format: .dateTime.month(.abbreviated).day().year())
                .font(.system(size: 13)).foregroundColor(AppTheme.textSecondary).frame(width: 110, alignment: .leading)
            HStack(spacing: 8) {
                if expense.source == "splitwise" { Image(systemName: "arrow.down.circle.fill").font(.system(size: 12)).foregroundColor(AppTheme.accentSecondary) }
                Text(expense.title).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textPrimary).lineLimit(1)
            }.frame(maxWidth: .infinity, alignment: .leading)
            HStack(spacing: 6) {
                if let cat = expense.category { Circle().fill(cat.color).frame(width: 8, height: 8); Text(cat.name).lineLimit(1) }
                else { Text("Uncategorized") }
            }.font(.system(size: 13)).foregroundColor(AppTheme.textSecondary).frame(width: 160, alignment: .leading)
            Text(expense.formattedAmount).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(AppTheme.danger).frame(width: 120, alignment: .trailing)
            Text(expense.notes.isEmpty ? "—" : expense.notes).font(.system(size: 12)).foregroundColor(AppTheme.textMuted).lineLimit(1).frame(width: 150, alignment: .leading).padding(.leading, 16)
            HStack(spacing: 8) {
                Button { startEditing(expense) } label: {
                    Image(systemName: "pencil").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                        .frame(width: 28, height: 28).background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.surfaceElevated))
                }.buttonStyle(.plain).opacity(hoveredExpenseId == expense.id ? 1 : 0)
                Button { deleteExpense(expense) } label: {
                    Image(systemName: "trash").font(.system(size: 12)).foregroundColor(AppTheme.danger)
                        .frame(width: 28, height: 28).background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.danger.opacity(0.1)))
                }.buttonStyle(.plain).opacity(hoveredExpenseId == expense.id ? 1 : 0)
            }.frame(width: 80)
        }
        .padding(.horizontal, 20).padding(.vertical, 10)
        .background(hoveredExpenseId == expense.id ? AppTheme.surfaceElevated.opacity(0.4) : Color.clear)
        .onHover { h in withAnimation(.easeInOut(duration: 0.1)) { hoveredExpenseId = h ? expense.id : nil } }
    }

    // MARK: - Editing Row
    private func editingRow(_ expense: Expense) -> some View {
        HStack(spacing: 0) {
            DatePicker("", selection: $editDate, displayedComponents: .date).labelsHidden().datePickerStyle(.field).frame(width: 110, alignment: .leading)
            TextField("Title", text: $editTitle).textFieldStyle(.plain).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textPrimary).padding(.horizontal, 8).padding(.vertical, 4).background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.surfaceElevated)).frame(maxWidth: .infinity, alignment: .leading)
            Picker("", selection: $editCategory) {
                Text("None").tag(nil as ExpenseCategory?)
                ForEach(categories, id: \.id) { cat in Label(cat.name, systemImage: cat.icon).tag(cat as ExpenseCategory?) }
            }.labelsHidden().frame(width: 160)
            TextField("0", text: $editAmount).textFieldStyle(.plain).font(.system(size: 13, weight: .semibold, design: .rounded)).foregroundColor(AppTheme.danger).multilineTextAlignment(.trailing).padding(.horizontal, 8).padding(.vertical, 4).background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.surfaceElevated)).frame(width: 120)
            TextField("Notes", text: $editNotes).textFieldStyle(.plain).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary).padding(.horizontal, 8).padding(.vertical, 4).background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.surfaceElevated)).frame(width: 150).padding(.leading, 16)
            HStack(spacing: 6) {
                Button { saveEdit(expense) } label: { Image(systemName: "checkmark").font(.system(size: 12, weight: .bold)).foregroundColor(AppTheme.success).frame(width: 28, height: 28).background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.success.opacity(0.15))) }.buttonStyle(.plain)
                Button { editingExpenseId = nil } label: { Image(systemName: "xmark").font(.system(size: 12, weight: .bold)).foregroundColor(AppTheme.danger).frame(width: 28, height: 28).background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.danger.opacity(0.15))) }.buttonStyle(.plain)
            }.frame(width: 80)
        }.padding(.horizontal, 20).padding(.vertical, 8).background(AppTheme.accent.opacity(0.05))
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
    private func startEditing(_ e: Expense) { editTitle = e.title; editAmount = String(format: "%.2f", e.amount); editDate = e.date; editCategory = e.category; editNotes = e.notes; withAnimation { editingExpenseId = e.id } }
    private func saveEdit(_ e: Expense) { e.title = editTitle; e.amount = Double(editAmount) ?? e.amount; e.date = editDate; e.category = editCategory; e.notes = editNotes; try? modelContext.save(); withAnimation { editingExpenseId = nil } }
    private func deleteExpense(_ e: Expense) { withAnimation { modelContext.delete(e); try? modelContext.save() } }

    private func deleteSelected() {
        let toDelete = expenses.filter { selectedIds.contains($0.id) }
        withAnimation {
            toDelete.forEach { modelContext.delete($0) }
            try? modelContext.save()
            selectedIds.removeAll()
            isSelectMode = false
        }
    }

    private func deleteAll() {
        let toDelete = filteredExpenses
        withAnimation {
            toDelete.forEach { modelContext.delete($0) }
            try? modelContext.save()
            selectedIds.removeAll()
        }
    }
}
