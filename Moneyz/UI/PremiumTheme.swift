import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum PremiumTheme {
    enum Palette {
        static let accent = Color(red: 0.27, green: 0.49, blue: 0.98)
        static let accentSecondary = Color(red: 0.55, green: 0.42, blue: 0.98)
        static let info = Color(red: 0.32, green: 0.72, blue: 0.98)

        static let success = Color(red: 0.24, green: 0.79, blue: 0.59)
        static let successSoft = Color(red: 0.59, green: 0.92, blue: 0.78)

        static let warning = Color(red: 0.98, green: 0.72, blue: 0.31)
        static let warningSoft = Color(red: 1.00, green: 0.86, blue: 0.55)

        static let danger = Color(red: 0.96, green: 0.48, blue: 0.41)
        static let dangerSoft = Color(red: 1.00, green: 0.72, blue: 0.63)

        static let pageTopLight = Color(red: 0.95, green: 0.97, blue: 1.00)
        static let pageBottomLight = Color(red: 0.99, green: 0.99, blue: 1.00)
        static let pageTopDark = Color(red: 0.04, green: 0.06, blue: 0.12)
        static let pageBottomDark = Color(red: 0.08, green: 0.10, blue: 0.18)

        static let surfaceLightTop = Color.white.opacity(0.96)
        static let surfaceLightBottom = Color(red: 0.97, green: 0.98, blue: 1.00).opacity(0.96)
        static let surfaceDarkTop = Color(red: 0.10, green: 0.13, blue: 0.22).opacity(0.96)
        static let surfaceDarkBottom = Color(red: 0.07, green: 0.10, blue: 0.18).opacity(0.98)

        static let outlineLight = Color.black.opacity(0.05)
        static let outlineDark = Color.white.opacity(0.08)

        static let mutedTextLight = Color.black.opacity(0.62)
        static let mutedTextDark = Color.white.opacity(0.68)

        static func surfaceFill(for colorScheme: ColorScheme) -> LinearGradient {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [surfaceDarkTop, surfaceDarkBottom]
                    : [surfaceLightTop, surfaceLightBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static func elevatedSurfaceFill(for colorScheme: ColorScheme) -> LinearGradient {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color.white.opacity(0.08), surfaceDarkTop]
                    : [Color.white, surfaceLightBottom],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static func pageGradient(for colorScheme: ColorScheme) -> LinearGradient {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [pageTopDark, pageBottomDark]
                    : [pageTopLight, pageBottomLight],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static func borderColor(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? outlineDark : outlineLight
        }

        static func mutedText(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? mutedTextDark : mutedTextLight
        }

        static func shadowColor(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? .black.opacity(0.34) : .black.opacity(0.10)
        }

        static func metricColors(for titleKey: String, systemImage: String? = nil) -> [Color] {
            if titleKey == "dashboard.income" || (systemImage?.contains("down.left") == true) {
                return [success, successSoft]
            }
            if titleKey == "dashboard.expense" || (systemImage?.contains("up.right") == true) {
                return [warning, dangerSoft]
            }
            if titleKey == "dashboard.netDebt" || (systemImage?.contains("creditcard") == true) {
                return [info, accentSecondary]
            }
            return [accent, accentSecondary]
        }

        static func transactionColors(isExpense: Bool) -> [Color] {
            isExpense ? [warning, dangerSoft] : [success, successSoft]
        }
    }

    struct PageBackground: View {
        @Environment(\.colorScheme) private var colorScheme

        var body: some View {
            ZStack {
                Palette.pageGradient(for: colorScheme)

                RadialGradient(
                    colors: [
                        Palette.accent.opacity(colorScheme == .dark ? 0.28 : 0.18),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 40,
                    endRadius: 360
                )
                .offset(x: 120, y: -80)

                RadialGradient(
                    colors: [
                        Palette.accentSecondary.opacity(colorScheme == .dark ? 0.22 : 0.12),
                        Color.clear
                    ],
                    center: .bottomLeading,
                    startRadius: 30,
                    endRadius: 320
                )
                .offset(x: -120, y: 120)

                RadialGradient(
                    colors: [
                        Palette.info.opacity(colorScheme == .dark ? 0.14 : 0.08),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 280
                )
            }
        }
    }

    struct CardModifier: ViewModifier {
        @Environment(\.colorScheme) private var colorScheme

        let cornerRadius: CGFloat
        let contentPadding: CGFloat

        func body(content: Content) -> some View {
            content
                .padding(contentPadding)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Palette.surfaceFill(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Palette.borderColor(for: colorScheme), lineWidth: 1)
                )
                .shadow(color: Palette.shadowColor(for: colorScheme), radius: colorScheme == .dark ? 18 : 22, x: 0, y: 12)
        }
    }

    struct SecondaryCardModifier: ViewModifier {
        @Environment(\.colorScheme) private var colorScheme

        let cornerRadius: CGFloat
        let contentPadding: CGFloat

        func body(content: Content) -> some View {
            content
                .padding(contentPadding)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Palette.elevatedSurfaceFill(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(Palette.borderColor(for: colorScheme), lineWidth: 1)
                )
        }
    }

    struct GlassCapsuleModifier: ViewModifier {
        @Environment(\.colorScheme) private var colorScheme

        func body(content: Content) -> some View {
            content
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial, in: Capsule(style: .continuous))
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Palette.borderColor(for: colorScheme), lineWidth: 1)
                )
        }
    }

    struct FilledButtonStyle: ButtonStyle {
        @Environment(\.colorScheme) private var colorScheme

        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: configuration.isPressed
                            ? [Palette.accentSecondary, Palette.accent]
                            : [Palette.accent, Palette.accentSecondary],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.10 : 0.20), lineWidth: 1)
                )
                .shadow(color: Palette.accent.opacity(configuration.isPressed ? 0.18 : 0.26), radius: 14, x: 0, y: 10)
                .scaleEffect(configuration.isPressed ? 0.99 : 1.0)
                .animation(.easeOut(duration: 0.18), value: configuration.isPressed)
        }
    }

    struct IconBadge: View {
        let systemImage: String
        let colors: [Color]
        var size: CGFloat = 48
        var symbolSize: CGFloat? = nil

        var body: some View {
            ZStack {
                RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                RoundedRectangle(cornerRadius: size * 0.34, style: .continuous)
                    .fill(Color.white.opacity(0.10))
                    .padding(1)

                Image(systemName: systemImage)
                    .font(.system(size: symbolSize ?? size * 0.36, weight: .semibold))
                    .foregroundStyle(.white)
            }
            .frame(width: size, height: size)
            .shadow(color: (colors.first ?? Palette.accent).opacity(0.25), radius: 12, x: 0, y: 8)
        }
    }

    struct SectionHeaderView: View {
        let title: String
        var subtitle: String? = nil

        var body: some View {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title3.weight(.bold))

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    #if canImport(UIKit)
    static func configureUIKitAppearance() {
        let accent = UIColor(red: 0.27, green: 0.49, blue: 0.98, alpha: 1.0)
        let secondaryAccent = UIColor(red: 0.55, green: 0.42, blue: 0.98, alpha: 1.0)
        let tabBarBackground = UIColor.systemBackground.withAlphaComponent(0.78)

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithTransparentBackground()
        tabBarAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        tabBarAppearance.backgroundColor = tabBarBackground

        let normalColor = UIColor.secondaryLabel
        let selectedColor = accent

        [tabBarAppearance.stackedLayoutAppearance,
         tabBarAppearance.inlineLayoutAppearance,
         tabBarAppearance.compactInlineLayoutAppearance].forEach { appearance in
            appearance.selected.iconColor = selectedColor
            appearance.selected.titleTextAttributes = [
                .foregroundColor: selectedColor,
                .font: UIFont.systemFont(ofSize: 10, weight: .semibold)
            ]

            appearance.normal.iconColor = normalColor
            appearance.normal.titleTextAttributes = [
                .foregroundColor: normalColor,
                .font: UIFont.systemFont(ofSize: 10, weight: .medium)
            ]
        }

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        navAppearance.backgroundColor = .clear
        navAppearance.titleTextAttributes = [.foregroundColor: UIColor.label]
        navAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance

        let segmented = UISegmentedControl.appearance()
        segmented.selectedSegmentTintColor = accent
        segmented.setTitleTextAttributes([
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 13, weight: .semibold)
        ], for: .selected)
        segmented.setTitleTextAttributes([
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 13, weight: .medium)
        ], for: .normal)

        UITableView.appearance().backgroundColor = .clear
        UICollectionView.appearance().backgroundColor = .clear

        let searchFieldAppearance = UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self])
        searchFieldAppearance.backgroundColor = UIColor.secondarySystemBackground.withAlphaComponent(0.9)
        searchFieldAppearance.layer.cornerRadius = 14
        searchFieldAppearance.layer.masksToBounds = true

        UISwitch.appearance().onTintColor = secondaryAccent
    }
    #endif
}

extension View {
    func premiumPageBackground() -> some View {
        background(PremiumTheme.PageBackground().ignoresSafeArea())
    }

    func premiumCard(cornerRadius: CGFloat = 26, padding: CGFloat = 18) -> some View {
        modifier(PremiumTheme.CardModifier(cornerRadius: cornerRadius, contentPadding: padding))
    }

    func premiumSecondaryCard(cornerRadius: CGFloat = 22, padding: CGFloat = 16) -> some View {
        modifier(PremiumTheme.SecondaryCardModifier(cornerRadius: cornerRadius, contentPadding: padding))
    }

    func premiumCapsule() -> some View {
        modifier(PremiumTheme.GlassCapsuleModifier())
    }

    func premiumPrimaryButton() -> some View {
        buttonStyle(PremiumTheme.FilledButtonStyle())
    }
}
