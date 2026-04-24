import SwiftUI
import SwiftData

@MainActor
struct DebtView: View {
    init() {
        _viewModel = StateObject(wrappedValue: DebtViewModel())
    }

    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @Query(sort: [SortDescriptor<DebtRecord>(\.updatedAt, order: .reverse)])
    private var debts: [DebtRecord]

    @StateObject private var viewModel: DebtViewModel

    private var summary: DebtSummary {
        viewModel.summary(from: debts)
    }

    private var filteredDebts: [DebtRecord] {
        viewModel.filteredDebts(from: debts)
    }

    var body: some View {
        ZStack {
            PremiumTheme.PageBackground()
                .ignoresSafeArea()

            List {
                Section {
                    VStack(alignment: .leading, spacing: 14) {
                        PremiumTheme.SectionHeaderView(
                            title: AppLocalizer.string("debt.title"),
                            subtitle: "\(AppLocalizer.string("debt.summary.openItems")) \(summary.openCount)"
                        )

                        Picker(AppLocalizer.string("debt.filter"), selection: $viewModel.filter) {
                            ForEach(DebtViewModel.Filter.allCases) { filter in
                                Text(AppLocalizer.string(filter.localizedKey)).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .premiumCard(cornerRadius: 24, padding: 8)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 10, trailing: 20))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section {
                    VStack(spacing: 14) {
                        SummaryCardView(
                            titleKey: "dashboard.netDebt",
                            valueText: CurrencyFormatter.string(from: summary.netMinor, currencyCode: settings.currencyCode, locale: settings.locale),
                            subtitleText: "\(AppLocalizer.string("debt.summary.openItems")) \(summary.openCount)",
                            systemImage: "scale.3d"
                        )

                        HStack(spacing: 14) {
                            SummaryCardView(
                                titleKey: DebtDirection.owedToMe.localizedKey,
                                valueText: CurrencyFormatter.string(from: summary.owedToMeMinor, currencyCode: settings.currencyCode, locale: settings.locale),
                                subtitleText: nil,
                                systemImage: "arrow.down.circle.fill"
                            )

                            SummaryCardView(
                                titleKey: DebtDirection.iOwe.localizedKey,
                                valueText: CurrencyFormatter.string(from: -summary.iOweMinor, currencyCode: settings.currencyCode, locale: settings.locale),
                                subtitleText: nil,
                                systemImage: "arrow.up.circle.fill"
                            )
                        }

                        HStack(spacing: 14) {
                            debtStatusMetric(
                                title: AppLocalizer.string("debt.summary.overdue"),
                                value: "\(summary.overdueCount)",
                                accent: PremiumTheme.Palette.danger
                            )
                            debtStatusMetric(
                                title: AppLocalizer.string("debt.summary.dueSoon"),
                                value: "\(summary.dueSoonCount)",
                                accent: PremiumTheme.Palette.warning
                            )
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                Section {
                    if filteredDebts.isEmpty {
                        EmptyStateView(
                            systemImage: "creditcard.trianglebadge.exclamationmark",
                            titleKey: "debt.empty.title",
                            messageKey: "debt.empty.message"
                        )
                        .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    } else {
                        ForEach(filteredDebts, id: \.id) { debt in
                            debtCard(debt)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    viewModel.presentEditor(for: debt)
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        viewModel.requestDelete(debt)
                                    } label: {
                                        Label(AppLocalizer.string("common.delete"), systemImage: "trash")
                                    }

                                    Button {
                                        viewModel.presentEditor(for: debt)
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
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(Text(AppLocalizer.string("debt.title")))
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.presentEditor()
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .premiumToolbarButton()
            }
        }
        .sheet(isPresented: $viewModel.showingEditor, onDismiss: {
            viewModel.editingDebt = nil
        }) {
            NavigationStack {
                DebtEditorView(debt: viewModel.editingDebt)
            }
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
            message: {
                Text(viewModel.errorMessage ?? "")
            }
        )
        .confirmationDialog(
            AppLocalizer.string("common.deleteConfirmTitle"),
            isPresented: Binding(
                get: { viewModel.pendingDeletionDebt != nil },
                set: { if !$0 { viewModel.cancelPendingDelete() } }
            ),
            titleVisibility: .visible
        ) {
            Button(AppLocalizer.string("common.delete"), role: .destructive) {
                viewModel.confirmDelete(in: modelContext)
            }
            Button(AppLocalizer.string("common.cancel"), role: .cancel) {
                viewModel.cancelPendingDelete()
            }
        } message: {
            Text(AppLocalizer.string("common.deleteConfirmMessage"))
        }
    }

    private func debtCard(_ debt: DebtRecord) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                PremiumTheme.IconBadge(
                    systemImage: debt.direction == .owedToMe ? "arrow.down.left" : "arrow.up.right",
                    colors: debt.direction == .owedToMe
                        ? [PremiumTheme.Palette.success, PremiumTheme.Palette.successSoft]
                        : [PremiumTheme.Palette.warning, PremiumTheme.Palette.dangerSoft],
                    size: 44,
                    symbolSize: 16
                )

                VStack(alignment: .leading, spacing: 4) {
                    Text(debt.counterpartyName)
                        .font(.headline)

                    Text(AppLocalizer.string(debt.direction.localizedKey))
                        .font(.caption)
                        .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
                }

                Spacer()

                Text(CurrencyFormatter.string(from: debt.amountMinor * (debt.direction == .owedToMe ? 1 : -1), currencyCode: settings.currencyCode, locale: settings.locale))
                    .font(.body.weight(.bold))
                    .monospacedDigit()
            }

            HStack {
                Text(AppLocalizer.string(debt.status.localizedKey))
                Spacer()
                if let dueDate = debt.dueDate {
                    Text(dueDate, format: .dateTime.day().month().year())
                } else {
                    Text(debt.issueDate, format: .dateTime.day().month().year())
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if !debt.note.isEmpty {
                Text(debt.note)
                    .font(.caption)
                    .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
            }
        }
        .premiumCard(cornerRadius: 24, padding: 16)
    }

    private func debtStatusMetric(title: String, value: String, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(value)
                .font(.subheadline.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .premiumSecondaryCard(cornerRadius: 20, padding: 14)
    }
}

@MainActor
private struct DebtViewPreviewHost: View {
    @StateObject private var settings = SettingsStore()

    var body: some View {
        NavigationStack {
            DebtView()
        }
        .environmentObject(settings)
        .modelContainer(PreviewContainer.modelContainer)
    }
}

#Preview {
    DebtViewPreviewHost()
}
