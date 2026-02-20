import SwiftUI
import SwiftData
import Charts

struct DashboardView: View {
    let profileId: UUID
    @Query private var allExpenses: [Expense]
    @Query private var categories: [ExpenseCategory]
    @Environment(\.themeAccent) private var themeAccent
    
    init(profileId: UUID) {
        self.profileId = profileId
        let pid = profileId
        _allExpenses = Query(filter: #Predicate<Expense> { $0.profileId == pid }, sort: \Expense.date, order: .reverse)
        _categories = Query(filter: #Predicate<ExpenseCategory> { $0.profileId == pid })
    }
    
    private var currentMonthExpenses: [Expense] {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        return allExpenses.filter { $0.date >= startOfMonth }
    }
    
    private var totalThisMonth: Double { currentMonthExpenses.reduce(0) { $0 + $1.amount } }
    
    private var dailyAverage: Double {
        let day = Calendar.current.component(.day, from: Date())
        return day > 0 ? totalThisMonth / Double(day) : 0
    }
    
    private var topCategory: (String, Double)? {
        let grouped = Dictionary(grouping: currentMonthExpenses) { $0.category?.name ?? "Other" }
        return grouped.mapValues { $0.reduce(0) { $0 + $1.amount } }.max(by: { $0.value < $1.value })
    }
    
    private var last30DaysData: [(Date, Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<30).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: today) else { return nil }
            let total = allExpenses.filter { calendar.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.amount }
            return (date, total)
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                statsGrid
                HStack(alignment: .top, spacing: 16) { spendingTrendChart; categoryBreakdown }.fixedSize(horizontal: false, vertical: true)
                recentExpensesSection
            }
            .padding(24)
            .frame(maxWidth: .infinity) // Ensures responsiveness inside ScrollView
        }
        .background(AppTheme.dynamicBackground)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Dashboard").font(.system(size: 28, weight: .bold)).foregroundColor(AppTheme.textPrimary)
            Text(Date(), format: .dateTime.month(.wide).day().year()).font(.system(size: 14)).foregroundColor(AppTheme.textSecondary)
        }
    }
    
    private var statsGrid: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                HStack { Image(systemName: "indianrupeesign.circle.fill").foregroundColor(themeAccent); Text("This Month").foregroundColor(AppTheme.textSecondary) }.font(.system(size: 13, weight: .medium))
                Text(fmt(totalThisMonth)).font(.system(size: 32, weight: .bold)).foregroundColor(AppTheme.textPrimary)
            }.statCard(accent: themeAccent).frame(maxHeight: .infinity)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack { Image(systemName: "chart.line.uptrend.xyaxis").foregroundColor(AppTheme.accentSecondary); Text("Daily Average").foregroundColor(AppTheme.textSecondary) }.font(.system(size: 13, weight: .medium))
                Text(fmt(dailyAverage)).font(.system(size: 32, weight: .bold)).foregroundColor(AppTheme.textPrimary)
            }.statCard(accent: AppTheme.accentSecondary).frame(maxHeight: .infinity)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack { Image(systemName: "flame.fill").foregroundColor(AppTheme.warning); Text("Top Category").foregroundColor(AppTheme.textSecondary) }.font(.system(size: 13, weight: .medium))
                HStack(alignment: .firstTextBaseline) {
                    Text(topCategory?.0 ?? "—").font(.system(size: 32, weight: .bold)).foregroundColor(AppTheme.textPrimary).lineLimit(1).minimumScaleFactor(0.5)
                    Spacer()
                    if let top = topCategory { Text(fmt(top.1)).font(.system(size: 14, weight: .semibold)).foregroundColor(AppTheme.textSecondary) }
                }
            }.statCard(accent: AppTheme.warning).frame(maxHeight: .infinity)
            
            VStack(alignment: .leading, spacing: 10) {
                HStack { Image(systemName: "number.circle.fill").foregroundColor(AppTheme.success); Text("Transactions").foregroundColor(AppTheme.textSecondary) }.font(.system(size: 13, weight: .medium))
                Text("\(currentMonthExpenses.count)").font(.system(size: 32, weight: .bold)).foregroundColor(AppTheme.textPrimary)
            }.statCard(accent: AppTheme.success).frame(maxHeight: .infinity)
        }.frame(maxWidth: .infinity) // Added to allow horizontal stretch
        .fixedSize(horizontal: false, vertical: true)
    }
    
    private var spendingTrendChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Spending Trend (30 days)").font(.system(size: 16, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
            if last30DaysData.contains(where: { $0.1 > 0 }) {
                Chart(last30DaysData, id: \.0) { item in
                    AreaMark(x: .value("Date", item.0), y: .value("Amount", item.1))
                        .foregroundStyle(themeAccent.opacity(0.15)).interpolationMethod(.catmullRom)
                    LineMark(x: .value("Date", item.0), y: .value("Amount", item.1))
                        .foregroundStyle(themeAccent).lineStyle(StrokeStyle(lineWidth: 2)).interpolationMethod(.catmullRom)
                }
                .chartXAxis { AxisMarks(values: .stride(by: .day, count: 7)) { _ in AxisValueLabel(format: .dateTime.day().month(.abbreviated)).foregroundStyle(AppTheme.textSecondary) } }
                .chartYAxis { AxisMarks { _ in AxisValueLabel().foregroundStyle(AppTheme.textSecondary) } }
            } else { emptyChart }
        }.glassCard().frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var categoryBreakdown: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Split").font(.system(size: 16, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
            let totals = Dictionary(grouping: currentMonthExpenses) { $0.category?.name ?? "Other" }
                .mapValues { $0.reduce(0) { $0 + $1.amount } }.sorted { $0.value > $1.value }
            if !totals.isEmpty {
                Chart(totals, id: \.key) { item in
                    SectorMark(angle: .value("Amount", item.value), innerRadius: .ratio(0.6), angularInset: 2)
                        .foregroundStyle(colorFor(item.key)).cornerRadius(4)
                }.frame(height: 180)
                VStack(spacing: 8) {
                    ForEach(Array(totals.prefix(5).enumerated()), id: \.element.key) { _, item in
                        HStack(spacing: 8) {
                            Circle().fill(colorFor(item.key)).frame(width: 8, height: 8)
                            Text(item.key).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                            Spacer()
                            Text(fmt(item.value)).font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
                        }
                    }
                }
            } else { emptyChart }
        }.glassCard().frame(width: 250).frame(maxHeight: .infinity) // Make width more responsive
    }
    
    private var recentExpensesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack { Text("Recent Expenses").font(.system(size: 16, weight: .semibold)).foregroundColor(AppTheme.textPrimary); Spacer(); Text("\(allExpenses.count) total").font(.system(size: 13)).foregroundColor(AppTheme.textMuted) }
            if allExpenses.isEmpty {
                HStack { Spacer(); VStack(spacing: 12) { Image(systemName: "tray").font(.system(size: 36)).foregroundColor(AppTheme.textMuted); Text("No expenses yet").font(.system(size: 14)).foregroundColor(AppTheme.textSecondary) }.padding(.vertical, 40); Spacer() }
            } else {
                ForEach(Array(allExpenses.prefix(8)), id: \.id) { expense in
                    HStack(spacing: 14) {
                        ZStack { RoundedRectangle(cornerRadius: 10).fill((expense.category?.color ?? AppTheme.textMuted).opacity(0.15)).frame(width: 40, height: 40); Image(systemName: expense.category?.icon ?? "questionmark.circle").font(.system(size: 16)).foregroundColor(expense.category?.color ?? AppTheme.textMuted) }
                        VStack(alignment: .leading, spacing: 3) { Text(expense.title).font(.system(size: 14, weight: .medium)).foregroundColor(AppTheme.textPrimary); Text(expense.category?.name ?? "Uncategorized").font(.system(size: 12)).foregroundColor(AppTheme.textSecondary) }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 3) { Text(expense.formattedAmount).font(.system(size: 14, weight: .semibold)).foregroundColor(AppTheme.danger); Text(expense.date, format: .dateTime.month(.abbreviated).day()).font(.system(size: 12)).foregroundColor(AppTheme.textMuted) }
                    }.padding(.vertical, 8)
                }
            }
        }.glassCard()
    }
    
    private var emptyChart: some View {
        VStack(spacing: 12) { Image(systemName: "chart.bar.xaxis").font(.system(size: 30)).foregroundColor(AppTheme.textMuted); Text("No data yet").font(.system(size: 13)).foregroundColor(AppTheme.textSecondary) }.frame(maxWidth: .infinity).frame(height: 180)
    }
    
    private func fmt(_ v: Double) -> String { let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = "INR"; f.maximumFractionDigits = 0; return f.string(from: NSNumber(value: v)) ?? "₹\(Int(v))" }
    
    private func colorFor(_ name: String) -> Color {
        categories.first(where: { $0.name == name })?.color ?? AppTheme.chartColors[abs(name.hashValue) % AppTheme.chartColors.count]
    }
}
