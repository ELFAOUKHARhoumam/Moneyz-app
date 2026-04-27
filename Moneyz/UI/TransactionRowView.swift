import SwiftUI

// MARK: - TransactionRowView
// FIX: Category emoji now overlays the icon badge instead of always showing a generic up/down arrow.
// Root cause: IconBadge always used systemImage — the category information (emoji) was shown
// only in the subtitle text, making rows visually identical regardless of category.
// Fix: pass the category emoji as emojiOverlay to IconBadge when available.

@MainActor
struct TransactionRowView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.colorScheme) private var colorScheme

    let transaction: MoneyTransaction

    private var subtitle: String {
        var parts: [String] = []
        if let category = transaction.category {
            parts.append("\(category.emoji) \(category.name)")
        }
        if let person = transaction.person {
            parts.append("\(person.emoji) \(person.name)")
        }
        if !transaction.note.isEmpty {
            parts.append(transaction.note)
        }
        return parts.joined(separator: " • ")
    }

    private var amountText: String {
        CurrencyFormatter.string(
            from: transaction.amountMinor * transaction.kind.multiplier,
            currencyCode: settings.currencyCode,
            locale: settings.locale
        )
    }

    private var colors: [Color] {
        PremiumTheme.Palette.transactionColors(isExpense: transaction.kind == .expense)
    }

    // Category emoji takes priority over the direction arrow when available.
    // This gives each row a unique, instantly-recognizable identity.
    private var badgeEmoji: String? {
        guard let emoji = transaction.category?.emoji, !emoji.isEmpty else { return nil }
        return emoji
    }

    private var fallbackSystemImage: String {
        transaction.kind == .expense ? "arrow.up.right" : "arrow.down.left"
    }

    var body: some View {
        HStack(spacing: 14) {
            PremiumTheme.IconBadge(
                systemImage: fallbackSystemImage,
                colors: colors,
                size: 46,
                symbolSize: 16,
                emojiOverlay: badgeEmoji   // category emoji when present
            )

            VStack(alignment: .leading, spacing: 6) {
                Text(transaction.displayTitle)
                    .font(.headline)

                if !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
                        .lineLimit(2)
                }

                Text(transaction.transactionDate, format: .dateTime.day().month().year())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 12)

            VStack(alignment: .trailing, spacing: 6) {
                Text(amountText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(transaction.kind == .expense ? .primary : PremiumTheme.Palette.success)

                Text(AppLocalizer.string(transaction.kind.localizedKey))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        colors.first?.opacity(0.16) ?? PremiumTheme.Palette.accent.opacity(0.16),
                                        colors.last?.opacity(0.08) ?? PremiumTheme.Palette.accentSecondary.opacity(0.08)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
            }
        }
        .padding(16)
        .premiumSecondaryCard(cornerRadius: PremiumTheme.CornerRadius.md, padding: 0)
    }
}
