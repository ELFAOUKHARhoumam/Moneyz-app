import SwiftUI
import SwiftData
import Charts

// MARK: - HomeView
// Changes from original:
// 1. Dashboard style picker removed — moved to Settings > Appearance
// 2. Time range control is inline (no card wrapper)
// 3. Overview condensed from 6 cards to 4
// 4. 7-day spending bar chart added (Swift Charts)
// 5. Burn rate bar animated + contextual insight sentence (localized)
// 6. "See All" is a simple action callback — avoids NavigationLink-in-ScrollView issues
// 7. Grocery button downsized; Grocery sheet still accessible from home

@MainActor
struct HomeView: View {
    // Callback injected by RootTabView to switch to the Transactions tab.
    // Using a callback avoids NavigationLink-in-ScrollView push bugs and keeps
    // HomeView decoupled from tab index knowledge.
    var onShowAllTransactions: (() -> Void)?

    init(onShowAllTransactions: (() -> Void)? = nil) {
        self.onShowAllTransactions = onShowAllTransactions
    }

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

    /// Last 7 days daily expense totals for the bar chart.
    private var last7DaysSpending: [(day: Date, amount: Double)] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).reversed().map { offset in
            let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let total = transactions
                .filter { $0.kind == .expense && calendar.isDate($0.transactionDate, inSameDayAs: day) }
                .reduce(0.0) { $0 + Double($1.amountMinor) / 100.0 }
            return (day: day, amount: total)
        }
    }

    private var savingsSubtitle: String {
        summary.savingsMinor >= 0
            ? AppLocalizer.string("home.savings.positive")
            : AppLocalizer.string("home.savings.negative")
    }

    // MARK: - Body

    var body: some View {
        ZStack {
            PremiumTheme.PageBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 22) {
                    heroCard

                    // Inline time range — no card wrapper, saves ~60pt vertical space
                    Picker(AppLocalizer.string("time.range"), selection: $viewModel.rangeOption) {
                        ForEach(TimeRangeOption.allCases) { option in
                            Text(AppLocalizer.string(option.localizedKey)).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 2)

                    overviewSection
                    spendingSparklineCard
                    burnRateCard
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
            NavigationStack { AddEditTransactionView(transaction: nil) }
        }
        .sheet(isPresented: $showingGrocery) {
            NavigationStack { GroceryModeView() }
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

    // MARK: - Overview Section
    // Reduced from 6 → 4 cards: Balance, Income, Expenses, Savings.
    // Removed Spending Pulse (same number as Expenses) and Net Debt (belongs on Debt tab).

    @ViewBuilder
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            PremiumTheme.SectionHeaderView(title: AppLocalizer.string("dashboard.overview"))

            if settings.homeOverviewStyle == .cards {
                LazyVGrid(
                    columns: [GridItem(.flexible(), spacing: 14), GridItem(.flexible(), spacing: 14)],
                    spacing: 14
                ) {
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
                        titleKey: "home.savings.title",
                        valueText: CurrencyFormatter.string(from: summary.savingsMinor, currencyCode: settings.currencyCode, locale: settings.locale),
                        subtitleText: savingsSubtitle,
                        systemImage: "chart.line.uptrend.xyaxis"
                    )
                }
            } else {
                DashboardRingOverviewView(summary: summary)
            }
        }
    }

    // MARK: - 7-Day Spending Sparkline

    @ViewBuilder
    private var spendingSparklineCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            PremiumTheme.SectionHeaderView(title: AppLocalizer.string("home.activity.title"))

            Chart(last7DaysSpending, id: \.day) { point in
                BarMark(
                    x: .value("Day", point.day, unit: .day),
                    y: .value("Amount", point.amount)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [PremiumTheme.Palette.accent, PremiumTheme.Palette.accentSecondary],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                )
                .cornerRadius(6)
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .day)) { _ in
                    AxisValueLabel(format: .dateTime.weekday(.narrow), centered: true)
                        .font(.caption2)
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(CurrencyFormatter.string(
                                from: Int64(amount * 100),
                                currencyCode: settings.currencyCode,
                                locale: settings.locale
                            ))
                            .font(.caption2)
                        }
                    }
                }
            }
            .frame(height: 160)
            .chartPlotStyle { plot in plot.background(Color.clear) }
            .accessibilityLabel(Text(AppLocalizer.string("home.activity.title")))
        }
        .premiumCard(cornerRadius: PremiumTheme.CornerRadius.lg, padding: PremiumTheme.Spacing.md)
    }

    // MARK: - Burn Rate Card

    @ViewBuilder
    private var burnRateCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(AppLocalizer.string("home.burnRate"))
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(Int((summary.burnRateProgress * 100).rounded()))%")
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(
                        summary.burnRateProgress > 0.85
                            ? PremiumTheme.Palette.danger
                            : .primary
                    )
            }

            GeometryReader { proxy in
                let width = max(proxy.size.width, 1)
                ZStack(alignment: .leading) {
                    Capsule(style: .continuous)
                        .fill(PremiumTheme.Palette.neutralFill)
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
                        .frame(width: width * min(summary.burnRateProgress, 1.0))
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: summary.burnRateProgress)
                }
            }
            .frame(height: 10)

            Text(burnRateInsight)
                .font(.caption)
                .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
        }
        .premiumSecondaryCard(cornerRadius: PremiumTheme.CornerRadius.md, padding: PremiumTheme.Spacing.md)
    }

    /// Context-aware insight sentence. Uses localization keys — English text is a fallback only.
    private var burnRateInsight: String {
        let pct = Int((summary.burnRateProgress * 100).rounded())
        if summary.incomeMinor == 0 {
            return AppLocalizer.string("home.burnRate.footer")
        }
        if pct >= 100 {
            return AppLocalizer.string("home.insight.exceeded", fallback: "⚠️ You've exceeded your income for this period.")
        } else if pct >= 85 {
            return String(format: AppLocalizer.string("home.insight.warning", fallback: "You've spent %d%% of your income — watch your remaining %d%%."), pct, 100 - pct)
        } else if pct >= 50 {
            return String(format: AppLocalizer.string("home.insight.onTrack", fallback: "You've used %d%% of your income. You're on track."), pct)
        } else {
            return String(format: AppLocalizer.string("home.insight.good", fallback: "Great start — only %d%% of your income spent so far."), pct)
        }
    }

    // MARK: - Recent Transactions Section

    @ViewBuilder
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 10) {
                PremiumTheme.SectionHeaderView(
                    title: AppLocalizer.string("home.recentTransactions")
                )

                Spacer()

                // "See All" switches to Transactions tab via callback injected by RootTabView.
                // Using a callback avoids NavigationLink-inside-ScrollView-inside-NavigationStack
                // double-push issues and keeps HomeView tab-agnostic.
                if onShowAllTransactions != nil {
                    Button {
                        onShowAllTransactions?()
                    } label: {
                        Text(AppLocalizer.string("common.seeAll"))
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.plain)
                    .premiumCapsule()
                }

                // Grocery entry — single entry point kept on Home
                Button {
                    showingGrocery = true
                } label: {
                    PremiumTheme.IconBadge(
                        systemImage: "cart.fill",
                        colors: [PremiumTheme.Palette.warning, PremiumTheme.Palette.warningSoft],
                        size: 36,
                        symbolSize: 14
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(AppLocalizer.string("grocery.title")))
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
                                        .onTapGesture { editingTransaction = transaction }
                                }
                            }
                        }
                        .premiumCard(cornerRadius: PremiumTheme.CornerRadius.lg, padding: PremiumTheme.Spacing.md)
                    }
                }
            }
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        HStack(spacing: 16) {
            BrandMarkView(size: 62, cornerRadius: 20)

            VStack(alignment: .leading, spacing: 6) {
                Text(AppLocalizer.string("home.greeting"))
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))

                (Text(AppLocalizer.string("home.hello")) + Text(" \(settings.displayName) 👋"))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.72)
                    .lineLimit(2)
            }

            Spacer(minLength: 12)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: PremiumTheme.CornerRadius.lg, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: colorScheme == .dark
                            ? [Color.white.opacity(0.08), Color.white.opacity(0.03)]
                            : [Color.white, Color(red: 0.97, green: 0.98, blue: 1.0)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: PremiumTheme.CornerRadius.lg, style: .continuous)
                .strokeBorder(PremiumTheme.Palette.borderColor(for: colorScheme), lineWidth: 1)
        )
        .shadow(color: PremiumTheme.Palette.shadowColor(for: colorScheme), radius: 22, x: 0, y: 12)
    }
}

// MARK: - Preview
@MainActor
private struct HomeViewPreviewHost: View {
    @StateObject private var settings = SettingsStore()

    var body: some View {
        NavigationStack {
            HomeView(onShowAllTransactions: nil)
        }
        .environmentObject(settings)
        .modelContainer(PreviewContainer.modelContainer)
    }
}

#Preview { HomeViewPreviewHost() }
