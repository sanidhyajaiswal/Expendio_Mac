import SwiftUI

struct PanelActionButton: View {
    let icon: String
    let label: String
    var destructive: Bool = false
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        let tint = destructive ? AppTheme.danger : AppTheme.textSecondary
        Button { action() } label: {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundColor(tint)
                    .frame(width: 18)
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(destructive ? AppTheme.danger : AppTheme.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? AppTheme.textMuted.opacity(0.15) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 4)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
}
