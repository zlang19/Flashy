import SwiftUI
import UIKit
import FlashyCore

/// Synthwave palette from the app icon: navy night, magenta-violet cards, an
/// orange sun.
enum Theme {
    static let background = Color(hex: 0x14142A)
    static let surface = Color(hex: 0x1F1B3D)
    static let surfaceHigh = Color(hex: 0x2C2558)
    static let magenta = Color(hex: 0xF03EC8)
    static let violet = Color(hex: 0x7B4DFF)
    static let blue = Color(hex: 0x4D7CFF)
    static let sun = Color(hex: 0xFF7A59)
    static let peach = Color(hex: 0xFFB199)
    static let text = Color(hex: 0xF5ECFF)
    static let textDim = Color(hex: 0xA99BC9)

    static func color(for rating: Rating) -> Color {
        switch rating {
        case .bad: return Color(hex: 0xFF5A36)
        case .okay: return violet
        case .good: return Color(hex: 0x3CD6FF)
        }
    }

    static func color(for maturity: Maturity) -> Color {
        switch maturity {
        case .new: return sun
        case .learning: return magenta
        case .mature: return blue
        }
    }

    static let sunGradient = LinearGradient(colors: [peach, sun, magenta], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let cardGradient = LinearGradient(colors: [Color(hex: 0x5A2FB8), Color(hex: 0x2A1F6E)], startPoint: .topLeading, endPoint: .bottomTrailing)
    static let edgeGradient = LinearGradient(colors: [magenta, violet, blue], startPoint: .topLeading, endPoint: .bottomTrailing)

    /// SF Mono, for UI chrome. Card content uses the system font.
    static func mono(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .monospaced)
    }

    static func applyNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(background)
        appearance.shadowColor = .clear
        appearance.largeTitleTextAttributes = [
            .font: UIFont.monospacedSystemFont(ofSize: 30, weight: .bold),
            .foregroundColor: UIColor(text),
        ]
        appearance.titleTextAttributes = [
            .font: UIFont.monospacedSystemFont(ofSize: 17, weight: .semibold),
            .foregroundColor: UIColor(text),
        ]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance

        let tabs = UITabBarAppearance()
        tabs.configureWithOpaqueBackground()
        tabs.backgroundColor = UIColor(background)
        UITabBar.appearance().standardAppearance = tabs
        UITabBar.appearance().scrollEdgeAppearance = tabs
    }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

/// Faint CRT-style horizontal lines.
struct Scanlines: View {
    var spacing: CGFloat = 3
    var opacity: Double = 0.12

    var body: some View {
        Canvas { context, size in
            var y: CGFloat = 0
            while y < size.height {
                context.fill(Path(CGRect(x: 0, y: y, width: size.width, height: 1)), with: .color(.black.opacity(opacity)))
                y += spacing
            }
        }
        .allowsHitTesting(false)
    }
}

struct NeonButtonStyle: ButtonStyle {
    var fill: AnyShapeStyle
    var glowColor: Color

    init(color: Color) {
        fill = AnyShapeStyle(color)
        glowColor = color
    }

    init<S: ShapeStyle>(fill: S, glow: Color) {
        self.fill = AnyShapeStyle(fill)
        glowColor = glow
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(Theme.mono(16, .bold))
            .tracking(2)
            .foregroundStyle(Theme.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(fill, in: RoundedRectangle(cornerRadius: 14))
            .glow(glowColor, radius: configuration.isPressed ? 4 : 12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct SectionTitle: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(Theme.mono(12, .semibold))
            .tracking(2)
            .foregroundStyle(Theme.textDim)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

extension View {
    func glow(_ color: Color, radius: CGFloat = 12) -> some View {
        shadow(color: color.opacity(0.7), radius: radius / 2)
            .shadow(color: color.opacity(0.35), radius: radius)
    }

    /// A rounded surface panel for dashboard sections.
    func panel() -> some View {
        padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: 18))
            .overlay(RoundedRectangle(cornerRadius: 18).stroke(Theme.violet.opacity(0.35), lineWidth: 1))
    }

    /// Full-screen themed background behind a screen's content.
    func screenBackground() -> some View {
        background(Theme.background.ignoresSafeArea())
    }

    /// For Lists and Forms: hide the system background and show the theme's.
    func themedList() -> some View {
        scrollContentBackground(.hidden)
            .background(Theme.background.ignoresSafeArea())
    }
}
