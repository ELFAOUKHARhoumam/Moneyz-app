import Foundation
import Combine
import SwiftData

@MainActor
final class TransactionsViewModel: ObservableObject {
    enum Filter: String, CaseIterable, Identifiable {
        case all
        case expense
        case income

        var id: String { rawValue }
        var localizedKey: String {
            switch self {
            case .all: return "filter.all"
            case .expense: return "transaction.kind.expense"
            case .income: return "transaction.kind.income"
            }
        }
    }

    @Published var searchText = ""
    @Published var filter: Filter = .all
    @Published var showingAddSheet = false
    @Published var showingCategoryManager = false
    @Published var editingTransaction: MoneyTransaction?
    @Published var pendingDeletionTransaction: MoneyTransaction?
    @Published var errorMessage: String?

    private let deleteTransactionAction: @MainActor (MoneyTransaction, ModelContext) throws -> Void

    init(
        deleteTransactionAction: (@MainActor (MoneyTransaction, ModelContext) throws -> Void)? = nil
    ) {
        self.deleteTransactionAction = deleteTransactionAction ?? { transaction, context in
            try TransactionRepository().delete(transaction, in: context)
        }
    }

    var activeFilterSummaryKey: String {
        switch filter {
        case .all:
            return searchText.isEmpty ? "transactions.summary.all" : "transactions.summary.searching"
        case .expense:
            return "transactions.summary.expense"
        case .income:
            return "transactions.summary.income"
        }
    }

    func filteredTransactions(from transactions: [MoneyTransaction]) -> [MoneyTransaction] {
        transactions.filter { transaction in
            let matchesFilter: Bool
            switch filter {
            case .all:
                matchesFilter = true
            case .expense:
                matchesFilter = transaction.kind == .expense
            case .income:
                matchesFilter = transaction.kind == .income
            }

            guard matchesFilter else { return false }
            guard !searchText.isEmpty else { return true }

            let haystack = [
                transaction.displayTitle,
                transaction.note,
                transaction.category?.name ?? "",
                transaction.person?.name ?? ""
            ].joined(separator: " ").lowercased()

            return haystack.contains(searchText.lowercased())
        }
    }

    func delete(_ transaction: MoneyTransaction, in context: ModelContext) {
        do {
            try deleteTransactionAction(transaction, context)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func requestDelete(_ transaction: MoneyTransaction) {
        pendingDeletionTransaction = transaction
    }

    func confirmDelete(in context: ModelContext) {
        guard let transaction = pendingDeletionTransaction else { return }
        delete(transaction, in: context)
        pendingDeletionTransaction = nil
    }

    func cancelPendingDelete() {
        pendingDeletionTransaction = nil
    }
}
