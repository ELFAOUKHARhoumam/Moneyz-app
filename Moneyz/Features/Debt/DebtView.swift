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
                // Filter picker
                Section {
                    Picker(AppLocalizer.string("debt.filter"), selection: $viewModel.filter) {
                        ForEach(DebtViewModel.Filter.allCases) { filter in
                            Text(AppLocalizer.string(filter.localizedKey)).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .premiumCard(cornerRadius: PremiumTheme.CornerRadius.md, padding: PremiumTheme.Spacing.xs)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 10, trailing: 20))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                // Summary cards
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
                                accent: summary.overdueCount > 0 ? PremiumTheme.Palette.danger : .secondary,
                                isUrgent: summary.overdueCount > 0
                            )
                            debtStatusMetric(
                                title: AppLocalizer.string("debt.summary.dueSoon"),
                                value: "\(summary.dueSoonCount)",
                                accent: summary.dueSoonCount > 0 ? PremiumTheme.Palette.warning : .secondary,
                                isUrgent: false
                            )
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }

                // Debt rows
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
                                .onTapGesture { viewModel.presentEditor(for: debt) }
                                // Leading swipe: Mark as Settled — most common resolution action
                                // Previously required opening the full edit sheet
                                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                    if debt.status != .settled {
                                        Button {
                                            markAsSettled(debt)
                                        } label: {
                                            Label(AppLocalizer.string("status.settled"), systemImage: "checkmark.circle.fill")
                                        }
                                        .tint(PremiumTheme.Palette.success)
                                    }
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
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, PremiumTheme.Palette.accent)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingEditor, onDismiss: {
            viewModel.editingDebt = nil
        }) {
            NavigationStack {
                DebtEditorView(debt: viewModel.editingDebt)
            }
        }
        // FIX: alert previously used "common.error" / "common.ok" keys missing from .strings files.
        // Now uses "common.cancel" (exists) + the new "common.ok" added in LocalizationAdditions.
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
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            Button(AppLocalizer.string("common.cancel"), role: .cancel) {
                viewModel.cancelPendingDelete()
            }
        } message: {
            Text(AppLocalizer.string("common.deleteConfirmMessage"))
        }
    }

    // MARK: - Mark as Settled
    // FIX: sets updatedAt = .now so the @Query(sort: updatedAt) reorders the row correctly.
    // Previously: status was set but updatedAt was not updated, so the sort order wouldn't reflect
    // the change and the settled item might stay at the top of the list.
    private func markAsSettled(_ debt: DebtRecord) {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            debt.status = .settled
            debt.updatedAt = .now   // required for correct @Query sort behavior
            do {
                try modelContext.save()
            } catch {
                viewModel.errorMessage = error.localizedDescription
            }
        }
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    // MARK: - Debt Card

    private func debtCard(_ debt: DebtRecord) -> some View {
        let isOverdue: Bool = {
            guard let dueDate = debt.dueDate, debt.status != .settled else { return false }
            return dueDate < Date()
        }()

        return VStack(alignment: .leading, spacing: 12) {
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

                VStack(alignment: .trailing, spacing: 4) {
                    Text(CurrencyFormatter.string(
                        from: debt.amountMinor * (debt.direction == .owedToMe ? 1 : -1),
                        currencyCode: settings.currencyCode,
                        locale: settings.locale
                    ))
                    .font(.body.weight(.bold))
                    .monospacedDigit()

                    // Status badge
                    Text(AppLocalizer.string(debt.status.localizedKey))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(debt.status == .settled ? PremiumTheme.Palette.success : .secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule().fill(
                                debt.status == .settled
                                    ? PremiumTheme.Palette.success.opacity(0.12)
                                    : PremiumTheme.Palette.neutralFill
                            )
                        )
                }
            }

            HStack {
                if isOverdue {
                    Label(AppLocalizer.string("debt.summary.overdue"), systemImage: "exclamationmark.circle.fill")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(PremiumTheme.Palette.danger)
                }
                Spacer()
                if let dueDate = debt.dueDate {
                    Text(dueDate, format: .dateTime.day().month().year())
                        .font(.caption)
                        .foregroundStyle(isOverdue ? PremiumTheme.Palette.danger : .secondary)
                } else {
                    Text(debt.issueDate, format: .dateTime.day().month().year())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !debt.note.isEmpty {
                Text(debt.note)
                    .font(.caption)
                    .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
            }
        }
        .premiumCard(cornerRadius: PremiumTheme.CornerRadius.md, padding: PremiumTheme.Spacing.md)
        // Overdue items get a red border for immediate visual urgency
        .overlay(
            isOverdue
                ? RoundedRectangle(cornerRadius: PremiumTheme.CornerRadius.md, style: .continuous)
                    .strokeBorder(PremiumTheme.Palette.danger.opacity(0.4), lineWidth: 1.5)
                : nil
        )
    }

    // MARK: - Metric Card

    private func debtStatusMetric(title: String, value: String, accent: Color, isUrgent: Bool) -> some View {
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
        .premiumSecondaryCard(cornerRadius: PremiumTheme.CornerRadius.sm, padding: 14)
        .overlay(
            isUrgent
                ? RoundedRectangle(cornerRadius: PremiumTheme.CornerRadius.sm, style: .continuous)
                    .strokeBorder(accent.opacity(0.3), lineWidth: 1)
                : nil
        )
    }
}

// MARK: - Preview
@MainActor
private struct DebtViewPreviewHost: View {
    @StateObject private var settings = SettingsStore()

    var body: some View {
        NavigationStack { DebtView() }
            .environmentObject(settings)
            .modelContainer(PreviewContainer.modelContainer)
    }
}

#Preview { DebtViewPreviewHost() }
