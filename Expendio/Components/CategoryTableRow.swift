import SwiftUI

// Based on ReportsView.CatItem but decoupled
struct CategoryTableItem {
    let name: String
    let icon: String
    let color: Color
    let amount: Double
    let count: Int
}

struct CategoryTableRow: View {
    // Decoupled from ReportsView
    let name: String
    let icon: String
    let color: Color
    let count: Int
    let amount: Double
    let total: Double
    let amountString: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack {
                HStack(spacing: 10) { 
                    ZStack { 
                        RoundedRectangle(cornerRadius: 8)
                            .fill(color.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: icon)
                            .font(.system(size: 14))
                            .foregroundColor(color) 
                    }
                    Text(name)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppTheme.textPrimary) 
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("\(count)")
                    .font(.system(size: 13))
                    .foregroundColor(AppTheme.textSecondary)
                    .frame(width: 100, alignment: .trailing)
                
                Text(amountString)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppTheme.textPrimary)
                    .frame(width: 120, alignment: .trailing)
                
                HStack(spacing: 8) {
                    GeometryReader { geo in 
                        ZStack(alignment: .leading) { 
                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppTheme.surfaceElevated)
                                .frame(height: 6)
                            RoundedRectangle(cornerRadius: 3)
                                .fill(color)
                                .frame(width: geo.size.width * CGFloat(total > 0 ? amount / total : 0), height: 6) 
                        }
                        .frame(height: 6)
                        .offset(y: 10) 
                    }
                    .frame(width: 60)
                    
                    Text(String(format: "%.0f%%", total > 0 ? (amount / total) * 100 : 0))
                        .font(.system(size: 12))
                        .foregroundColor(AppTheme.textSecondary)
                }
                .frame(width: 120, alignment: .trailing)
            }
            .contentShape(Rectangle())
            .padding(.vertical, 4).padding(.horizontal, 8)
            .background(RoundedRectangle(cornerRadius: 8).fill(isHovered ? AppTheme.surfaceElevated : Color.clear))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
