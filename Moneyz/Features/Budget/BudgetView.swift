import SwiftUI
import SwiftData

// MARK: - BudgetView
// FIX: Progress bar warning threshold and statusKey warning threshold are now consistent.
// Root cause: snapshotCard changed bar color at progress > 0.9 (90%)
// but PersonBudgetSnapshot.statusKey returned "budget.status.warning" at progress >= 0.85 (85%).
// A user would see the "Close to the budget limit" text while the bar was still green.
// Fix: align both to 0.85 as the single source of truth.

private let kWarningThreshold: Double = 0.85
private let kDangerThreshold: Double = 1.0

@MainActor
struct BudgetView: View {
    init() {
        _viewModel = StateObject(wrappedValue: BudgetViewModel())
    }

    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: [SortDescriptor<PersonProfile>(\.createdAt)])
    private var people: [PersonProfile]

    @Query(sort: [SortDescriptor<MoneyTransaction>(\.transactionDate, order: .reverse)])
    private var transactions: [MoneyTransaction]

    @Query(sort: [SortDescriptor<RecurringTransactionRule>(\.nextRunDate)])
    private var recurringRules: [RecurringTransactionRule]

    @StateObject private var viewModel: BudgetViewModel

    private var snapshots: [PersonBudgetSnapshot] {
        viewModel.snapshots(people: people, transactions: transactions, settings: settings)
    }

    var body: some View {
        ZStack {
            PremiumTheme.PageBackground()
                .ignoresSafeArea()

            List {
                // Time range picker
                Section {
                    Picker(AppLocalizer.string("time.range"), selection: $viewModel.rangeOption) {
                        ForEach(TimeRangeOption.allCases) { option in
                            Text(AppLocalizer.string(option.localizedKey)).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)
                    .premiumCard(cornerRadius: PremiumTheme.CornerRadius.md, padding: PremiumTheme.Spacing.xs)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 10, trailing: 20))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                // People budgets
                Section {
                    if snapshots.isEmpty {
                        EmptyStateView(
                            systemImage: "person.2.badge.plus",
                            titleKey: "budget.empty.title",
                            messageKey: "budget.empty.message"
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(snapshots) { snapshot in
                            snapshotCard(snapshot)
                                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                } header: {
                    headerRow(
                        title: AppLocalizer.string("budget.people"),
                        actionTitle: AppLocalizer.string("budget.person.add")
                    ) {
                        viewModel.presentPersonEditor()
                    }
                }

                // Recurring rules
                Section {
                    if recurringRules.filter({ $0.isActive }).isEmpty {
                        EmptyStateView(
                            systemImage: "repeat.circle",
                            titleKey: "budget.fixed.empty.title",
                            messageKey: "budget.fixed.empty.message"
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(recurringRules.filter { $0.isActive }, id: \.id) { rule in
                            recurringRuleCard(rule)
                                .contentShape(Rectangle())
                                .onTapGesture { viewModel.presentRuleEditor(for: rule) }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.requestDelete(rule)
                                    } label: {
                                        Label(AppLocalizer.string("common.delete"), systemImage: "trash")
                                    }

                                    Button {
                                        viewModel.presentRuleEditor(for: rule)
                                    } label: {
                                        Label(AppLocalizer.string("common.edit"), systemImage: "pencil")
                                    }
                                    .tint(PremiumTheme.Palette.accent)
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                } header: {
                    headerRow(
                        title: AppLocalizer.string("budget.fixed.title"),
                        actionTitle: AppLocalizer.string("budget.fixed.add")
                    ) {
                        viewModel.presentRuleEditor()
                    }
                } footer: {
                    Text(AppLocalizer.string("budget.fixed.footer"))
                        .textCase(nil)
                        .foregroundStyle(.secondary)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(Text(AppLocalizer.string("budget.title")))
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $viewModel.showingPersonEditor, onDismiss: { viewModel.editingPerson = nil }) {
            NavigationStack { PersonBudgetEditorView(person: viewModel.editingPerson) }
        }
        .sheet(isPresented: $viewModel.showingRuleEditor, onDismiss: { viewModel.editingRule = nil }) {
            NavigationStack { RecurringRuleEditorView(rule: viewModel.editingRule) }
        }
        .alert(
            Text(AppLocalizer.string("common.error")),
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            actions: {
                Button(AppLocalizer.string("common.ok"), role: .cancel) {
                    viewModel.errorMessage = nil
                }
            },
            message: { Text(viewModel.errorMessage ?? "") }
        )
        .confirmationDialog(
            AppLocalizer.string("common.deleteConfirmTitle"),
            isPresented: Binding(
                get: { viewModel.pendingDeletionRule != nil },
                set: { if !$0 { viewModel.cancelPendingDelete() } }
            ),
            titleVisibility: .visible
        ) {
            Button(AppLocalizer.string("common.delete"), role: .destructive) {
                viewModel.confirmDelete(in: modelContext)
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            Button(AppLocalizer.string("common.cancel"), role: .cancel) {
                viewModel.cancelPendingDelete()
            }
        } message: {
            Text(AppLocalizer.string("common.deleteConfirmMessage"))
        }
    }

    // MARK: - Header Row
    private func headerRow(title: String, actionTitle: String, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.title3.weight(.bold))
            Spacer()
            Button(action: action) {
                Label(actionTitle, systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.plain)
            .premiumCapsule()
        }
        .textCase(nil)
        .padding(.horizontal, 20)
        .padding(.top, 10)
    }

    // MARK: - Snapshot Card
    // FIX: progress bar now changes color at kWarningThreshold (0.85) matching statusKey threshold.
    private func snapshotCard(_ snapshot: PersonBudgetSnapshot) -> some View {
        let progress = max(0, min(snapshot.progress, 1))
        let isWarning = progress >= kWarningThreshold && progress < kDangerThreshold
        let isDanger  = progress >= kDangerThreshold

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 12) {
                PremiumTheme.IconBadge(
                    systemImage: "person.fill",
                    colors: [PremiumTheme.Palette.accent, PremiumTheme.Palette.accentSecondary],
                    size: 44,
                    symbolSize: 16
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(snapshot.person.emoji) \(snapshot.person.name)")
                        .font(.headline)
                    Text(snapshot.plan.title)
                        .font(.caption)
                        .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
                }

                Spacer()

                Button {
                    viewModel.presentPersonEditor(for: snapshot.person)
                } label: {
                    Image(systemName: "pencil")
                        .font(.callout.weight(.semibold))
                }
                .buttonStyle(.plain)
                .premiumCapsule()
            }

            VStack(spacing: 10) {
                HStack {
                    Text(AppLocalizer.string("budget.spent"))
                    Spacer()
                    Text(CurrencyFormatter.string(from: snapshot.spentMinor, currencyCode: settings.currencyCode, locale: settings.locale))
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                }

                GeometryReader { proxy in
                    let width = max(proxy.size.width, 1)
                    ZStack(alignment: .leading) {
                        Capsule(style: .continuous)
                            .fill(PremiumTheme.Palette.neutralFill)

                        Capsule(style: .continuous)
                            .fill(
                                LinearGradient(
                                    // FIX: now uses kWarningThreshold (0.85), was 0.9
                                    colors: isDanger
                                        ? [PremiumTheme.Palette.danger, PremiumTheme.Palette.warning]
                                        : isWarning
                                            ? [PremiumTheme.Palette.warning, PremiumTheme.Palette.warningSoft]
                                            : [PremiumTheme.Palette.accent, PremiumTheme.Palette.info],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: width * progress)
                            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: progress)
                    }
                }
                .frame(height: 10)
            }

            HStack(spacing: 12) {
                budgetMetric(
                    title: AppLocalizer.string("budget.limit"),
                    value: CurrencyFormatter.string(from: snapshot.plan.amountMinor, currencyCode: settings.currencyCode, locale: settings.locale)
                )
                budgetMetric(
                    title: AppLocalizer.string("budget.remaining"),
                    value: CurrencyFormatter.string(from: snapshot.remainingMinor, currencyCode: settings.currencyCode, locale: settings.locale)
                )
            }

            Text(AppLocalizer.string(snapshot.statusKey))
                .font(.caption.weight(.semibold))
                .foregroundStyle(
                    isDanger  ? PremiumTheme.Palette.danger :
                    isWarning ? PremiumTheme.Palette.warning :
                                PremiumTheme.Palette.success
                )
        }
        .premiumCard(cornerRadius: PremiumTheme.CornerRadius.lg, padding: PremiumTheme.Spacing.md)
    }

    // MARK: - Recurring Rule Card
    private func recurringRuleCard(_ rule: RecurringTransactionRule) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                PremiumTheme.IconBadge(
                    systemImage: rule.kind == .income ? "arrow.down.left" : "arrow.up.right",
                    colors: rule.kind == .income
                        ? [PremiumTheme.Palette.success, PremiumTheme.Palette.successSoft]
                        : [PremiumTheme.Palette.warning, PremiumTheme.Palette.dangerSoft],
                    size: 44,
                    symbolSize: 16
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(rule.title)
                        .font(.headline)
                    Text("\(AppLocalizer.string(rule.frequency.localizedKey)) • \(rule.nextRunDate, format: .dateTime.day().month().year())")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(CurrencyFormatter.string(
                    from: rule.amountMinor * rule.kind.multiplier,
                    currencyCode: settings.currencyCode,
                    locale: settings.locale
                ))
                .font(.body.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(rule.kind == .income ? PremiumTheme.Palette.success : .primary)
            }

            if let person = rule.person {
                Text("\(person.emoji) \(person.name)")
                    .font(.caption)
                    .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
            }
        }
        .premiumCard(cornerRadius: PremiumTheme.CornerRadius.md, padding: PremiumTheme.Spacing.md)
    }

    // MARK: - Budget Metric
    private func budgetMetric(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumSecondaryCard(cornerRadius: PremiumTheme.CornerRadius.sm, padding: 14)
    }
}

// MARK: - Preview
@MainActor
private struct BudgetViewPreviewHost: View {
    @StateObject private var settings = SettingsStore()

    var body: some View {
        NavigationStack { BudgetView() }
            .environmentObject(settings)
            .modelContainer(PreviewContainer.modelContainer)
    }
}

#Preview { BudgetViewPreviewHost() }
