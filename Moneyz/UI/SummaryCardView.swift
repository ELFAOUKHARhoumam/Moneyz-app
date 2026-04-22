import SwiftUI

@MainActor
struct SummaryCardView: View {
    let titleKey: String
    let valueText: String
    let subtitleText: String?
    let systemImage: String

    @Environment(\.colorScheme) private var colorScheme

    private var colors: [Color] {
        PremiumTheme.Palette.metricColors(for: titleKey, systemImage: systemImage)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                PremiumTheme.IconBadge(systemImage: systemImage, colors: colors, size: 44, symbolSize: 16)

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppLocalizer.string(titleKey))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))

                    if let subtitleText {
                        Text(subtitleText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 8)
            }

            Text(valueText)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)

            RoundedRectangle(cornerRadius: 999, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            colors.first?.opacity(0.24) ?? PremiumTheme.Palette.accent.opacity(0.24),
                            colors.last?.opacity(0.10) ?? PremiumTheme.Palette.accentSecondary.opacity(0.10)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumCard(cornerRadius: 24, padding: 18)
    }
}
