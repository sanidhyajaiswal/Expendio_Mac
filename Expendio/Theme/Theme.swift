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
    // Backgrounds - Notion uses pure white for light, very dark gray for dark
    static let background = Color("BackgroundColor") // Need to define in Assets or fallback properly, but let's use dynamic color
    static let surface = Color("SurfaceColor")
    static let surfaceElevated = Color("SurfaceElevatedColor")
    static let border = Color(hex: "E0E0E0") // Light border, we'll fake dynamic locally if needed, but for now flat is fine or systemGray
    
    // We can use standard semantic system colors for dynamic light/dark
    static var dynamicBackground: Color { Color(NSColor.underPageBackgroundColor) } // Darker background
    static var dynamicSurface: Color { Color(NSColor.windowBackgroundColor) }
    static var dynamicSurfaceElevated: Color { Color(NSColor.controlBackgroundColor) }
    static var dynamicBorder: Color { Color(NSColor.separatorColor).opacity(0.3) } // Softer borders
    
    // Accents
    static let accent = Color(hex: "7C3AED") // Let's keep the user's primary choices
    static let accentSecondary = Color(hex: "06B6D4")
    static let accentTertiary = Color(hex: "8B5CF6")
    
    // Text
    static let textPrimary = Color(NSColor.labelColor)
    static let textSecondary = Color(NSColor.secondaryLabelColor)
    static let textMuted = Color(NSColor.tertiaryLabelColor)
    
    // Semantic
    static let success = Color(NSColor.systemGreen)
    static let warning = Color(NSColor.systemYellow)
    static let danger = Color(NSColor.systemRed)
    
    // Category chart colors (Flatter, slightly muted like Notion)
    static let chartColors: [Color] = [
        Color(hex: "E05252"), Color(hex: "0BA376"), Color(hex: "8B5CF6"),
        Color(hex: "E59500"), Color(hex: "2563EB"), Color(hex: "D946EF"),
        Color(hex: "7C3AED"), Color(hex: "059669"), Color(hex: "EA580C"),
        Color(hex: "4F46E5"), Color(hex: "0D9488"), Color(hex: "4B5563"),
    ]
}

// MARK: - Theme Accent Environment Key
struct ThemeAccentKey: EnvironmentKey {
    static let defaultValue: Color = AppTheme.accent
}

extension EnvironmentValues {
    var themeAccent: Color {
        get { self[ThemeAccentKey.self] }
        set { self[ThemeAccentKey.self] = newValue }
    }
}

// MARK: - View Modifiers
struct GlassCard: ViewModifier {
    var padding: CGFloat = 16 // compacted
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading) // Ensure flexibility
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.dynamicSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.dynamicBorder, lineWidth: 1)
            )
    }
}

struct GradientButton: ViewModifier {
    @Environment(\.themeAccent) private var accent
    func body(content: Content) -> some View {
        content
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(accent)
            )
    }
}

struct StatCard: ViewModifier {
    let accentColor: Color
    
    func body(content: Content) -> some View {
        content
            .padding(14) // compacted
            .frame(maxWidth: .infinity, alignment: .leading) // Ensure flexibility
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppTheme.dynamicSurface)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.dynamicBorder, lineWidth: 1)
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
    
    func themeAccent(_ color: Color) -> some View {
        environment(\.themeAccent, color)
    }
}
