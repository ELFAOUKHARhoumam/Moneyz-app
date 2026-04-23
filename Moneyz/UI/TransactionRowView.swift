import SwiftUI

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

    var body: some View {
        HStack(spacing: 14) {
            PremiumTheme.IconBadge(
                systemImage: transaction.kind == .expense ? "arrow.up.right" : "arrow.down.left",
                colors: colors,
                size: 46,
                symbolSize: 16
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

                HStack(spacing: 6) {
                    Circle()
                        .fill(colors.first ?? PremiumTheme.Palette.accent)
                        .frame(width: 6, height: 6)

                    Text(AppLocalizer.string(transaction.kind.localizedKey))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
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
        .premiumSecondaryCard(cornerRadius: 22, padding: 0)
    }
}
