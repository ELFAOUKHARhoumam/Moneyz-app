import SwiftUI
import SwiftData

@MainActor
struct HomeView: View {
    init() {}

    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: [SortDescriptor<MoneyTransaction>(\.transactionDate, order: .reverse)])
    private var transactions: [MoneyTransaction]

    @Query(sort: [SortDescriptor<DebtRecord>(\.createdAt, order: .reverse)])
    private var debts: [DebtRecord]

    @StateObject private var viewModel = HomeViewModel()
    @State private var showingAddTransaction = false
    @State private var showingGrocery = false
    @State private var editingTransaction: MoneyTransaction?

    private var summary: DashboardSummary {
        viewModel.summary(transactions: transactions, debts: debts, settings: settings)
    }

    private var groupedTransactions: [(date: Date, transactions: [MoneyTransaction])] {
        viewModel.recentGroups(from: transactions, settings: settings)
    }

    private var expenseIntensitySubtitle: String {
        let countText = "\(summary.intervalTransactionCount)"
        return "\(countText) \(AppLocalizer.string("home.activity.count"))"
    }

    private var savingsSubtitle: String {
        summary.savingsMinor >= 0
            ? AppLocalizer.string("home.savings.positive")
            : AppLocalizer.string("home.savings.negative")
    }

    var body: some View {
        ZStack {
            PremiumTheme.PageBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    heroCard
                    dashboardControlsCard
                    overviewSection
                    burnRateSpotlight
                    recentTransactionsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(Text(AppLocalizer.string("home.title")))
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingAddTransaction = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, PremiumTheme.Palette.accent)
                }
            }
        }
        .sheet(isPresented: $showingAddTransaction) {
            NavigationStack {
                AddEditTransactionView(transaction: nil)
            }
        }
        .sheet(isPresented: $showingGrocery) {
            NavigationStack {
                GroceryModeView()
            }
        }
        .sheet(isPresented: Binding(
            get: { editingTransaction != nil },
            set: { if !$0 { editingTransaction = nil } }
        )) {
            NavigationStack {
                if let transaction = editingTransaction {
                    AddEditTransactionView(transaction: transaction)
                }
            }
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top, spacing: 16) {
                BrandMarkView(size: 62, cornerRadius: 20)

                VStack(alignment: .leading, spacing: 8) {
                    Text(AppLocalizer.string("home.greeting"))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))

                    (Text(AppLocalizer.string("home.hello")) + Text(" \(settings.displayName) 👋"))
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.72)
                        .lineLimit(2)

                    Text(AppLocalizer.string(viewModel.rangeOption.localizedKey))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(Color.white.opacity(colorScheme == .dark ? 0.08 : 0.55))
                        )
                }

                Spacer(minLength: 12)

                VStack(spacing: 10) {
                    Button {
                        showingAddTransaction = true
                    } label: {
                        PremiumTheme.IconBadge(
                            systemImage: "plus",
                            colors: [PremiumTheme.Palette.accent, PremiumTheme.Palette.accentSecondary],
                            size: 46,
                            symbolSize: 18
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        showingGrocery = true
                    } label: {
                        PremiumTheme.IconBadge(
                            systemImage: "cart.fill",
                            colors: [PremiumTheme.Palette.warning, PremiumTheme.Palette.warningSoft],
                            size: 46,
                            symbolSize: 18
                        )
                    }
                    .buttonStyle(.plain)
                }
            }

            HStack(spacing: 12) {
                HeroDetailCard(
                    title: AppLocalizer.string("dashboard.balance"),
                    value: CurrencyFormatter.string(
                        from: summary.balanceMinor,
                        currencyCode: settings.currencyCode,
                        locale: settings.locale
                    ),
                    accent: summary.balanceMinor >= 0 ? PremiumTheme.Palette.success : PremiumTheme.Palette.danger
                )

                HeroDetailCard(
                    title: AppLocalizer.string("home.activity.title"),
                    value: expenseIntensitySubtitle,
                    accent: PremiumTheme.Palette.info
                )
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.white.opacity(0.10), Color.white.opacity(0.03)]
                            : [Color.white, Color(red: 0.97, green: 0.98, blue: 1.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .strokeBorder(PremiumTheme.Palette.borderColor(for: colorScheme), lineWidth: 1)
        )
        .overlay(alignment: .topTrailing) {
            Circle()
                .fill(PremiumTheme.Palette.accent.opacity(colorScheme == .dark ? 0.18 : 0.10))
                .frame(width: 120, height: 120)
                .blur(radius: 18)
                .offset(x: 18, y: -18)
        }
        .overlay(alignment: .bottomLeading) {
            Circle()
                .fill(PremiumTheme.Palette.info.opacity(colorScheme == .dark ? 0.16 : 0.08))
                .frame(width: 110, height: 110)
                .blur(radius: 18)
                .offset(x: -14, y: 14)
        }
        .shadow(color: PremiumTheme.Palette.shadowColor(for: colorScheme), radius: 22, x: 0, y: 12)
    }

    private var dashboardControlsCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            PremiumTheme.SectionHeaderView(
                title: AppLocalizer.string("dashboard.overview"),
                subtitle: AppLocalizer.string("dashboard.style.label")
            )

            VStack(alignment: .leading, spacing: 10) {
                Text(AppLocalizer.string("time.range"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))

                Picker(AppLocalizer.string("time.range"), selection: $viewModel.rangeOption) {
                    ForEach(TimeRangeOption.allCases) { option in
                        Text(AppLocalizer.string(option.localizedKey)).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.04))
                )
            }

            VStack(alignment: .leading, spacing: 10) {
                Text(AppLocalizer.string("dashboard.style.label"))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))

                Picker(AppLocalizer.string("dashboard.style.label"), selection: $settings.homeOverviewStyle) {
                    ForEach(SettingsStore.HomeOverviewStyle.allCases) { style in
                        Text(AppLocalizer.string(style.localizedKey)).tag(style)
                    }
                }
                .pickerStyle(.segmented)
                .padding(6)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.10 : 0.04))
                )
            }
        }
        .premiumCard(cornerRadius: 28, padding: 18)
    }

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            PremiumTheme.SectionHeaderView(
                title: AppLocalizer.string("dashboard.overview"),
                subtitle: AppLocalizer.string(viewModel.rangeOption.localizedKey)
            )

            if settings.homeOverviewStyle == .cards {
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)], spacing: 14) {
                    SummaryCardView(
                        titleKey: "dashboard.balance",
                        valueText: CurrencyFormatter.string(from: summary.balanceMinor, currencyCode: settings.currencyCode, locale: settings.locale),
                        subtitleText: nil,
                        systemImage: "wallet.bifold.fill"
                    )
                    SummaryCardView(
                        titleKey: "dashboard.income",
                        valueText: CurrencyFormatter.string(from: summary.incomeMinor, currencyCode: settings.currencyCode, locale: settings.locale),
                        subtitleText: nil,
                        systemImage: "arrow.down.left.circle.fill"
                    )
                    SummaryCardView(
                        titleKey: "dashboard.expense",
                        valueText: CurrencyFormatter.string(from: -summary.expenseMinor, currencyCode: settings.currencyCode, locale: settings.locale),
                        subtitleText: nil,
                        systemImage: "arrow.up.right.circle.fill"
                    )
                    SummaryCardView(
                        titleKey: "dashboard.netDebt",
                        valueText: CurrencyFormatter.string(from: summary.netDebtMinor, currencyCode: settings.currencyCode, locale: settings.locale),
                        subtitleText: nil,
                        systemImage: "creditcard.trianglebadge.exclamationmark"
                    )
                    SummaryCardView(
                        titleKey: "home.savings.title",
                        valueText: CurrencyFormatter.string(from: summary.savingsMinor, currencyCode: settings.currencyCode, locale: settings.locale),
                        subtitleText: savingsSubtitle,
                        systemImage: "chart.line.uptrend.xyaxis"
                    )
                    SummaryCardView(
                        titleKey: "home.activity.title",
                        valueText: CurrencyFormatter.string(from: -summary.intervalExpenseMinor, currencyCode: settings.currencyCode, locale: settings.locale),
                        subtitleText: expenseIntensitySubtitle,
                        systemImage: "bolt.heart.fill"
                    )
                }
            } else {
                DashboardRingOverviewView(summary: summary)
            }
        }
    }

    private var burnRateSpotlight: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                PremiumTheme.IconBadge(
                    systemImage: summary.burnRateProgress > 0.85 ? "flame.fill" : "speedometer",
                    colors: summary.burnRateProgress > 0.85
                        ? [PremiumTheme.Palette.danger, PremiumTheme.Palette.warning]
                        : [PremiumTheme.Palette.success, PremiumTheme.Palette.accent],
                    size: 48,
                    symbolSize: 18
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(AppLocalizer.string("home.burnRate"))
                        .font(.headline.weight(.semibold))

                    Text(AppLocalizer.string("home.burnRate.footer"))
                        .font(.caption)
                        .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
                }

                Spacer()

                Text("\(Int((summary.burnRateProgress * 100).rounded()))%")
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .monospacedDigit()
            }

            GeometryReader { proxy in
                let width = max(proxy.size.width, 1)
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(Color.primary.opacity(colorScheme == .dark ? 0.14 : 0.08))

                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: summary.burnRateProgress > 0.85
                                    ? [PremiumTheme.Palette.danger, PremiumTheme.Palette.warning]
                                    : [PremiumTheme.Palette.success, PremiumTheme.Palette.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(width * summary.burnRateProgress, summary.burnRateProgress > 0 ? 22 : 0))
                }
            }
            .frame(height: 12)
        }
        .premiumCard(cornerRadius: 28, padding: 18)
    }

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                PremiumTheme.SectionHeaderView(
                    title: AppLocalizer.string("home.recentTransactions"),
                    subtitle: AppLocalizer.string(viewModel.rangeOption.localizedKey)
                )
                Spacer()
                Button {
                    showingGrocery = true
                } label: {
                    Label(AppLocalizer.string("grocery.title"), systemImage: "cart.fill")
                        .font(.subheadline.weight(.semibold))
                }
                .buttonStyle(.plain)
                .premiumCapsule()
            }

            if groupedTransactions.isEmpty {
                EmptyStateView(
                    systemImage: "tray",
                    titleKey: "home.empty.title",
                    messageKey: "home.empty.message"
                )
            } else {
                VStack(spacing: 16) {
                    ForEach(groupedTransactions, id: \.date) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.date, format: .dateTime.weekday(.wide).day().month())
                                .font(.headline)
                                .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))

                            VStack(spacing: 12) {
                                ForEach(group.transactions, id: \.id) { transaction in
                                    TransactionRowView(transaction: transaction)
                                        .contentShape(Rectangle())
                                        .onTapGesture {
                                            editingTransaction = transaction
                                        }
                                }
                            }
                        }
                        .premiumCard(cornerRadius: 26, padding: 18)
                    }
                }
            }
        }
    }
}

private struct HeroDetailCard: View {
    let title: String
    let value: String
    let accent: Color

    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))

            Text(value)
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .lineLimit(2)
                .minimumScaleFactor(0.74)

            Capsule(style: .continuous)
                .fill(accent.opacity(colorScheme == .dark ? 0.75 : 0.90))
                .frame(width: 42, height: 4)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.45))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(Color.white.opacity(colorScheme == .dark ? 0.06 : 0.18), lineWidth: 1)
        )
    }
}

@MainActor
private struct HomeViewPreviewHost: View {
    @StateObject private var settings = SettingsStore()

    var body: some View {
        NavigationStack {
            HomeView()
        }
        .environmentObject(settings)
        .modelContainer(PreviewContainer.modelContainer)
    }
}

#Preview {
    HomeViewPreviewHost()
}
