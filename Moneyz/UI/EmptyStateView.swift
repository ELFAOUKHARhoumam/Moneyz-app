import SwiftUI

@MainActor
struct EmptyStateView: View {
    let systemImage: String
    let titleKey: String
    let messageKey: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(spacing: 14) {
            PremiumTheme.IconBadge(
                systemImage: systemImage,
                colors: [PremiumTheme.Palette.accent, PremiumTheme.Palette.accentSecondary],
                size: 56,
                symbolSize: 22
            )
            .accessibilityHidden(true)

            Text(AppLocalizer.string(titleKey))
                .font(.headline)
                .multilineTextAlignment(.center)
                .dynamicTypeSize(...DynamicTypeSize.accessibility3)

            Text(AppLocalizer.string(messageKey))
                .font(.subheadline)
                .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
                .multilineTextAlignment(.center)
                .dynamicTypeSize(...DynamicTypeSize.accessibility4)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .premiumCard(cornerRadius: 24, padding: 24)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text(AppLocalizer.string(titleKey)))
        .accessibilityValue(Text(AppLocalizer.string(messageKey)))
        .accessibilityHint(Text(AppLocalizer.string(messageKey)))
    }
}
