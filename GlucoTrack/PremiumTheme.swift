import SwiftUI

enum PremiumTheme {
    static let cornerRadius: CGFloat = 20
    static let innerRadius: CGFloat = 14
    static let pagePadding: CGFloat = 24
    static let cardShadow = Color.black.opacity(0.12)
    static let border = Color.white.opacity(0.22)
    static let softBorder = Color.white.opacity(0.14)
}

enum PremiumPalette {
    static let accent = Color(red: 0.18, green: 0.50, blue: 0.82)
    static let accentSoft = Color(red: 0.72, green: 0.87, blue: 0.95)
    static let success = Color(red: 0.20, green: 0.66, blue: 0.50)
    static let warning = Color(red: 0.95, green: 0.70, blue: 0.28)
    static let danger = Color(red: 0.92, green: 0.37, blue: 0.37)
    static let calmBlue = Color(red: 0.20, green: 0.56, blue: 0.90)
    static let calmTeal = Color(red: 0.20, green: 0.72, blue: 0.70)
    static let indigo = Color(red: 0.35, green: 0.40, blue: 0.80)
}

struct PremiumBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.96, green: 0.97, blue: 0.99),
                    Color(red: 0.93, green: 0.95, blue: 0.98),
                    Color(red: 0.95, green: 0.96, blue: 0.98)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            RadialGradient(
                colors: [PremiumPalette.accent.opacity(0.20), .clear],
                center: .topTrailing,
                startRadius: 10,
                endRadius: 460
            )
            .blendMode(.plusLighter)
            .blur(radius: 24)

            RadialGradient(
                colors: [PremiumPalette.calmTeal.opacity(0.18), .clear],
                center: .bottomLeading,
                startRadius: 10,
                endRadius: 380
            )
            .blendMode(.plusLighter)
            .blur(radius: 26)
        }
    }
}

struct PremiumCardModifier: ViewModifier {
    var padding: CGFloat = PremiumTheme.pagePadding
    var radius: CGFloat = PremiumTheme.cornerRadius
    var shadow: CGFloat = 14

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .stroke(PremiumTheme.border)
            )
            .shadow(color: PremiumTheme.cardShadow, radius: shadow, x: 0, y: 8)
    }
}

struct PremiumFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(10)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(PremiumTheme.softBorder)
            )
    }
}

struct PremiumSectionHeader: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.title2.weight(.semibold))
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct PremiumPanel<Content: View>: View {
    let title: String
    let subtitle: String?
    let content: Content

    init(_ title: String, subtitle: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            PremiumSectionHeader(title, subtitle: subtitle)
            content
        }
        .premiumCard(padding: 20, radius: 18)
    }
}

struct PremiumStatusChip: View {
    let title: String
    let color: Color

    var body: some View {
        Text(title)
            .font(.system(size: 11, weight: .semibold, design: .rounded))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .foregroundStyle(color)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(color.opacity(0.14))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(color.opacity(0.25))
            )
    }
}

extension View {
    func premiumCard(padding: CGFloat = PremiumTheme.pagePadding, radius: CGFloat = PremiumTheme.cornerRadius) -> some View {
        modifier(PremiumCardModifier(padding: padding, radius: radius))
    }

    func premiumField() -> some View {
        modifier(PremiumFieldModifier())
    }

    func premiumPageBackground() -> some View {
        background(PremiumBackground())
    }
}
