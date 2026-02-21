import SwiftUI

struct ProfileSwitcherButton: View {
    let profile: Profile
    let isActive: Bool
    let themeAccent: Color
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button { action() } label: {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(Color(hex: profile.colorHex).opacity(0.2)).frame(width: 26, height: 26)
                    Text(String(profile.name.prefix(1)).uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: profile.colorHex))
                }
                Text(profile.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.textPrimary)
                Spacer()
                if isActive {
                    Image(systemName: "checkmark")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(themeAccent)
                }
            }
            .padding(.horizontal, 12).padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isActive ? themeAccent.opacity(0.1) : (isHovered ? AppTheme.textMuted.opacity(0.15) : Color.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.1)) {
                isHovered = hovering
            }
        }
    }
}
