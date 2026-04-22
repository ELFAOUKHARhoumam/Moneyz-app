import Foundation
import Combine

@MainActor
final class DebtViewModel: ObservableObject {
    enum Filter: String, CaseIterable, Identifiable {
        case all
        case open
        case settled
        case iOwe
        case owedToMe

        var id: String { rawValue }

        var localizedKey: String {
            switch self {
            case .all: return "filter.all"
            case .open: return "status.open"
            case .settled: return "status.settled"
            case .iOwe: return DebtDirection.iOwe.localizedKey
            case .owedToMe: return DebtDirection.owedToMe.localizedKey
            }
        }
    }

    @Published var filter: Filter = .all
    @Published var showingEditor = false
    @Published var editingDebt: DebtRecord?
    @Published var errorMessage: String?

    private let summaryService = DebtSummaryService()

    func summary(from debts: [DebtRecord]) -> DebtSummary {
        summaryService.summarize(debts)
    }

    func filteredDebts(from debts: [DebtRecord]) -> [DebtRecord] {
        debts.filter { debt in
            switch filter {
            case .all:
                return true
            case .open:
                return debt.status != .settled
            case .settled:
                return debt.status == .settled
            case .iOwe:
                return debt.direction == .iOwe
            case .owedToMe:
                return debt.direction == .owedToMe
            }
        }
        .sorted {
            let leftDate = $0.dueDate ?? $0.issueDate
            let rightDate = $1.dueDate ?? $1.issueDate
            return leftDate < rightDate
        }
    }

    func presentEditor(for debt: DebtRecord? = nil) {
        editingDebt = debt
        showingEditor = true
    }
}
