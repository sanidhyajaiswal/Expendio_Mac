import SwiftUI
import SwiftData
import Charts

enum ReportTab: String, CaseIterable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"
}

struct ReportsView: View {
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query private var categories: [ExpenseCategory]
    
    @State private var selectedTab: ReportTab = .monthly
    @State private var currentDate = Date()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            // Tab Bar
            tabBar
            
            // Content
            ScrollView {
                VStack(spacing: 20) {
                    // Period Navigator
                    periodNavigator
                    
                    // Summary Card
                    summaryCard
                    
                    // Charts Row
                    HStack(alignment: .top, spacing: 20) {
                        mainChart
                        categoryPieChart
                    }
                    
                    // Category Table
                    categoryTable
                }
                .padding(32)
            }
        }
        .background(AppTheme.background)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Reports")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                
                Text("Analyze your spending patterns")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.top, 28)
        .padding(.bottom, 16)
    }
    
    // MARK: - Tab Bar
    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(ReportTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: iconForTab(tab))
                                .font(.system(size: 13))
                            Text(tab.rawValue)
                                .font(.system(size: 14, weight: selectedTab == tab ? .semibold : .medium))
                        }
                        .foregroundColor(selectedTab == tab ? AppTheme.textPrimary : AppTheme.textSecondary)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        
                        // Animated underline
                        Rectangle()
                            .fill(selectedTab == tab ? AppTheme.accentGradient : LinearGradient(colors: [Color.clear], startPoint: .leading, endPoint: .trailing))
                            .frame(height: 2)
                            .scaleEffect(x: selectedTab == tab ? 1 : 0)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 32)
        .background(
            VStack {
                Spacer()
                Rectangle()
                    .fill(AppTheme.border.opacity(0.3))
                    .frame(height: 1)
            }
        )
    }
    
    // MARK: - Period Navigator
    private var periodNavigator: some View {
        HStack {
            Button {
                navigatePeriod(by: -1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.surfaceElevated)
                    )
            }
            .buttonStyle(.plain)
            
            Spacer()
            
            Text(periodTitle)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            
            Spacer()
            
            Button {
                navigatePeriod(by: 1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 32, height: 32)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(AppTheme.surfaceElevated)
                    )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Summary Card
    private var summaryCard: some View {
        let filtered = filteredExpenses
        let total = filtered.reduce(0) { $0 + $1.amount }
        let count = filtered.count
        let avgPerExpense = count > 0 ? total / Double(count) : 0
        
        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "indianrupeesign.circle.fill")
                        .foregroundStyle(AppTheme.accentGradient)
                    Text("Total Spending")
                        .foregroundColor(AppTheme.textSecondary)
                }
                .font(.system(size: 13, weight: .medium))
                
                Text(formatCurrency(total))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .statCard(accent: AppTheme.accent)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "number.circle.fill")
                        .foregroundColor(AppTheme.accentSecondary)
                    Text("Transactions")
                        .foregroundColor(AppTheme.textSecondary)
                }
                .font(.system(size: 13, weight: .medium))
                
                Text("\(count)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .statCard(accent: AppTheme.accentSecondary)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: "divide.circle.fill")
                        .foregroundColor(AppTheme.warning)
                    Text("Avg / Transaction")
                        .foregroundColor(AppTheme.textSecondary)
                }
                .font(.system(size: 13, weight: .medium))
                
                Text(formatCurrency(avgPerExpense))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .statCard(accent: AppTheme.warning)
        }
    }
    
    // MARK: - Main Chart
    @ViewBuilder
    private var mainChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(mainChartTitle)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            let data = mainChartData
            
            if data.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(data, id: \.label) { item in
                    switch selectedTab {
                    case .monthly:
                        BarMark(
                            x: .value("Day", item.label),
                            y: .value("Amount", item.value)
                        )
                        .foregroundStyle(AppTheme.accentGradient)
                        .cornerRadius(4)
                        
                    case .quarterly:
                        BarMark(
                            x: .value("Month", item.label),
                            y: .value("Amount", item.value)
                        )
                        .foregroundStyle(AppTheme.accentGradient)
                        .cornerRadius(6)
                        
                    case .yearly:
                        LineMark(
                            x: .value("Month", item.label),
                            y: .value("Amount", item.value)
                        )
                        .foregroundStyle(AppTheme.accent)
                        .lineStyle(StrokeStyle(lineWidth: 3))
                        .interpolationMethod(.catmullRom)
                        .symbol {
                            Circle()
                                .fill(AppTheme.accent)
                                .frame(width: 8, height: 8)
                        }
                        
                        AreaMark(
                            x: .value("Month", item.label),
                            y: .value("Amount", item.value)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppTheme.accent.opacity(0.25), AppTheme.accent.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                            .foregroundStyle(AppTheme.border.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                            .foregroundStyle(AppTheme.border.opacity(0.2))
                        AxisValueLabel()
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .frame(height: 260)
            }
        }
        .glassCard()
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Category Pie Chart
    private var categoryPieChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By Category")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            let catData = categoryData()
            
            if catData.isEmpty {
                emptyChartPlaceholder
            } else {
                Chart(catData, id: \.name) { item in
                    SectorMark(
                        angle: .value("Amount", item.amount),
                        innerRadius: .ratio(0.55),
                        angularInset: 2
                    )
                    .foregroundStyle(item.color)
                    .cornerRadius(4)
                }
                .frame(height: 200)
                
                VStack(spacing: 6) {
                    ForEach(Array(catData.prefix(6).enumerated()), id: \.element.name) { _, item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 8, height: 8)
                            
                            Text(item.name)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Text(formatCurrency(item.amount))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                }
            }
        }
        .glassCard()
        .frame(width: 280)
    }
    
    // MARK: - Category Table
    private var categoryTable: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Breakdown")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            let catData = categoryData()
            let total = catData.reduce(0) { $0 + $1.amount }
            
            if catData.isEmpty {
                HStack {
                    Spacer()
                    Text("No expenses for this period")
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textMuted)
                        .padding(.vertical, 32)
                    Spacer()
                }
            } else {
                // Table Header
                HStack {
                    Text("CATEGORY")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("TRANSACTIONS")
                        .frame(width: 120, alignment: .trailing)
                    Text("AMOUNT")
                        .frame(width: 120, alignment: .trailing)
                    Text("% OF TOTAL")
                        .frame(width: 120, alignment: .trailing)
                }
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppTheme.textMuted)
                .padding(.bottom, 4)
                
                Divider().overlay(AppTheme.border.opacity(0.3))
                
                ForEach(catData, id: \.name) { item in
                    HStack {
                        HStack(spacing: 10) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(item.color.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                
                                Image(systemName: item.icon)
                                    .font(.system(size: 14))
                                    .foregroundColor(item.color)
                            }
                            
                            Text(item.name)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("\(item.count)")
                            .font(.system(size: 13))
                            .foregroundColor(AppTheme.textSecondary)
                            .frame(width: 120, alignment: .trailing)
                        
                        Text(formatCurrency(item.amount))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppTheme.textPrimary)
                            .frame(width: 120, alignment: .trailing)
                        
                        // Percentage Bar
                        HStack(spacing: 8) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(AppTheme.surfaceElevated)
                                        .frame(height: 6)
                                    
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(item.color)
                                        .frame(width: geo.size.width * CGFloat(total > 0 ? item.amount / total : 0), height: 6)
                                }
                                .frame(height: 6)
                                .offset(y: 10)
                            }
                            .frame(width: 60)
                            
                            Text(String(format: "%.0f%%", total > 0 ? (item.amount / total) * 100 : 0))
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        .frame(width: 120, alignment: .trailing)
                    }
                    .padding(.vertical, 6)
                    
                    Divider().overlay(AppTheme.border.opacity(0.1))
                }
            }
        }
        .glassCard()
    }
    
    // MARK: - Data Helpers
    private var filteredExpenses: [Expense] {
        let calendar = Calendar.current
        
        switch selectedTab {
        case .monthly:
            let comps = calendar.dateComponents([.year, .month], from: currentDate)
            guard let start = calendar.date(from: comps),
                  let end = calendar.date(byAdding: .month, value: 1, to: start) else { return [] }
            return allExpenses.filter { $0.date >= start && $0.date < end }
            
        case .quarterly:
            let month = calendar.component(.month, from: currentDate)
            let year = calendar.component(.year, from: currentDate)
            let quarterStartMonth = ((month - 1) / 3) * 3 + 1
            guard let start = calendar.date(from: DateComponents(year: year, month: quarterStartMonth)),
                  let end = calendar.date(byAdding: .month, value: 3, to: start) else { return [] }
            return allExpenses.filter { $0.date >= start && $0.date < end }
            
        case .yearly:
            let year = calendar.component(.year, from: currentDate)
            guard let start = calendar.date(from: DateComponents(year: year)),
                  let end = calendar.date(from: DateComponents(year: year + 1)) else { return [] }
            return allExpenses.filter { $0.date >= start && $0.date < end }
        }
    }
    
    struct ChartItem {
        let label: String
        let value: Double
    }
    
    private var mainChartData: [ChartItem] {
        let calendar = Calendar.current
        let filtered = filteredExpenses
        
        switch selectedTab {
        case .monthly:
            let comps = calendar.dateComponents([.year, .month], from: currentDate)
            guard let startOfMonth = calendar.date(from: comps),
                  let range = calendar.range(of: .day, in: .month, for: startOfMonth) else { return [] }
            
            return range.compactMap { day -> ChartItem? in
                guard let date = calendar.date(byAdding: .day, value: day - 1, to: startOfMonth) else { return nil }
                let total = filtered.filter { calendar.isDate($0.date, inSameDayAs: date) }
                    .reduce(0) { $0 + $1.amount }
                return ChartItem(label: "\(day)", value: total)
            }
            
        case .quarterly:
            let month = calendar.component(.month, from: currentDate)
            let year = calendar.component(.year, from: currentDate)
            let quarterStart = ((month - 1) / 3) * 3 + 1
            
            let monthNames = DateFormatter().shortMonthSymbols ?? []
            
            return (0..<3).compactMap { offset -> ChartItem? in
                let m = quarterStart + offset
                guard let start = calendar.date(from: DateComponents(year: year, month: m)),
                      let end = calendar.date(byAdding: .month, value: 1, to: start) else { return nil }
                let total = filtered.filter { $0.date >= start && $0.date < end }
                    .reduce(0) { $0 + $1.amount }
                let name = m <= monthNames.count ? monthNames[m - 1] : "M\(m)"
                return ChartItem(label: name, value: total)
            }
            
        case .yearly:
            let year = calendar.component(.year, from: currentDate)
            let monthNames = DateFormatter().shortMonthSymbols ?? []
            
            return (1...12).compactMap { month -> ChartItem? in
                guard let start = calendar.date(from: DateComponents(year: year, month: month)),
                      let end = calendar.date(byAdding: .month, value: 1, to: start) else { return nil }
                let total = filtered.filter { $0.date >= start && $0.date < end }
                    .reduce(0) { $0 + $1.amount }
                let name = month <= monthNames.count ? monthNames[month - 1] : "M\(month)"
                return ChartItem(label: name, value: total)
            }
        }
    }
    
    struct CategoryItem {
        let name: String
        let icon: String
        let color: Color
        let amount: Double
        let count: Int
    }
    
    private func categoryData() -> [CategoryItem] {
        let filtered = filteredExpenses
        let grouped = Dictionary(grouping: filtered) { $0.category?.name ?? "Other" }
        
        return grouped.map { (name, expenses) in
            let cat = categories.first { $0.name == name }
            return CategoryItem(
                name: name,
                icon: cat?.icon ?? "ellipsis.circle.fill",
                color: cat?.color ?? colorForName(name),
                amount: expenses.reduce(0) { $0 + $1.amount },
                count: expenses.count
            )
        }
        .sorted { $0.amount > $1.amount }
    }
    
    // MARK: - Navigation
    private var periodTitle: String {
        let calendar = Calendar.current
        let formatter = DateFormatter()
        
        switch selectedTab {
        case .monthly:
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: currentDate)
            
        case .quarterly:
            let month = calendar.component(.month, from: currentDate)
            let year = calendar.component(.year, from: currentDate)
            let quarter = (month - 1) / 3 + 1
            return "Q\(quarter) \(year)"
            
        case .yearly:
            formatter.dateFormat = "yyyy"
            return formatter.string(from: currentDate)
        }
    }
    
    private var mainChartTitle: String {
        switch selectedTab {
        case .monthly: return "Daily Spending"
        case .quarterly: return "Monthly Comparison"
        case .yearly: return "Monthly Trend"
        }
    }
    
    private func navigatePeriod(by direction: Int) {
        let calendar = Calendar.current
        withAnimation(.easeInOut(duration: 0.2)) {
            switch selectedTab {
            case .monthly:
                currentDate = calendar.date(byAdding: .month, value: direction, to: currentDate) ?? currentDate
            case .quarterly:
                currentDate = calendar.date(byAdding: .month, value: 3 * direction, to: currentDate) ?? currentDate
            case .yearly:
                currentDate = calendar.date(byAdding: .year, value: direction, to: currentDate) ?? currentDate
            }
        }
    }
    
    private func iconForTab(_ tab: ReportTab) -> String {
        switch tab {
        case .monthly: return "calendar"
        case .quarterly: return "calendar.badge.clock"
        case .yearly: return "chart.line.uptrend.xyaxis"
        }
    }
    
    // MARK: - Helpers
    private var emptyChartPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 30))
                .foregroundColor(AppTheme.textMuted)
            Text("No data for this period")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 200)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "₹\(Int(value))"
    }
    
    private func colorForName(_ name: String) -> Color {
        let index = abs(name.hashValue) % AppTheme.chartColors.count
        return AppTheme.chartColors[index]
    }
}
