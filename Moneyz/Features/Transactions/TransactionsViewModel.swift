import Foundation
import Combine

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
    @Published var showingGrocery = false
    @Published var editingTransaction: MoneyTransaction?
    @Published var errorMessage: String?

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
}
