import SwiftUI
import SwiftData

// MARK: - Date-Grouped Transaction List (Reusable Component)
// Extracted so both HomeView and TransactionsView use identical grouping logic.
// Root cause of previous inconsistency: HomeView grouped by date, TransactionsView was flat.
@MainActor
struct DateGroupedTransactionList: View {
    let transactions: [MoneyTransaction]
    let onTap: (MoneyTransaction) -> Void
    let onDelete: (MoneyTransaction) -> Void
    let onEdit: (MoneyTransaction) -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var groupedByDate: [(date: Date, transactions: [MoneyTransaction])] {
        let grouped = Dictionary(grouping: transactions) {
            Calendar.current.startOfDay(for: $0.transactionDate)
        }
        return grouped
            .map { (date: $0.key, transactions: $0.value.sorted { $0.transactionDate > $1.transactionDate }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        if groupedByDate.isEmpty {
            EmptyStateView(
                systemImage: "list.bullet.rectangle.portrait",
                titleKey: "transactions.empty.title",
                messageKey: "transactions.empty.message"
            )
            .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } else {
            ForEach(groupedByDate, id: \.date) { group in
                Section {
                    ForEach(group.transactions, id: \.id) { transaction in
                        TransactionRowView(transaction: transaction)
                            .contentShape(Rectangle())
                            .onTapGesture { onTap(transaction) }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    onDelete(transaction)
                                } label: {
                                    Label(AppLocalizer.string("common.delete"), systemImage: "trash")
                                }

                                Button {
                                    onEdit(transaction)
                                } label: {
                                    Label(AppLocalizer.string("common.edit"), systemImage: "pencil")
                                }
                                .tint(PremiumTheme.Palette.accent)
                            }
                            .listRowInsets(EdgeInsets(top: 4, leading: 20, bottom: 4, trailing: 20))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                } header: {
                    Text(group.date, format: .dateTime.weekday(.wide).day().month())
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
                        .textCase(nil)
                        .padding(.horizontal, 20)
                        .padding(.top, 8)
                }
            }
        }
    }
}

// MARK: - Transactions View
@MainActor
struct TransactionsView: View {
    init() {
        _viewModel = StateObject(wrappedValue: TransactionsViewModel())
    }

    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor<MoneyTransaction>(\.transactionDate, order: .reverse)])
    private var transactions: [MoneyTransaction]

    @StateObject private var viewModel: TransactionsViewModel

    private var filteredTransactions: [MoneyTransaction] {
        viewModel.filteredTransactions(from: transactions)
    }

    var body: some View {
        ZStack {
            PremiumTheme.PageBackground()
                .ignoresSafeArea()

            List {
                // Filter + count row
                Section {
                    Picker(AppLocalizer.string("transactions.filter"), selection: $viewModel.filter) {
                        ForEach(TransactionsViewModel.Filter.allCases) { filter in
                            Text(AppLocalizer.string(filter.localizedKey)).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .premiumCard(cornerRadius: 24, padding: 8)
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                // Date-grouped transaction list — matches HomeView grouping
                DateGroupedTransactionList(
                    transactions: filteredTransactions,
                    onTap: { viewModel.editingTransaction = $0 },
                    onDelete: { viewModel.requestDelete($0) },
                    onEdit: { viewModel.editingTransaction = $0 }
                )
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(Text(AppLocalizer.string("transactions.title")))
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .searchable(text: $viewModel.searchText, prompt: Text(AppLocalizer.string("transactions.search")))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                // Count badge replaces the verbose summary text row
                if !filteredTransactions.isEmpty {
                    Text("\(filteredTransactions.count)")
                        .font(.caption.weight(.bold))
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(PremiumTheme.Palette.accent, in: Capsule())
                }

                Button {
                    viewModel.showingCategoryManager = true
                } label: {
                    Image(systemName: "square.grid.2x2")
                }

                Button {
                    viewModel.showingAddSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, PremiumTheme.Palette.accent)
                }
            }
        }
        .sheet(isPresented: $viewModel.showingAddSheet) {
            NavigationStack {
                AddEditTransactionView(transaction: nil)
            }
        }
        .sheet(isPresented: $viewModel.showingCategoryManager) {
            NavigationStack {
                CategoryManagementView()
            }
        }
        // NOTE: Grocery removed from Transactions toolbar.
        // Root cause: Grocery was accessible from Home hero, Transactions toolbar, and its own mode.
        // Three entry points for a non-financial feature created noise. Home is the single entry point.
        .alert(
            Text(AppLocalizer.string("common.error")),
            isPresented: Binding(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            ),
            actions: {
                Button(AppLocalizer.string("common.cancel"), role: .cancel) {
                    viewModel.errorMessage = nil
                }
            },
            message: {
                Text(viewModel.errorMessage ?? "")
            }
        )
        .sheet(isPresented: Binding(
            get: { viewModel.editingTransaction != nil },
            set: { if !$0 { viewModel.editingTransaction = nil } }
        )) {
            NavigationStack {
                if let transaction = viewModel.editingTransaction {
                    AddEditTransactionView(transaction: transaction)
                }
            }
        }
        .confirmationDialog(
            AppLocalizer.string("common.deleteConfirmTitle"),
            isPresented: Binding(
                get: { viewModel.pendingDeletionTransaction != nil },
                set: { if !$0 { viewModel.cancelPendingDelete() } }
            ),
            titleVisibility: .visible
        ) {
            Button(AppLocalizer.string("common.delete"), role: .destructive) {
                viewModel.confirmDelete(in: modelContext)
                // Haptic on delete confirmation
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }
            Button(AppLocalizer.string("common.cancel"), role: .cancel) {
                viewModel.cancelPendingDelete()
            }
        } message: {
            Text(AppLocalizer.string("common.deleteConfirmMessage"))
        }
    }
}

@MainActor
private struct TransactionsViewPreviewHost: View {
    @StateObject private var settings = SettingsStore()

    var body: some View {
        NavigationStack {
            TransactionsView()
        }
        .environmentObject(settings)
        .modelContainer(PreviewContainer.modelContainer)
    }
}

#Preview {
    TransactionsViewPreviewHost()
}
