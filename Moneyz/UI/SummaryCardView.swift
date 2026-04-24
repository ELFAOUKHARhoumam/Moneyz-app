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

    private var valuePrefix: String? {
        splitValue?.prefix
    }

    private var valueAmount: String {
        splitValue?.amount ?? valueText
    }

    private var splitValue: (prefix: String, amount: String)? {
        let trimmed = valueText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let separatorIndex = trimmed.firstIndex(of: " ") else {
            return nil
        }

        let prefix = String(trimmed[..<separatorIndex])
        let amountStart = trimmed.index(after: separatorIndex)
        let amount = String(trimmed[amountStart...])

        guard !prefix.isEmpty, !amount.isEmpty else {
            return nil
        }

        return (prefix, amount)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                PremiumTheme.IconBadge(systemImage: systemImage, colors: colors, size: 42, symbolSize: 15)

                VStack(alignment: .leading, spacing: 5) {
                    Text(AppLocalizer.string(titleKey))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
                        .lineLimit(2)

                    if let subtitleText {
                        Text(subtitleText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer(minLength: 0)
            }

            VStack(alignment: .leading, spacing: 8) {
                if let valuePrefix {
                    Text(valuePrefix)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(colors.first ?? PremiumTheme.Palette.accent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(
                            Capsule(style: .continuous)
                                .fill((colors.first ?? PremiumTheme.Palette.accent).opacity(colorScheme == .dark ? 0.16 : 0.10))
                        )
                }

                Text(valueAmount)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(2)
                    .minimumScaleFactor(0.68)
            }

            HStack(spacing: 8) {
                Circle()
                    .fill(colors.first ?? PremiumTheme.Palette.accent)
                    .frame(width: 8, height: 8)

                RoundedRectangle(cornerRadius: 999, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                colors.first?.opacity(0.20) ?? PremiumTheme.Palette.accent.opacity(0.20),
                                colors.last?.opacity(0.08) ?? PremiumTheme.Palette.accentSecondary.opacity(0.08)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumSecondaryCard(cornerRadius: 24, padding: 18)
    }
}
