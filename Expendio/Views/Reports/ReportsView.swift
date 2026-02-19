import SwiftUI
import SwiftData
import Charts

enum ReportTab: String, CaseIterable { case monthly = "Monthly"; case quarterly = "Quarterly"; case yearly = "Yearly" }

struct ReportsView: View {
    let profileId: UUID
    @Query private var allExpenses: [Expense]
    @Query private var categories: [ExpenseCategory]
    @State private var selectedTab: ReportTab = .monthly
    @State private var currentDate = Date()
    
    init(profileId: UUID) {
        self.profileId = profileId
        let pid = profileId
        _allExpenses = Query(filter: #Predicate<Expense> { $0.profileId == pid }, sort: \Expense.date, order: .reverse)
        _categories = Query(filter: #Predicate<ExpenseCategory> { $0.profileId == pid })
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Reports").font(.system(size: 28, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary)
                    Text("Analyze your spending patterns").font(.system(size: 13)).foregroundColor(AppTheme.textSecondary)
                }; Spacer()
            }.padding(.horizontal, 32).padding(.top, 28).padding(.bottom, 16)
            
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(ReportTab.allCases, id: \.self) { tab in
                    Button { withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { selectedTab = tab } } label: {
                        VStack(spacing: 8) {
                            HStack(spacing: 6) { Image(systemName: tabIcon(tab)).font(.system(size: 13)); Text(tab.rawValue).font(.system(size: 14, weight: selectedTab == tab ? .semibold : .medium)) }
                                .foregroundColor(selectedTab == tab ? AppTheme.textPrimary : AppTheme.textSecondary).padding(.horizontal, 20).padding(.vertical, 8)
                            Rectangle().fill(selectedTab == tab ? AppTheme.accent : Color.clear).frame(height: 2).scaleEffect(x: selectedTab == tab ? 1 : 0)
                        }
                    }.buttonStyle(.plain)
                }
            }.padding(.horizontal, 32).background(VStack { Spacer(); Rectangle().fill(AppTheme.border.opacity(0.3)).frame(height: 1) })
            
            ScrollView {
                VStack(spacing: 20) {
                    periodNavigator; summaryCard
                    HStack(alignment: .top, spacing: 20) { mainChart; categoryPieChart }.fixedSize(horizontal: false, vertical: true)
                    categoryTable
                }.padding(32)
            }
        }.background(AppTheme.background)
    }
    
    // MARK: - Period Nav
    private var periodNavigator: some View {
        HStack {
            Button { nav(-1) } label: { Image(systemName: "chevron.left").font(.system(size: 14, weight: .semibold)).foregroundColor(AppTheme.textSecondary).frame(width: 32, height: 32).background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.surfaceElevated)) }.buttonStyle(.plain)
            Spacer()
            Text(periodTitle).font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary)
            Spacer()
            Button { nav(1) } label: { Image(systemName: "chevron.right").font(.system(size: 14, weight: .semibold)).foregroundColor(AppTheme.textSecondary).frame(width: 32, height: 32).background(RoundedRectangle(cornerRadius: 8).fill(AppTheme.surfaceElevated)) }.buttonStyle(.plain)
        }
    }
    
    private var summaryCard: some View {
        let f = filtered; let total = f.reduce(0) { $0 + $1.amount }; let count = f.count; let avg = count > 0 ? total / Double(count) : 0
        return HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) { HStack(spacing: 6) { Image(systemName: "indianrupeesign.circle.fill").foregroundColor(AppTheme.accent); Text("Total Spending").foregroundColor(AppTheme.textSecondary) }.font(.system(size: 13, weight: .medium)); Text(fmt(total)).font(.system(size: 36, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary) }.statCard(accent: AppTheme.accent).frame(maxHeight: .infinity)
            VStack(alignment: .leading, spacing: 8) { HStack(spacing: 6) { Image(systemName: "number.circle.fill").foregroundColor(AppTheme.accentSecondary); Text("Transactions").foregroundColor(AppTheme.textSecondary) }.font(.system(size: 13, weight: .medium)); Text("\(count)").font(.system(size: 36, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary) }.statCard(accent: AppTheme.accentSecondary).frame(maxHeight: .infinity)
            VStack(alignment: .leading, spacing: 8) { HStack(spacing: 6) { Image(systemName: "divide.circle.fill").foregroundColor(AppTheme.warning); Text("Avg / Transaction").foregroundColor(AppTheme.textSecondary) }.font(.system(size: 13, weight: .medium)); Text(fmt(avg)).font(.system(size: 36, weight: .bold, design: .rounded)).foregroundColor(AppTheme.textPrimary) }.statCard(accent: AppTheme.warning).frame(maxHeight: .infinity)
        }.fixedSize(horizontal: false, vertical: true)
    }
    
    // MARK: - Charts
    @ViewBuilder private var mainChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(chartTitle).font(.system(size: 16, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
            let data = chartData
            if data.isEmpty { empty } else {
                Chart(data, id: \.label) { item in
                    switch selectedTab {
                    case .monthly: BarMark(x: .value("Day", item.label), y: .value("Amount", item.value)).foregroundStyle(AppTheme.accent).cornerRadius(4)
                    case .quarterly: BarMark(x: .value("Month", item.label), y: .value("Amount", item.value)).foregroundStyle(AppTheme.accent).cornerRadius(6)
                    case .yearly:
                        LineMark(x: .value("Month", item.label), y: .value("Amount", item.value)).foregroundStyle(AppTheme.accent).lineStyle(StrokeStyle(lineWidth: 3)).interpolationMethod(.catmullRom).symbol { Circle().fill(AppTheme.accent).frame(width: 8, height: 8) }
                        AreaMark(x: .value("Month", item.label), y: .value("Amount", item.value)).foregroundStyle(AppTheme.accent.opacity(0.12)).interpolationMethod(.catmullRom)
                    }
                }
                .chartXAxis { AxisMarks { _ in AxisGridLine().foregroundStyle(AppTheme.border.opacity(0.3)); AxisValueLabel().foregroundStyle(AppTheme.textSecondary) } }
                .chartYAxis { AxisMarks { _ in AxisGridLine().foregroundStyle(AppTheme.border.opacity(0.2)); AxisValueLabel().foregroundStyle(AppTheme.textSecondary) } }
                .frame(minHeight: 220, maxHeight: .infinity)
            }
        }.glassCard().frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var categoryPieChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("By Category").font(.system(size: 16, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
            let cd = catData()
            if cd.isEmpty { empty } else {
                Chart(cd, id: \.name) { item in SectorMark(angle: .value("Amount", item.amount), innerRadius: .ratio(0.55), angularInset: 2).foregroundStyle(item.color).cornerRadius(4) }.frame(minHeight: 180)
                Spacer(minLength: 0)
                VStack(spacing: 6) { ForEach(Array(cd.prefix(6).enumerated()), id: \.element.name) { _, item in HStack(spacing: 8) { Circle().fill(item.color).frame(width: 8, height: 8); Text(item.name).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary).lineLimit(1); Spacer(); Text(fmt(item.amount)).font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.textPrimary) } } }
            }
        }.glassCard().frame(width: 280).frame(maxHeight: .infinity)
    }
    
    // MARK: - Category Table
    private var categoryTable: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Category Breakdown").font(.system(size: 16, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
            let cd = catData(); let total = cd.reduce(0) { $0 + $1.amount }
            if cd.isEmpty { HStack { Spacer(); Text("No expenses for this period").font(.system(size: 14)).foregroundColor(AppTheme.textMuted).padding(.vertical, 32); Spacer() } }
            else {
                HStack { Text("CATEGORY").frame(maxWidth: .infinity, alignment: .leading); Text("COUNT").frame(width: 100, alignment: .trailing); Text("AMOUNT").frame(width: 120, alignment: .trailing); Text("% OF TOTAL").frame(width: 120, alignment: .trailing) }.font(.system(size: 11, weight: .semibold)).foregroundColor(AppTheme.textMuted).padding(.bottom, 4)
                Divider().overlay(AppTheme.border.opacity(0.3))
                ForEach(cd, id: \.name) { item in
                    HStack {
                        HStack(spacing: 10) { ZStack { RoundedRectangle(cornerRadius: 8).fill(item.color.opacity(0.15)).frame(width: 32, height: 32); Image(systemName: item.icon).font(.system(size: 14)).foregroundColor(item.color) }; Text(item.name).font(.system(size: 13, weight: .medium)).foregroundColor(AppTheme.textPrimary) }.frame(maxWidth: .infinity, alignment: .leading)
                        Text("\(item.count)").font(.system(size: 13)).foregroundColor(AppTheme.textSecondary).frame(width: 100, alignment: .trailing)
                        Text(fmt(item.amount)).font(.system(size: 13, weight: .semibold)).foregroundColor(AppTheme.textPrimary).frame(width: 120, alignment: .trailing)
                        HStack(spacing: 8) {
                            GeometryReader { geo in ZStack(alignment: .leading) { RoundedRectangle(cornerRadius: 3).fill(AppTheme.surfaceElevated).frame(height: 6); RoundedRectangle(cornerRadius: 3).fill(item.color).frame(width: geo.size.width * CGFloat(total > 0 ? item.amount / total : 0), height: 6) }.frame(height: 6).offset(y: 10) }.frame(width: 60)
                            Text(String(format: "%.0f%%", total > 0 ? (item.amount / total) * 100 : 0)).font(.system(size: 12)).foregroundColor(AppTheme.textSecondary)
                        }.frame(width: 120, alignment: .trailing)
                    }.padding(.vertical, 6)
                    Divider().overlay(AppTheme.border.opacity(0.1))
                }
            }
        }.glassCard()
    }
    
    // MARK: - Data
    private var filtered: [Expense] {
        let c = Calendar.current
        switch selectedTab {
        case .monthly:
            let comps = c.dateComponents([.year, .month], from: currentDate)
            guard let s = c.date(from: comps), let e = c.date(byAdding: .month, value: 1, to: s) else { return [] }
            return allExpenses.filter { $0.date >= s && $0.date < e }
        case .quarterly:
            let m = c.component(.month, from: currentDate); let y = c.component(.year, from: currentDate); let qs = ((m - 1) / 3) * 3 + 1
            guard let s = c.date(from: DateComponents(year: y, month: qs)), let e = c.date(byAdding: .month, value: 3, to: s) else { return [] }
            return allExpenses.filter { $0.date >= s && $0.date < e }
        case .yearly:
            let y = c.component(.year, from: currentDate)
            guard let s = c.date(from: DateComponents(year: y)), let e = c.date(from: DateComponents(year: y + 1)) else { return [] }
            return allExpenses.filter { $0.date >= s && $0.date < e }
        }
    }
    
    struct CI { let label: String; let value: Double }
    private var chartData: [CI] {
        let c = Calendar.current; let f = filtered
        switch selectedTab {
        case .monthly:
            let comps = c.dateComponents([.year, .month], from: currentDate)
            guard let som = c.date(from: comps), let range = c.range(of: .day, in: .month, for: som) else { return [] }
            return range.compactMap { d -> CI? in guard let date = c.date(byAdding: .day, value: d - 1, to: som) else { return nil }; return CI(label: "\(d)", value: f.filter { c.isDate($0.date, inSameDayAs: date) }.reduce(0) { $0 + $1.amount }) }
        case .quarterly:
            let m = c.component(.month, from: currentDate); let y = c.component(.year, from: currentDate); let qs = ((m - 1) / 3) * 3 + 1; let mn = DateFormatter().shortMonthSymbols ?? []
            return (0..<3).compactMap { o -> CI? in let m2 = qs + o; guard let s = c.date(from: DateComponents(year: y, month: m2)), let e = c.date(byAdding: .month, value: 1, to: s) else { return nil }; return CI(label: m2 <= mn.count ? mn[m2-1] : "M\(m2)", value: f.filter { $0.date >= s && $0.date < e }.reduce(0) { $0 + $1.amount }) }
        case .yearly:
            let y = c.component(.year, from: currentDate); let mn = DateFormatter().shortMonthSymbols ?? []
            return (1...12).compactMap { m -> CI? in guard let s = c.date(from: DateComponents(year: y, month: m)), let e = c.date(byAdding: .month, value: 1, to: s) else { return nil }; return CI(label: m <= mn.count ? mn[m-1] : "M\(m)", value: f.filter { $0.date >= s && $0.date < e }.reduce(0) { $0 + $1.amount }) }
        }
    }
    
    struct CatItem { let name: String; let icon: String; let color: Color; let amount: Double; let count: Int }
    private func catData() -> [CatItem] {
        Dictionary(grouping: filtered) { $0.category?.name ?? "Other" }.map { (name, exps) in let cat = categories.first { $0.name == name }; return CatItem(name: name, icon: cat?.icon ?? "ellipsis.circle.fill", color: cat?.color ?? AppTheme.chartColors[abs(name.hashValue) % AppTheme.chartColors.count], amount: exps.reduce(0) { $0 + $1.amount }, count: exps.count) }.sorted { $0.amount > $1.amount }
    }
    
    private var periodTitle: String { let c = Calendar.current; let f = DateFormatter(); switch selectedTab { case .monthly: f.dateFormat = "MMMM yyyy"; return f.string(from: currentDate); case .quarterly: let m = c.component(.month, from: currentDate); let y = c.component(.year, from: currentDate); return "Q\((m-1)/3+1) \(y)"; case .yearly: f.dateFormat = "yyyy"; return f.string(from: currentDate) } }
    private var chartTitle: String { switch selectedTab { case .monthly: return "Daily Spending"; case .quarterly: return "Monthly Comparison"; case .yearly: return "Monthly Trend" } }
    private func nav(_ d: Int) { let c = Calendar.current; withAnimation { switch selectedTab { case .monthly: currentDate = c.date(byAdding: .month, value: d, to: currentDate) ?? currentDate; case .quarterly: currentDate = c.date(byAdding: .month, value: 3*d, to: currentDate) ?? currentDate; case .yearly: currentDate = c.date(byAdding: .year, value: d, to: currentDate) ?? currentDate } } }
    private func tabIcon(_ t: ReportTab) -> String { switch t { case .monthly: return "calendar"; case .quarterly: return "calendar.badge.clock"; case .yearly: return "chart.line.uptrend.xyaxis" } }
    private var empty: some View { VStack(spacing: 12) { Image(systemName: "chart.bar.xaxis").font(.system(size: 30)).foregroundColor(AppTheme.textMuted); Text("No data for this period").font(.system(size: 13)).foregroundColor(AppTheme.textSecondary) }.frame(maxWidth: .infinity).frame(height: 200) }
    private func fmt(_ v: Double) -> String { let f = NumberFormatter(); f.numberStyle = .currency; f.currencyCode = "INR"; f.maximumFractionDigits = 0; return f.string(from: NSNumber(value: v)) ?? "₹\(Int(v))" }
}
