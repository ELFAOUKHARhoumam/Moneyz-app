import SwiftUI

@MainActor
struct DashboardRingOverviewView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.colorScheme) private var colorScheme

    let summary: DashboardSummary
    @State private var ringAnimationProgress: Double = 0
    @State private var pulseCenterCard = false

    private struct RingMetric: Identifiable {
        let titleKey: String
        let amountMinor: Int64
        let colors: [Color]
        let systemImage: String

        var id: String { titleKey }

        var magnitude: Double {
            Double(abs(amountMinor))
        }
    }

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

    private var savingsAmountText: String {
        CurrencyFormatter.string(
            from: summary.savingsMinor,
            currencyCode: settings.currencyCode,
            locale: settings.locale
        )
    }

    private var activityAmountText: String {
        CurrencyFormatter.string(
            from: -summary.intervalExpenseMinor,
            currencyCode: settings.currencyCode,
            locale: settings.locale
        )
    }

    private var activitySubtitle: String {
        "\(summary.intervalTransactionCount) \(AppLocalizer.string("home.activity.count"))"
    }

    private var savingsColors: [Color] {
        summary.savingsMinor >= 0
            ? [PremiumTheme.Palette.success, PremiumTheme.Palette.successSoft]
            : [PremiumTheme.Palette.danger, PremiumTheme.Palette.warningSoft]
    }

    private var balanceColors: [Color] {
        summary.balanceMinor >= 0
            ? [PremiumTheme.Palette.accent, PremiumTheme.Palette.info]
            : [PremiumTheme.Palette.danger, PremiumTheme.Palette.warning]
    }

    private var burnRateText: String {
        "\(Int((summary.burnRateProgress * 100).rounded()))%"
    }

    var body: some View {
        VStack(spacing: 18) {
            heroCard
            insightsRow
            metricsList
        }
        .premiumCard(cornerRadius: 30, padding: 18)
        .onAppear {
            triggerRingAnimation()
            pulseCenterCard = true
        }
        .onChange(of: summary.incomeMinor) { _, _ in
            triggerRingAnimation()
        }
        .onChange(of: summary.expenseMinor) { _, _ in
            triggerRingAnimation()
        }
        .onChange(of: summary.netDebtMinor) { _, _ in
            triggerRingAnimation()
        }
    }

    private var heroCard: some View {
        VStack(spacing: 18) {
            GeometryReader { proxy in
                let size = min(proxy.size.width, 294)
                let ringLineWidth: CGFloat = 16
                let ringStep: CGFloat = 36

                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    PremiumTheme.Palette.accent.opacity(colorScheme == .dark ? 0.12 : 0.08),
                                    Color.clear
                                ],
                                center: .center,
                                startRadius: 24,
                                endRadius: size * 0.50
                            )
                        )
                        .frame(width: size * 0.90, height: size * 0.90)

                    Circle()
                        .stroke(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.18), lineWidth: 1)
                        .frame(width: size * 0.92, height: size * 0.92)

                    ForEach(Array(metrics.enumerated()), id: \.element.id) { index, metric in
                        let ringSize = size - CGFloat(index) * ringStep

                        FullRingView(
                            progress: animatedRingProgress(for: metric),
                            colors: metric.colors,
                            lineWidth: ringLineWidth
                        )
                        .frame(width: ringSize, height: ringSize)
                        .animation(
                            .spring(response: 0.72, dampingFraction: 0.86).delay(Double(index) * 0.08),
                            value: ringAnimationProgress
                        )
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
            .frame(height: 280)

            ringLegend

            HStack(spacing: 12) {
                HeroMetricPill(
                    title: AppLocalizer.string("dashboard.income"),
                    amountText: CurrencyFormatter.string(
                        from: summary.incomeMinor,
                        currencyCode: settings.currencyCode,
                        locale: settings.locale
                    ),
                    colors: [PremiumTheme.Palette.success, PremiumTheme.Palette.successSoft],
                    systemImage: "arrow.down.left.circle.fill"
                )

                HeroMetricPill(
                    title: AppLocalizer.string("dashboard.expense"),
                    amountText: CurrencyFormatter.string(
                        from: -summary.expenseMinor,
                        currencyCode: settings.currencyCode,
                        locale: settings.locale
                    ),
                    colors: [PremiumTheme.Palette.warning, PremiumTheme.Palette.dangerSoft],
                    systemImage: "arrow.up.right.circle.fill"
                )
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(PremiumTheme.Palette.elevatedSurfaceFill(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(PremiumTheme.Palette.borderColor(for: colorScheme), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(PremiumTheme.Palette.accent.opacity(colorScheme == .dark ? 0.12 : 0.06))
                .frame(width: 104, height: 104)
                .blur(radius: 18)
                .offset(x: 20, y: -20)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(PremiumTheme.Palette.accentWarm.opacity(colorScheme == .dark ? 0.10 : 0.05))
                .frame(width: 92, height: 92)
                .blur(radius: 18)
                .offset(x: -16, y: 14)
        }
    }

    private var centerBalanceCard: some View {
        VStack(spacing: 10) {
            Text(settings.currencyCode.uppercased())
                .font(.caption2.weight(.bold))
                .kerning(0.6)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(
                    Capsule(style: .continuous)
                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.12 : 0.06))
                )

            Text(balanceAmountText)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.65)
                .foregroundStyle(balanceColors.first ?? .primary)

            Text(AppLocalizer.string("dashboard.balance"))
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)

            HStack(spacing: 6) {
                Image(systemName: summary.savingsMinor >= 0 ? "arrow.up.right" : "arrow.down.right")
                Text(savingsAmountText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .font(.caption.weight(.semibold))
            .foregroundStyle((savingsColors.first ?? PremiumTheme.Palette.accent))
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill((savingsColors.first ?? PremiumTheme.Palette.accent).opacity(colorScheme == .dark ? 0.16 : 0.10))
            )

            Text(
                AppLocalizer.string("home.burnRate") + " · " + burnRateText
            )
            .font(.caption2.weight(.medium))
            .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 14)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            Circle()
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color(red: 0.10, green: 0.13, blue: 0.20), Color(red: 0.06, green: 0.08, blue: 0.14)]
                            : [Color.white.opacity(0.98), Color(red: 0.95, green: 0.97, blue: 1.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            Circle()
                .strokeBorder(PremiumTheme.Palette.borderColor(for: colorScheme), lineWidth: 1)
        )
        .overlay {
            Circle()
                .stroke((balanceColors.first ?? PremiumTheme.Palette.accent).opacity(colorScheme == .dark ? 0.34 : 0.22), lineWidth: 2)
                .padding(8)
                .scaleEffect(pulseCenterCard ? 1.03 : 0.96)
                .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: pulseCenterCard)
        }
        .shadow(color: (balanceColors.first ?? PremiumTheme.Palette.accent).opacity(colorScheme == .dark ? 0.24 : 0.16), radius: 20, y: 10)
        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.24 : 0.08), radius: 16, y: 8)
    }

    private var insightsRow: some View {
        HStack(spacing: 12) {
            OverviewInsightCard(
                titleKey: "home.savings.title",
                valueText: savingsAmountText,
                subtitleText: summary.savingsMinor >= 0
                    ? AppLocalizer.string("home.savings.positive")
                    : AppLocalizer.string("home.savings.negative"),
                colors: savingsColors,
                systemImage: "chart.line.uptrend.xyaxis"
            )

            OverviewInsightCard(
                titleKey: "home.activity.title",
                valueText: activityAmountText,
                subtitleText: activitySubtitle,
                colors: [PremiumTheme.Palette.info, PremiumTheme.Palette.accentSecondary],
                systemImage: "bolt.heart.fill"
            )
        }
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
                    progress: animatedRingProgress(for: metric),
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

    private var ringLegend: some View {
        HStack(spacing: 8) {
            ForEach(metrics) { metric in
                RingLegendChipView(
                    title: AppLocalizer.string(metric.titleKey),
                    percentageText: percentageText(for: metric),
                    colors: metric.colors,
                    systemImage: metric.systemImage
                )
            }
        }
    }

    private func animatedRingProgress(for metric: RingMetric) -> Double {
        (metric.magnitude / totalMagnitude) * ringAnimationProgress
    }

    private func triggerRingAnimation() {
        ringAnimationProgress = 0
        withAnimation(.spring(response: 0.90, dampingFraction: 0.88)) {
            ringAnimationProgress = 1
        }
    }
}

private struct FullRingView: View {
    let progress: Double
    let colors: [Color]
    let lineWidth: CGFloat

    @Environment(\.colorScheme) private var colorScheme

    private var clampedProgress: CGFloat {
        CGFloat(max(0, min(progress, 1)))
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
                .stroke(
                    Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.08),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                )

            Circle()
                .stroke(
                    Color.white.opacity(colorScheme == .dark ? 0.08 : 0.18),
                    style: StrokeStyle(lineWidth: 1.1, lineCap: .round, dash: [2.0, 7.0])
                )
                .padding(lineWidth * 0.42)

            if clampedProgress > 0 {
                Circle()
                    .trim(from: 0, to: clampedProgress)
                    .stroke(
                        gradient,
                        style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .shadow(color: (colors.first ?? .accentColor).opacity(0.24), radius: 12, y: 6)

                RingEndpointMarker(progress: clampedProgress, colors: colors, lineWidth: lineWidth)
            }

            Circle()
                .stroke(Color.white.opacity(colorScheme == .dark ? 0.05 : 0.24), lineWidth: 1)
                .padding(lineWidth * 0.55)
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.88), value: clampedProgress)
    }
}

private struct RingEndpointMarker: View {
    let progress: CGFloat
    let colors: [Color]
    let lineWidth: CGFloat

    var body: some View {
        GeometryReader { proxy in
            let size = min(proxy.size.width, proxy.size.height)
            let radius = (size - lineWidth) / 2
            let angle = Angle.degrees(Double(progress) * 360 - 90)
            let point = CGPoint(
                x: size / 2 + CGFloat(cos(angle.radians)) * radius,
                y: size / 2 + CGFloat(sin(angle.radians)) * radius
            )

            Circle()
                .fill(
                    LinearGradient(
                        colors: [colors.last ?? colors.first ?? .accentColor, colors.first ?? .accentColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: lineWidth * 0.76, height: lineWidth * 0.76)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.75), lineWidth: 1.4)
                )
                .shadow(color: (colors.first ?? .accentColor).opacity(0.32), radius: 8, y: 4)
                .position(point)
        }
        .allowsHitTesting(false)
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

    private var splitAmount: (prefix: String, amount: String)? {
        amountText.monetarySplit
    }

    var body: some View {
        HStack(spacing: 14) {
            PremiumTheme.IconBadge(systemImage: systemImage, colors: colors, size: 44, symbolSize: 15)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.subheadline.weight(.semibold))

                        if let splitAmount {
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(splitAmount.prefix)
                                    .font(.caption2.weight(.bold))
                                    .foregroundStyle(colors.first ?? PremiumTheme.Palette.accent)
                                    .padding(.horizontal, 7)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule(style: .continuous)
                                            .fill((colors.first ?? PremiumTheme.Palette.accent).opacity(colorScheme == .dark ? 0.16 : 0.10))
                                    )

                                Text(splitAmount.amount)
                                    .font(.body.weight(.bold))
                                    .monospacedDigit()
                                    .foregroundStyle(colorScheme == .dark ? .white : .primary)
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.70)
                            }
                        } else {
                            Text(amountText)
                                .font(.body.weight(.bold))
                                .monospacedDigit()
                                .foregroundStyle(colorScheme == .dark ? .white : .primary)
                        }
                    }

                    Spacer()

                    Text(percentageText)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(colors.first ?? PremiumTheme.Palette.accent)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill((colors.first ?? PremiumTheme.Palette.accent).opacity(colorScheme == .dark ? 0.18 : 0.12))
                        )
                }

                GeometryReader { proxy in
                    let width = max(proxy.size.width, 1)

                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.08))

                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: colors,
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(width * progress, progress > 0 ? 16 : 0))
                    }
                }
                .frame(height: 10)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(PremiumTheme.Palette.elevatedSurfaceFill(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            (colors.first ?? PremiumTheme.Palette.accent).opacity(colorScheme == .dark ? 0.18 : 0.10),
                            Color.clear
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .blendMode(.plusLighter)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(PremiumTheme.Palette.borderColor(for: colorScheme), lineWidth: 1)
        )
    }
}

private struct HeroMetricPill: View {
    let title: String
    let amountText: String
    let colors: [Color]
    let systemImage: String

    @Environment(\.colorScheme) private var colorScheme

    private var splitAmount: (prefix: String, amount: String)? {
        amountText.monetarySplit
    }

    var body: some View {
        HStack(spacing: 10) {
            PremiumTheme.IconBadge(systemImage: systemImage, colors: colors, size: 34, symbolSize: 12)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                if let splitAmount {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text(splitAmount.prefix)
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(colors.first ?? PremiumTheme.Palette.accent)

                        Text(splitAmount.amount)
                            .font(.subheadline.weight(.bold))
                            .monospacedDigit()
                            .lineLimit(1)
                            .minimumScaleFactor(0.72)
                    }
                } else {
                    Text(amountText)
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.18), lineWidth: 1)
        )
    }
}

private struct OverviewInsightCard: View {
    let titleKey: String
    let valueText: String
    let subtitleText: String
    let colors: [Color]
    let systemImage: String

    @Environment(\.colorScheme) private var colorScheme

    private var splitAmount: (prefix: String, amount: String)? {
        valueText.monetarySplit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                PremiumTheme.IconBadge(systemImage: systemImage, colors: colors, size: 38, symbolSize: 14)
                Spacer(minLength: 0)
            }

            Text(AppLocalizer.string(titleKey))
                .font(.caption.weight(.semibold))
                .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))

            if let splitAmount {
                VStack(alignment: .leading, spacing: 6) {
                    Text(splitAmount.prefix)
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(colors.first ?? PremiumTheme.Palette.accent)

                    Text(splitAmount.amount)
                        .font(.system(size: 21, weight: .bold, design: .rounded))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.70)
                }
            } else {
                Text(valueText)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
            }

            Text(subtitleText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(PremiumTheme.Palette.elevatedSurfaceFill(for: colorScheme))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            (colors.first ?? PremiumTheme.Palette.accent).opacity(colorScheme == .dark ? 0.18 : 0.10),
                            Color.clear
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .strokeBorder(PremiumTheme.Palette.borderColor(for: colorScheme), lineWidth: 1)
        )
    }
}

private struct RingLegendChipView: View {
    let title: String
    let percentageText: String
    let colors: [Color]
    let systemImage: String

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Circle()
                    .fill(colors.first ?? PremiumTheme.Palette.accent)
                    .frame(width: 7, height: 7)

                Image(systemName: systemImage)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(colors.first ?? PremiumTheme.Palette.accent)
            }

            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.78)

            Text(percentageText)
                .font(.caption.weight(.bold))
                .foregroundStyle(colors.first ?? PremiumTheme.Palette.accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 9)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.primary.opacity(colorScheme == .dark ? 0.08 : 0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(PremiumTheme.Palette.borderColor(for: colorScheme), lineWidth: 1)
        )
    }
}

private extension String {
    var monetarySplit: (prefix: String, amount: String)? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
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
}
