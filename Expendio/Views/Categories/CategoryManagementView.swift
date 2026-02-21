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
                    Text("Add Category")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(RoundedRectangle(cornerRadius: 8).fill(themeAccent))
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
                ZStack { 
                    RoundedRectangle(cornerRadius: 10).fill(cat.color.opacity(0.15)).frame(width: 40, height: 40)
                    Image(systemName: cat.icon).font(.system(size: 18)).foregroundColor(cat.color) 
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(cat.name).font(.system(size: 15, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
                    Text("\(cat.expenses.count) expenses").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                }
                Spacer()
                if hoveredCategoryId == cat.id {
                    HStack(spacing: 8) {
                        Button { editingCategory = cat } label: { 
                            Image(systemName: "pencil")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.dynamicSurfaceElevated))
                        }.buttonStyle(.plain)
                        Button { withAnimation { modelContext.delete(cat); try? modelContext.save() } } label: { 
                            Image(systemName: "trash")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.danger)
                                .frame(width: 32, height: 32)
                                .background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.danger.opacity(0.1))) 
                        }.buttonStyle(.plain)
                    }.transition(.opacity)
                }
            }
        }.padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(hoveredCategoryId == cat.id ? AppTheme.dynamicSurfaceElevated : Color.clear))
        .onHover { h in withAnimation(.easeInOut(duration: 0.15)) { hoveredCategoryId = h ? cat.id : nil } }
    }
    
    private func formField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label).font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.textSecondary)
            content()
                .padding(.horizontal, 12).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.dynamicSurfaceElevated))
        }
    }

    private func categoryForm(editing: ExpenseCategory?) -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(editing != nil ? "Edit Category" : "New Category")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                Button { showAddForm = false; editingCategory = nil } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppTheme.textMuted)
                }.buttonStyle(.plain)
            }
            .padding(.horizontal, 24).padding(.top, 24).padding(.bottom, 20)
            
            ScrollView {
                VStack(spacing: 24) {
                    formField(label: "Name") {
                        TextField("Category name", text: $formName)
                            .textFieldStyle(.plain)
                            .font(.system(size: 15))
                            .foregroundColor(AppTheme.textPrimary)
                    }
                    
                    formField(label: "Icon") {
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(36), spacing: 8), count: 8), spacing: 8) {
                            ForEach(icons, id: \.self) { ic in
                                Button { formIcon = ic } label: {
                                    Image(systemName: ic)
                                        .font(.system(size: 16))
                                        .foregroundColor(formIcon == ic ? Color(hex: formColor) : AppTheme.textSecondary)
                                        .frame(width: 36, height: 36)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(formIcon == ic ? Color(hex: formColor).opacity(0.15) : Color.clear)
                                        )
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                    
                    formField(label: "Color") {
                        LazyVGrid(columns: Array(repeating: GridItem(.fixed(28), spacing: 10), count: 9), spacing: 12) {
                            ForEach(colors, id: \.self) { c in
                                Button { formColor = c } label: { 
                                    Circle()
                                        .fill(Color(hex: c))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white.opacity(0.8), lineWidth: formColor == c ? 2 : 0)
                                                .scaleEffect(1.2)
                                        )
                                }.buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24).padding(.bottom, 24)
            }
            
            HStack(spacing: 12) {
                Button { showAddForm = false; editingCategory = nil } label: {
                    Text("Cancel")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.danger)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(AppTheme.dynamicSurfaceElevated))
                }.buttonStyle(.plain)

                Button {
                    if let cat = editing { cat.name = formName; cat.icon = formIcon; cat.colorHex = formColor; try? modelContext.save(); editingCategory = nil }
                    else { modelContext.insert(ExpenseCategory(name: formName, icon: formIcon, colorHex: formColor, profileId: profileId)); try? modelContext.save(); showAddForm = false }
                } label: { 
                    Text(editing != nil ? "Save Category" : "Add Category")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).fill(themeAccent))
                }
                .buttonStyle(.plain)
                .disabled(formName.isEmpty)
                .opacity(formName.isEmpty ? 0.5 : 1.0)
            }.padding(24)
        }.frame(width: 440, height: 500).background(AppTheme.dynamicBackground)
    }
}

extension ExpenseCategory: Identifiable { }
