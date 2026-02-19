import SwiftUI

// MARK: - Color Palette
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - App Theme
struct AppTheme {
    // Backgrounds
    static let background = Color(hex: "0D1117")
    static let surface = Color(hex: "161B22")
    static let surfaceElevated = Color(hex: "21262D")
    static let border = Color(hex: "30363D")
    
    // Accents
    static let accent = Color(hex: "7C3AED")
    static let accentSecondary = Color(hex: "06B6D4")
    static let accentTertiary = Color(hex: "8B5CF6")
    
    // Text
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "8B949E")
    static let textMuted = Color(hex: "484F58")
    
    // Semantic
    static let success = Color(hex: "3FB950")
    static let warning = Color(hex: "D29922")
    static let danger = Color(hex: "F85149")
    
    // Gradients
    static let accentGradient = LinearGradient(
        colors: [Color(hex: "7C3AED"), Color(hex: "06B6D4")],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let subtleGradient = LinearGradient(
        colors: [Color(hex: "7C3AED").opacity(0.15), Color(hex: "06B6D4").opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let cardGradient = LinearGradient(
        colors: [surface.opacity(0.9), surfaceElevated.opacity(0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Category chart colors
    static let chartColors: [Color] = [
        Color(hex: "FF6B6B"), Color(hex: "4ECDC4"), Color(hex: "A78BFA"),
        Color(hex: "F59E0B"), Color(hex: "3B82F6"), Color(hex: "EC4899"),
        Color(hex: "8B5CF6"), Color(hex: "10B981"), Color(hex: "F97316"),
        Color(hex: "6366F1"), Color(hex: "14B8A6"), Color(hex: "6B7280"),
    ]
}

// MARK: - View Modifiers
struct GlassCard: ViewModifier {
    var padding: CGFloat = 20
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.surface.opacity(0.7))
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(AppTheme.border.opacity(0.5), lineWidth: 1)
            )
    }
}

struct GradientButton: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppTheme.accentGradient)
            )
            .shadow(color: AppTheme.accent.opacity(0.3), radius: 8, y: 4)
    }
}

struct StatCard: ViewModifier {
    let accentColor: Color
    
    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(AppTheme.surface.opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [accentColor.opacity(0.08), Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(accentColor.opacity(0.2), lineWidth: 1)
            )
    }
}

// MARK: - View Extensions
extension View {
    func glassCard(padding: CGFloat = 20) -> some View {
        modifier(GlassCard(padding: padding))
    }
    
    func gradientButton() -> some View {
        modifier(GradientButton())
    }
    
    func statCard(accent: Color = AppTheme.accent) -> some View {
        modifier(StatCard(accentColor: accent))
    }
}
