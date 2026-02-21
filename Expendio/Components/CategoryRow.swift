import SwiftUI

struct CategoryRow: View {
    let name: String
    let color: Color
    let amount: String
    
    // We pass a custom horizontal padding to match the previous components exactly
    var horizontalPadding: CGFloat = 8
    var verticalPadding: CGFloat = 6
    var lineLimit: Int? = nil // Support ReportsCategoryRow's line limit
    
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Circle().fill(color).frame(width: 8, height: 8)
                Text(name)
                    .font(.system(size: 12))
                    .foregroundColor(AppTheme.textSecondary)
                    .lineLimit(lineLimit)
                Spacer()
                Text(amount).font(.system(size: 12, weight: .semibold)).foregroundColor(AppTheme.textPrimary)
            }
            .contentShape(Rectangle())
            .padding(.vertical, verticalPadding)
            .padding(.horizontal, horizontalPadding)
            .background(RoundedRectangle(cornerRadius: 6).fill(isHovered ? AppTheme.surfaceElevated : Color.clear))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
