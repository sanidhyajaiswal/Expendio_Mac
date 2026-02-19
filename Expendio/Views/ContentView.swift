import SwiftUI
import SwiftData

enum SidebarItem: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case expenses = "Expenses"
    case reports = "Reports"
    case categories = "Categories"
    case importCSV = "Import"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .expenses: return "list.bullet.rectangle.fill"
        case .reports: return "chart.bar.fill"
        case .categories: return "tag.fill"
        case .importCSV: return "square.and.arrow.down.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedItem: SidebarItem = .dashboard
    @State private var hoveredItem: SidebarItem?
    @Environment(\.modelContext) private var modelContext
    @Query private var categories: [ExpenseCategory]
    
    var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            sidebar
            
            // Divider
            Rectangle()
                .fill(AppTheme.border.opacity(0.3))
                .frame(width: 1)
            
            // Main Content
            mainContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(AppTheme.background)
        }
        .background(AppTheme.background)
        .onAppear {
            seedDefaultCategories()
        }
    }
    
    // MARK: - Sidebar
    private var sidebar: some View {
        VStack(spacing: 0) {
            // Logo
            HStack(spacing: 10) {
                Image(systemName: "indianrupeesign.circle.fill")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(AppTheme.accentGradient)
                
                Text("Expendio")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .padding(.top, 20)
            .padding(.bottom, 30)
            .padding(.horizontal, 20)
            
            // Menu Items
            VStack(spacing: 4) {
                ForEach(SidebarItem.allCases) { item in
                    sidebarButton(item)
                }
            }
            .padding(.horizontal, 12)
            
            Spacer()
            
            // Footer
            VStack(spacing: 8) {
                Divider()
                    .overlay(AppTheme.border.opacity(0.3))
                
                HStack {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 13))
                        .foregroundColor(AppTheme.textSecondary)
                    
                    Text("v1.0")
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textMuted)
                }
                .padding(.bottom, 16)
            }
        }
        .frame(width: 220)
        .background(
            AppTheme.surface.opacity(0.5)
        )
    }
    
    private func sidebarButton(_ item: SidebarItem) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedItem = item
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.icon)
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 24)
                
                Text(item.rawValue)
                    .font(.system(size: 14, weight: selectedItem == item ? .semibold : .medium))
                
                Spacer()
            }
            .foregroundColor(selectedItem == item ? .white : AppTheme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(selectedItem == item
                          ? AppTheme.accentGradient
                          : (hoveredItem == item
                             ? LinearGradient(colors: [AppTheme.surfaceElevated], startPoint: .leading, endPoint: .trailing)
                             : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing))
                    )
                    .opacity(selectedItem == item ? 1 : 0.8)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovered in
            withAnimation(.easeInOut(duration: 0.15)) {
                hoveredItem = isHovered ? item : nil
            }
        }
    }
    
    // MARK: - Main Content
    @ViewBuilder
    private var mainContent: some View {
        switch selectedItem {
        case .dashboard:
            DashboardView()
        case .expenses:
            ExpenseListView()
        case .reports:
            ReportsView()
        case .categories:
            CategoryManagementView()
        case .importCSV:
            ImportView()
        }
    }
    
    // MARK: - Seed Default Categories
    private func seedDefaultCategories() {
        guard categories.isEmpty else { return }
        
        for (name, icon, color) in ExpenseCategory.defaults {
            let category = ExpenseCategory(name: name, icon: icon, colorHex: color)
            modelContext.insert(category)
        }
        try? modelContext.save()
    }
}
