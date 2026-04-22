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
                VStack(alignment: .leading, spacing: 22) {
                    heroCard

                    VStack(alignment: .leading, spacing: 12) {
                        PremiumTheme.SectionHeaderView(
                            title: AppLocalizer.string("time.range"),
                            subtitle: nil
                        )

                        Picker(AppLocalizer.string("time.range"), selection: $viewModel.rangeOption) {
                            ForEach(TimeRangeOption.allCases) { option in
                                Text(AppLocalizer.string(option.localizedKey)).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)
                        .premiumCard(cornerRadius: 24, padding: 8)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        PremiumTheme.SectionHeaderView(
                            title: AppLocalizer.string("dashboard.overview"),
                            subtitle: AppLocalizer.string("dashboard.style.label")
                        )

                        Picker(AppLocalizer.string("dashboard.style.label"), selection: $settings.homeOverviewStyle) {
                            ForEach(SettingsStore.HomeOverviewStyle.allCases) { style in
                                Text(AppLocalizer.string(style.localizedKey)).tag(style)
                            }
                        }
                        .pickerStyle(.segmented)
                        .premiumCard(cornerRadius: 24, padding: 8)

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

                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text(AppLocalizer.string("home.burnRate"))
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                Text("\(Int((summary.burnRateProgress * 100).rounded()))%")
                                    .font(.subheadline.weight(.bold))
                                    .monospacedDigit()
                            }

                            GeometryReader { proxy in
                                let width = max(proxy.size.width, 1)
                                ZStack(alignment: .leading) {
                                    Capsule(style: .continuous)
                                        .fill(Color.primary.opacity(0.08))

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
                                        .frame(width: width * summary.burnRateProgress)
                                }
                            }
                            .frame(height: 10)

                            Text(AppLocalizer.string("home.burnRate.footer"))
                                .font(.caption)
                                .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
                        }
                        .premiumSecondaryCard(cornerRadius: 24, padding: 16)
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            PremiumTheme.SectionHeaderView(
                                title: AppLocalizer.string("home.recentTransactions"),
                                subtitle: nil
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
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
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
        .shadow(color: PremiumTheme.Palette.shadowColor(for: colorScheme), radius: 22, x: 0, y: 12)
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
