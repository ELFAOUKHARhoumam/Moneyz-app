import SwiftUI
import SwiftData

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
                Section {
                    VStack(alignment: .leading, spacing: 14) {
                        PremiumTheme.SectionHeaderView(
                            title: AppLocalizer.string("transactions.title"),
                            subtitle: AppLocalizer.string(viewModel.activeFilterSummaryKey)
                        )

                        Picker(AppLocalizer.string("transactions.filter"), selection: $viewModel.filter) {
                            ForEach(TransactionsViewModel.Filter.allCases) { filter in
                                Text(AppLocalizer.string(filter.localizedKey)).tag(filter)
                            }
                        }
                        .pickerStyle(.segmented)
                        .premiumCard(cornerRadius: 24, padding: 8)

                        HStack {
                            Text(AppLocalizer.string(viewModel.activeFilterSummaryKey))
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("\(filteredTransactions.count)")
                                .font(.footnote.weight(.bold))
                                .monospacedDigit()
                        }
                        .premiumSecondaryCard(cornerRadius: 20, padding: 14)
                    }
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                if filteredTransactions.isEmpty {
                    EmptyStateView(
                        systemImage: "list.bullet.rectangle.portrait",
                        titleKey: "transactions.empty.title",
                        messageKey: "transactions.empty.message"
                    )
                    .listRowInsets(EdgeInsets(top: 8, leading: 20, bottom: 8, trailing: 20))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(filteredTransactions, id: \.id) { transaction in
                        TransactionRowView(transaction: transaction)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                viewModel.editingTransaction = transaction
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    viewModel.requestDelete(transaction)
                                } label: {
                                    Label(AppLocalizer.string("common.delete"), systemImage: "trash")
                                }

                                Button {
                                    viewModel.editingTransaction = transaction
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
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(Text(AppLocalizer.string("transactions.title")))
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(.hidden, for: .navigationBar)
        .searchable(text: $viewModel.searchText, prompt: Text(AppLocalizer.string("transactions.search")))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    viewModel.showingGrocery = true
                } label: {
                    Image(systemName: "cart.fill")
                }
                .buttonStyle(.plain)
                .premiumToolbarButton(accent: PremiumTheme.Palette.warning)

                Button {
                    viewModel.showingCategoryManager = true
                } label: {
                    Image(systemName: "square.grid.2x2")
                }
                .buttonStyle(.plain)
                .premiumToolbarButton(accent: PremiumTheme.Palette.info)

                Button {
                    viewModel.showingAddSheet = true
                } label: {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
                .premiumToolbarButton()
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
        .sheet(isPresented: $viewModel.showingGrocery) {
            NavigationStack {
                GroceryModeView()
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
