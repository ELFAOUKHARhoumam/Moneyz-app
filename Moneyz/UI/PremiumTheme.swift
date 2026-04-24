import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum PremiumTheme {
    enum Palette {
        static let accent = Color(red: 0.10, green: 0.43, blue: 0.85)
        static let accentSecondary = Color(red: 0.00, green: 0.68, blue: 0.72)
        static let accentWarm = Color(red: 0.91, green: 0.69, blue: 0.30)
        static let info = Color(red: 0.27, green: 0.64, blue: 0.98)

        static let success = Color(red: 0.24, green: 0.79, blue: 0.59)
        static let successSoft = Color(red: 0.59, green: 0.92, blue: 0.78)

        static let warning = Color(red: 0.98, green: 0.72, blue: 0.31)
        static let warningSoft = Color(red: 1.00, green: 0.86, blue: 0.55)

        static let danger = Color(red: 0.96, green: 0.48, blue: 0.41)
        static let dangerSoft = Color(red: 1.00, green: 0.72, blue: 0.63)

        static let pageTopLight = Color(red: 0.95, green: 0.97, blue: 1.00)
        static let pageBottomLight = Color(red: 0.99, green: 0.98, blue: 0.96)
        static let pageTopDark = Color(red: 0.03, green: 0.06, blue: 0.10)
        static let pageBottomDark = Color(red: 0.07, green: 0.11, blue: 0.17)

        static let surfaceLightTop = Color.white.opacity(0.94)
        static let surfaceLightBottom = Color(red: 0.95, green: 0.97, blue: 0.99).opacity(0.98)
        static let surfaceDarkTop = Color(red: 0.09, green: 0.13, blue: 0.19).opacity(0.98)
        static let surfaceDarkBottom = Color(red: 0.05, green: 0.09, blue: 0.15).opacity(0.99)

        static let outlineLight = Color.black.opacity(0.06)
        static let outlineDark = Color.white.opacity(0.10)

        static let mutedTextLight = Color.black.opacity(0.60)
        static let mutedTextDark = Color.white.opacity(0.70)

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
                    ? [Color.white.opacity(0.10), surfaceDarkTop]
                    : [Color.white, Color(red: 0.97, green: 0.98, blue: 1.00)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static func inputFill(for colorScheme: ColorScheme) -> LinearGradient {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [Color.white.opacity(0.08), Color.white.opacity(0.03)]
                    : [Color.white.opacity(0.95), Color(red: 0.96, green: 0.98, blue: 1.00)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }

        static func heroFill(for colorScheme: ColorScheme) -> LinearGradient {
            LinearGradient(
                colors: colorScheme == .dark
                    ? [
                        Color(red: 0.08, green: 0.14, blue: 0.21),
                        Color(red: 0.05, green: 0.09, blue: 0.16)
                    ]
                    : [
                        Color.white,
                        Color(red: 0.95, green: 0.98, blue: 1.00)
                    ],
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
            colorScheme == .dark ? .black.opacity(0.26) : .black.opacity(0.08)
        }

        static func softShadowColor(for colorScheme: ColorScheme) -> Color {
            colorScheme == .dark ? .black.opacity(0.12) : accent.opacity(0.07)
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

                LinearGradient(
                    colors: [
                        Color.white.opacity(colorScheme == .dark ? 0.02 : 0.16),
                        Color.clear
                    ],
                    startPoint: .top,
                    endPoint: .center
                )

                RadialGradient(
                    colors: [
                        Palette.accent.opacity(colorScheme == .dark ? 0.18 : 0.11),
                        Color.clear
                    ],
                    center: .topTrailing,
                    startRadius: 40,
                    endRadius: 320
                )
                .offset(x: 120, y: -80)

                RadialGradient(
                    colors: [
                        Palette.accentWarm.opacity(colorScheme == .dark ? 0.10 : 0.06),
                        Color.clear
                    ],
                    center: .bottomLeading,
                    startRadius: 30,
                    endRadius: 280
                )
                .offset(x: -120, y: 120)

                RadialGradient(
                    colors: [
                        Palette.info.opacity(colorScheme == .dark ? 0.10 : 0.05),
                        Color.clear
                    ],
                    center: .center,
                    startRadius: 10,
                    endRadius: 220
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
                        .allowsHitTesting(false)
                )
                .overlay(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(colorScheme == .dark ? 0.05 : 0.30),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .mask(
                            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                                .padding(1)
                        )
                        .allowsHitTesting(false)
                }
                .shadow(color: Palette.shadowColor(for: colorScheme), radius: colorScheme == .dark ? 14 : 16, x: 0, y: 10)
                .shadow(color: Palette.softShadowColor(for: colorScheme), radius: 6, x: 0, y: 2)
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
                        .allowsHitTesting(false)
                )
                .shadow(color: Palette.softShadowColor(for: colorScheme), radius: 5, x: 0, y: 3)
        }
    }

    struct InputFieldModifier: ViewModifier {
        @Environment(\.colorScheme) private var colorScheme

        func body(content: Content) -> some View {
            content
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Palette.inputFill(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Palette.borderColor(for: colorScheme), lineWidth: 1)
                        .allowsHitTesting(false)
                )
                .shadow(color: Palette.softShadowColor(for: colorScheme), radius: 8, x: 0, y: 3)
        }
    }

    struct GlassCapsuleModifier: ViewModifier {
        @Environment(\.colorScheme) private var colorScheme

        func body(content: Content) -> some View {
            content
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.white.opacity(0.10), Color.white.opacity(0.05)]
                            : [Color.white.opacity(0.94), Color.white.opacity(0.64)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule(style: .continuous)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .strokeBorder(Palette.borderColor(for: colorScheme), lineWidth: 1)
                        .allowsHitTesting(false)
                )
                .shadow(color: Palette.softShadowColor(for: colorScheme), radius: 10, x: 0, y: 4)
        }
    }

    struct ToolbarIconModifier: ViewModifier {
        @Environment(\.colorScheme) private var colorScheme

        let accent: Color

        func body(content: Content) -> some View {
            content
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(colorScheme == .dark ? .white : accent)
                .frame(width: 34, height: 34)
                .background(
                    Circle()
                        .fill(
                            colorScheme == .dark
                                ? Color.white.opacity(0.10)
                                : Color.white.opacity(0.86)
                        )
                )
                .overlay(
                    Circle()
                        .strokeBorder(
                            colorScheme == .dark ? Color.white.opacity(0.08) : accent.opacity(0.12),
                            lineWidth: 1
                        )
                        .allowsHitTesting(false)
                )
                .shadow(color: Palette.softShadowColor(for: colorScheme), radius: 4, x: 0, y: 2)
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
            .shadow(color: (colors.first ?? Palette.accent).opacity(0.18), radius: 8, x: 0, y: 5)
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
        let accent = UIColor(red: 0.10, green: 0.43, blue: 0.85, alpha: 1.0)
        let secondaryAccent = UIColor(red: 0.00, green: 0.68, blue: 0.72, alpha: 1.0)
        let tabBarBackground = UIColor.systemBackground.withAlphaComponent(0.72)

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
        tabBarAppearance.shadowColor = UIColor.separator.withAlphaComponent(0.08)

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithTransparentBackground()
        navAppearance.backgroundEffect = UIBlurEffect(style: .systemUltraThinMaterial)
        navAppearance.backgroundColor = .clear
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 34, weight: .bold)
        ]
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

    func premiumFormField() -> some View {
        modifier(PremiumTheme.InputFieldModifier())
    }

    func premiumCapsule() -> some View {
        modifier(PremiumTheme.GlassCapsuleModifier())
    }

    func premiumToolbarButton(accent: Color = PremiumTheme.Palette.accent) -> some View {
        modifier(PremiumTheme.ToolbarIconModifier(accent: accent))
    }

    func premiumPrimaryButton() -> some View {
        buttonStyle(PremiumTheme.FilledButtonStyle())
    }
}
