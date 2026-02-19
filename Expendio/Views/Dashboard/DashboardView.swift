import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    @Query(sort: \Expense.date, order: .reverse) private var allExpenses: [Expense]
    @Query private var categories: [ExpenseCategory]
    
    private var currentMonthExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        return allExpenses.filter { $0.date >= startOfMonth }
    }
    
    private var totalThisMonth: Double {
        currentMonthExpenses.reduce(0) { $0 + $1.amount }
    }
    
    private var dailyAverage: Double {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: Date())
        return day > 0 ? totalThisMonth / Double(day) : 0
    }
    
    private var topCategory: (String, Double)? {
        let grouped = Dictionary(grouping: currentMonthExpenses) { $0.category?.name ?? "Other" }
        let totals = grouped.mapValues { $0.reduce(0) { $0 + $1.amount } }
        return totals.max(by: { $0.value < $1.value })
    }
    
    private var last30DaysData: [(Date, Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return (0..<30).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let dayExpenses = allExpenses.filter { calendar.isDate($0.date, inSameDayAs: date) }
            let total = dayExpenses.reduce(0) { $0 + $1.amount }
            return (date, total)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                // Stat Cards
                statsGrid
                
                // Charts Row
                HStack(alignment: .top, spacing: 20) {
                    // Spending Trend
                    spendingTrendChart
                    
                    // Category Breakdown
                    categoryBreakdown
                }
                
                // Recent Expenses
                recentExpensesSection
            }
            .padding(32)
        }
        .background(AppTheme.background)
    }
    
    // MARK: - Header
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Dashboard")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(AppTheme.textPrimary)
            
            Text(Date(), format: .dateTime.month(.wide).day().year())
                .font(.system(size: 14))
                .foregroundColor(AppTheme.textSecondary)
        }
    }
    
    // MARK: - Stats Grid
    private var statsGrid: some View {
        HStack(spacing: 16) {
            // Total This Month
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "indianrupeesign.circle.fill")
                        .foregroundStyle(AppTheme.accentGradient)
                    Text("This Month")
                        .foregroundColor(AppTheme.textSecondary)
                }
                .font(.system(size: 13, weight: .medium))
                
                Text(formatCurrency(totalThisMonth))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .statCard(accent: AppTheme.accent)
            
            // Daily Average
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .foregroundColor(AppTheme.accentSecondary)
                    Text("Daily Average")
                        .foregroundColor(AppTheme.textSecondary)
                }
                .font(.system(size: 13, weight: .medium))
                
                Text(formatCurrency(dailyAverage))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .statCard(accent: AppTheme.accentSecondary)
            
            // Top Category
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "flame.fill")
                        .foregroundColor(AppTheme.warning)
                    Text("Top Category")
                        .foregroundColor(AppTheme.textSecondary)
                }
                .font(.system(size: 13, weight: .medium))
                
                Text(topCategory?.0 ?? "—")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
                
                if let top = topCategory {
                    Text(formatCurrency(top.1))
                        .font(.system(size: 14))
                        .foregroundColor(AppTheme.textSecondary)
                }
            }
            .statCard(accent: AppTheme.warning)
            
            // Total Expenses Count
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Image(systemName: "number.circle.fill")
                        .foregroundColor(AppTheme.success)
                    Text("Transactions")
                        .foregroundColor(AppTheme.textSecondary)
                }
                .font(.system(size: 13, weight: .medium))
                
                Text("\(currentMonthExpenses.count)")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(AppTheme.textPrimary)
            }
            .statCard(accent: AppTheme.success)
        }
    }
    
    // MARK: - Spending Trend
    private var spendingTrendChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trend (30 days)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            if last30DaysData.contains(where: { $0.1 > 0 }) {
                Chart(last30DaysData, id: \.0) { item in
                    AreaMark(
                        x: .value("Date", item.0),
                        y: .value("Amount", item.1)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppTheme.accent.opacity(0.3), AppTheme.accent.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)
                    
                    LineMark(
                        x: .value("Date", item.0),
                        y: .value("Amount", item.1)
                    )
                    .foregroundStyle(AppTheme.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                        AxisGridLine()
                            .foregroundStyle(AppTheme.border.opacity(0.3))
                        AxisValueLabel(format: .dateTime.day().month(.abbreviated))
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                            .foregroundStyle(AppTheme.border.opacity(0.3))
                        AxisValueLabel()
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .frame(height: 220)
            } else {
                emptyChartPlaceholder
            }
        }
        .glassCard()
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - Category Breakdown
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Split")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppTheme.textPrimary)
            
            let grouped = Dictionary(grouping: currentMonthExpenses) { $0.category?.name ?? "Other" }
            let totals = grouped.mapValues { $0.reduce(0) { $0 + $1.amount } }
                .sorted { $0.value > $1.value }
            
            if !totals.isEmpty {
                Chart(totals, id: \.key) { item in
                    SectorMark(
                        angle: .value("Amount", item.value),
                        innerRadius: .ratio(0.6),
                        angularInset: 2
                    )
                    .foregroundStyle(colorForCategory(item.key))
                    .cornerRadius(4)
                }
                .frame(height: 180)
                
                VStack(spacing: 8) {
                    ForEach(Array(totals.prefix(5).enumerated()), id: \.element.key) { index, item in
                        HStack(spacing: 8) {
                            Circle()
                                .fill(colorForCategory(item.key))
                                .frame(width: 8, height: 8)
                            
                            Text(item.key)
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                            
                            Spacer()
                            
                            Text(formatCurrency(item.value))
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppTheme.textPrimary)
                        }
                    }
                }
            } else {
                emptyChartPlaceholder
            }
        }
        .glassCard()
        .frame(width: 300)
    }
    
    // MARK: - Recent Expenses
    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Expenses")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                
                Spacer()
                
                Text("\(allExpenses.count) total")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textMuted)
            }
            
            if allExpenses.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 36))
                            .foregroundColor(AppTheme.textMuted)
                        Text("No expenses yet")
                            .font(.system(size: 14))
                            .foregroundColor(AppTheme.textSecondary)
                    }
                    .padding(.vertical, 40)
                    Spacer()
                }
            } else {
                ForEach(Array(allExpenses.prefix(8)), id: \.id) { expense in
                    HStack(spacing: 14) {
                        // Category icon
                        ZStack {
                            RoundedRectangle(cornerRadius: 10)
                                .fill((expense.category?.color ?? AppTheme.textMuted).opacity(0.15))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: expense.category?.icon ?? "questionmark.circle")
                                .font(.system(size: 16))
                                .foregroundColor(expense.category?.color ?? AppTheme.textMuted)
                        }
                        
                        VStack(alignment: .leading, spacing: 3) {
                            Text(expense.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(AppTheme.textPrimary)
                            
                            Text(expense.category?.name ?? "Uncategorized")
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textSecondary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 3) {
                            Text(expense.formattedAmount)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppTheme.danger)
                            
                            Text(expense.date, format: .dateTime.month(.abbreviated).day())
                                .font(.system(size: 12))
                                .foregroundColor(AppTheme.textMuted)
                        }
                    }
                    .padding(.vertical, 4)
                    
                    if expense.id != allExpenses.prefix(8).last?.id {
                        Divider().overlay(AppTheme.border.opacity(0.3))
                    }
                }
            }
        }
        .glassCard()
    }
    
    // MARK: - Helpers
    private var emptyChartPlaceholder: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.bar.xaxis")
                .font(.system(size: 30))
                .foregroundColor(AppTheme.textMuted)
            Text("No data yet")
                .font(.system(size: 13))
                .foregroundColor(AppTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "INR"
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "₹\(Int(value))"
    }
    
    private func colorForCategory(_ name: String) -> Color {
        if let cat = categories.first(where: { $0.name == name }) {
            return cat.color
        }
        let index = abs(name.hashValue) % AppTheme.chartColors.count
        return AppTheme.chartColors[index]
    }
}
