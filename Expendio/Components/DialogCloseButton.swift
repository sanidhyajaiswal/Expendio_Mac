import SwiftUI

struct DialogCloseButton: View {
    let action: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button { action() } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(isHovered ? AppTheme.danger : AppTheme.textMuted)
                .background(Circle().fill(isHovered ? AppTheme.danger.opacity(0.15) : Color.clear))
        }
        .buttonStyle(.plain)
        .onHover { h in withAnimation(.easeInOut(duration: 0.1)) { isHovered = h } }
    }
}
