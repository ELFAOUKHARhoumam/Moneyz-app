import SwiftUI

@MainActor
struct DashboardRingOverviewView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.colorScheme) private var colorScheme

    let summary: DashboardSummary

    private struct RingMetric: Identifiable {
        let id = UUID()
        let titleKey: String
        let amountMinor: Int64
        let colors: [Color]
        let systemImage: String

        var magnitude: Double {
            Double(abs(amountMinor))
        }
    }

    private let ringStartTrim: CGFloat = 0.12
    private let ringEndTrim: CGFloat = 0.88

    private var metrics: [RingMetric] {
        [
            RingMetric(
                titleKey: "dashboard.income",
                amountMinor: summary.incomeMinor,
                colors: [PremiumTheme.Palette.success, PremiumTheme.Palette.successSoft],
                systemImage: "arrow.down.left.circle.fill"
            ),
            RingMetric(
                titleKey: "dashboard.expense",
                amountMinor: -summary.expenseMinor,
                colors: [PremiumTheme.Palette.warning, PremiumTheme.Palette.dangerSoft],
                systemImage: "arrow.up.right.circle.fill"
            ),
            RingMetric(
                titleKey: "dashboard.netDebt",
                amountMinor: summary.netDebtMinor,
                colors: [PremiumTheme.Palette.info, PremiumTheme.Palette.accentSecondary],
                systemImage: "creditcard.trianglebadge.exclamationmark"
            )
        ]
    }

    private var totalMagnitude: Double {
        max(metrics.reduce(0) { $0 + $1.magnitude }, 1)
    }

    private var balanceAmountText: String {
        CurrencyFormatter.decimalString(from: summary.balanceMinor, locale: settings.locale)
    }

    var body: some View {
        VStack(spacing: 18) {
            heroCard
            metricsList
        }
        .premiumCard(cornerRadius: 28, padding: 18)
    }

    private var heroCard: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, 320)
            let ringLineWidth: CGFloat = 18
            let ringStep: CGFloat = 34

            ZStack {
                RoundedRectangle(cornerRadius: 32, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: colorScheme == .dark
                                ? [Color.white.opacity(0.07), Color.white.opacity(0.02)]
                                : [Color.white, Color(red: 0.97, green: 0.98, blue: 1.0)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(alignment: .topTrailing) {
                        Circle()
                            .fill(PremiumTheme.Palette.accent.opacity(colorScheme == .dark ? 0.22 : 0.12))
                            .frame(width: 132, height: 132)
                            .blur(radius: 22)
                            .offset(x: 26, y: -26)
                    }
                    .overlay(alignment: .bottomLeading) {
                        Circle()
                            .fill(PremiumTheme.Palette.info.opacity(colorScheme == .dark ? 0.18 : 0.10))
                            .frame(width: 110, height: 110)
                            .blur(radius: 22)
                            .offset(x: -18, y: 18)
                    }

                ForEach(Array(metrics.enumerated()), id: \.element.id) { index, metric in
                    let ringSize = size - CGFloat(index) * ringStep

                    TrimmedRingView(
                        progress: metric.magnitude / totalMagnitude,
                        colors: metric.colors,
                        lineWidth: ringLineWidth,
                        startTrim: ringStartTrim,
                        endTrim: ringEndTrim
                    )
                    .frame(width: ringSize, height: ringSize)
                }

                centerBalanceCard
                    .frame(width: size * 0.50, height: size * 0.50)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(Text(AppLocalizer.string("dashboard.balance")))
            .accessibilityValue(
                Text(
                    CurrencyFormatter.string(
                        from: summary.balanceMinor,
                        currencyCode: settings.currencyCode,
                        locale: settings.locale
                    )
                )
            )
        }
        .frame(height: 340)
    }

    private var centerBalanceCard: some View {
        VStack(spacing: 10) {
            PremiumTheme.IconBadge(
                systemImage: "wallet.bifold.fill",
                colors: [PremiumTheme.Palette.accent, PremiumTheme.Palette.accentSecondary],
                size: 50,
                symbolSize: 18
            )

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(settings.currencyCode.uppercased())
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.06))
                    )

                Text(balanceAmountText)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.65)
            }

            Text(AppLocalizer.string("dashboard.balance"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            Text(
                CurrencyFormatter.string(
                    from: summary.incomeMinor - summary.expenseMinor,
                    currencyCode: settings.currencyCode,
                    locale: settings.locale
                )
            )
            .font(.caption)
            .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 14)
        .padding(.vertical, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Circle()
                .fill(colorScheme == .dark ? Color.black.opacity(0.24) : Color.white.opacity(0.96))
        )
        .overlay(
            Circle()
                .strokeBorder(PremiumTheme.Palette.borderColor(for: colorScheme), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.28 : 0.10), radius: 18, y: 10)
    }

    private var metricsList: some View {
        VStack(spacing: 12) {
            ForEach(metrics) { metric in
                MetricRowView(
                    title: AppLocalizer.string(metric.titleKey),
                    amountText: CurrencyFormatter.string(
                        from: metric.amountMinor,
                        currencyCode: settings.currencyCode,
                        locale: settings.locale
                    ),
                    percentageText: percentageText(for: metric),
                    progress: metric.magnitude / totalMagnitude,
                    colors: metric.colors,
                    systemImage: metric.systemImage
                )
            }
        }
    }

    private func percentageText(for metric: RingMetric) -> String {
        let fraction = metric.magnitude / totalMagnitude
        return fraction.formatted(.percent.precision(.fractionLength(0)))
    }
}

private struct TrimmedRingView: View {
    let progress: Double
    let colors: [Color]
    let lineWidth: CGFloat
    let startTrim: CGFloat
    let endTrim: CGFloat

    private var clampedProgress: CGFloat {
        CGFloat(max(0, min(progress, 1)))
    }

    private var sweep: CGFloat {
        max(endTrim - startTrim, 0)
    }

    private var gradient: AngularGradient {
        AngularGradient(
            colors: colors + [colors.last ?? colors.first ?? .accentColor],
            center: .center,
            startAngle: .degrees(-90),
            endAngle: .degrees(270)
        )
    }

    var body: some View {
        ZStack {
            Circle()
                .trim(from: startTrim, to: endTrim)
                .stroke(
                    Color.primary.opacity(0.08),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )
                .rotationEffect(.degrees(-90))

            if clampedProgress > 0 {
                Circle()
                    .trim(from: startTrim, to: startTrim + (sweep * clampedProgress))
                    .stroke(
                        gradient,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: (colors.first ?? .accentColor).opacity(0.20), radius: 10, y: 4)
            }
        }
    }
}

private struct MetricRowView: View {
    let title: String
    let amountText: String
    let percentageText: String
    let progress: Double
    let colors: [Color]
    let systemImage: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        HStack(spacing: 14) {
            PremiumTheme.IconBadge(systemImage: systemImage, colors: colors, size: 42, symbolSize: 15)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(percentageText)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }

                GeometryReader { proxy in
                    let width = max(proxy.size.width, 1)
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(Color.primary.opacity(0.08))

                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: colors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: width * progress)
                    }
                }
                .frame(height: 8)

                Text(amountText)
                    .font(.body.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
            }
        }
        .premiumSecondaryCard(cornerRadius: 20, padding: 14)
    }
}
