import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    let profileId: UUID
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [ExpenseCategory]
    @Environment(\.themeAccent) private var themeAccent
    
    @State private var showAddForm = false
    @State private var editingCategory: ExpenseCategory?
    @State private var hoveredCategoryId: UUID?
    @State private var formName = ""
    @State private var formIcon = "tag.fill"
    @State private var formColor = "#7C3AED"
    
    init(profileId: UUID) {
        self.profileId = profileId
        let pid = profileId
        _categories = Query(filter: #Predicate<ExpenseCategory> { $0.profileId == pid })
    }
    
    private let icons = [
        "fork.knife", "car.fill", "bag.fill", "film.fill", "bolt.fill",
        "heart.fill", "house.fill", "book.fill", "airplane", "creditcard.fill",
        "cart.fill", "ellipsis.circle.fill", "gamecontroller.fill", "gift.fill",
        "music.note", "phone.fill", "cup.and.saucer.fill", "dumbbell.fill",
        "pawprint.fill", "leaf.fill", "wrench.fill", "tag.fill", "star.fill", "flame.fill",
    ]
    private let colors = [
        "#FF6B6B", "#4ECDC4", "#A78BFA", "#F59E0B", "#3B82F6",
        "#EC4899", "#8B5CF6", "#10B981", "#F97316", "#6366F1",
        "#14B8A6", "#6B7280", "#EF4444", "#06B6D4", "#84CC16",
        "#F43F5E", "#D946EF", "#0EA5E9",
    ]
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Categories").font(.system(size: 28, weight: .bold)).foregroundColor(AppTheme.textPrimary)
                    Text("\(categories.count) categories").font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                Button { formName = ""; formIcon = "tag.fill"; formColor = "#7C3AED"; showAddForm = true } label: {
                    HStack(spacing: 6) { Image(systemName: "plus"); Text("Add Category") }.gradientButton()
                }.buttonStyle(.plain)
            }.padding(.horizontal, 32).padding(.top, 28).padding(.bottom, 24)
            
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 240, maximum: 300), spacing: 16)], spacing: 16) {
                    ForEach(categories, id: \.id) { cat in categoryCard(cat) }
                }.padding(.horizontal, 32).padding(.bottom, 32).frame(maxWidth: .infinity)
            }
        }
        .background(AppTheme.dynamicBackground)
        .sheet(isPresented: $showAddForm) { categoryForm(editing: nil) }
        .sheet(item: $editingCategory) { cat in
            categoryForm(editing: cat).onAppear { formName = cat.name; formIcon = cat.icon; formColor = cat.colorHex }
        }
    }
    
    private func categoryCard(_ cat: ExpenseCategory) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                ZStack { RoundedRectangle(cornerRadius: 12).fill(cat.color.opacity(0.15)).frame(width: 44, height: 44); Image(systemName: cat.icon).font(.system(size: 20)).foregroundColor(cat.color) }
                VStack(alignment: .leading, spacing: 3) {
                    Text(cat.name).font(.system(size: 15, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
                    Text("\(cat.expenses.count) expenses").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                if hoveredCategoryId == cat.id {
                    HStack(spacing: 6) {
                        Button { editingCategory = cat } label: { Image(systemName: "pencil").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary).frame(width: 28, height: 28).background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.surfaceElevated)) }.buttonStyle(.plain)
                        Button { withAnimation { modelContext.delete(cat); try? modelContext.save() } } label: { Image(systemName: "trash").font(.system(size: 12)).foregroundColor(AppTheme.danger).frame(width: 28, height: 28).background(RoundedRectangle(cornerRadius: 6).fill(AppTheme.danger.opacity(0.1))) }.buttonStyle(.plain)
                    }.transition(.opacity)
                }
            }
        }.padding(18)
        .background(RoundedRectangle(cornerRadius: 16).fill(AppTheme.surface.opacity(0.7)).overlay(RoundedRectangle(cornerRadius: 16).stroke(hoveredCategoryId == cat.id ? cat.color.opacity(0.4) : AppTheme.border.opacity(0.3), lineWidth: 1)))
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hoveredCategoryId = h ? cat.id : nil } }
    }
    
    private func categoryForm(editing: ExpenseCategory?) -> some View {
        VStack(spacing: 0) {
            VStack(spacing: 10) {
                ZStack { RoundedRectangle(cornerRadius: 16).fill(Color(hex: formColor).opacity(0.15)).frame(width: 60, height: 60); Image(systemName: formIcon).font(.system(size: 28)).foregroundColor(Color(hex: formColor)) }
                Text(editing != nil ? "Edit Category" : "New Category").font(.system(size: 20, weight: .bold)).foregroundColor(AppTheme.textPrimary)
            }.frame(maxWidth: .infinity).padding(.vertical, 24).background(themeAccent.opacity(0.08))
            
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Name").font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
                    TextField("Category name", text: $formName).textFieldStyle(.plain).font(.system(size: 14)).foregroundColor(AppTheme.textPrimary).padding(12)
                        .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.surfaceElevated).overlay(RoundedRectangle(cornerRadius: 10).stroke(AppTheme.border.opacity(0.5), lineWidth: 1)))
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Icon").font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(40), spacing: 8), count: 8), spacing: 8) {
                        ForEach(icons, id: \.self) { ic in
                            Button { formIcon = ic } label: {
                                Image(systemName: ic).font(.system(size: 16)).foregroundColor(formIcon == ic ? Color(hex: formColor) : AppTheme.textSecondary).frame(width: 36, height: 36)
                                    .background(RoundedRectangle(cornerRadius: 8).fill(formIcon == ic ? Color(hex: formColor).opacity(0.15) : AppTheme.surfaceElevated).overlay(RoundedRectangle(cornerRadius: 8).stroke(formIcon == ic ? Color(hex: formColor).opacity(0.5) : Color.clear, lineWidth: 1.5)))
                            }.buttonStyle(.plain)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text("Color").font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(32), spacing: 8), count: 9), spacing: 8) {
                        ForEach(colors, id: \.self) { c in
                            Button { formColor = c } label: { Circle().fill(Color(hex: c)).frame(width: 28, height: 28).overlay(Circle().stroke(Color.white, lineWidth: formColor == c ? 2.5 : 0)).scaleEffect(formColor == c ? 1.15 : 1.0).animation(.spring(response: 0.3), value: formColor == c) }.buttonStyle(.plain)
                        }
                    }
                }
            }.padding(24)
            
            HStack {
                Button("Cancel") { showAddForm = false; editingCategory = nil }.font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textSecondary).padding(.horizontal, 20).padding(.vertical, 10).background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.surfaceElevated)).buttonStyle(.plain)
                Spacer()
                Button {
                    if let cat = editing { cat.name = formName; cat.icon = formIcon; cat.colorHex = formColor; try? modelContext.save(); editingCategory = nil }
                    else { modelContext.insert(ExpenseCategory(name: formName, icon: formIcon, colorHex: formColor, profileId: profileId)); try? modelContext.save(); showAddForm = false }
                } label: { Text(editing != nil ? "Save" : "Add").gradientButton() }.buttonStyle(.plain).disabled(formName.isEmpty)
            }.padding(20)
        }.frame(width: 440, height: 560).background(AppTheme.background)
    }
}

extension ExpenseCategory: Identifiable { }
