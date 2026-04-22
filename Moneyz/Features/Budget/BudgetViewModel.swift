import Foundation
import Combine

@MainActor
final class BudgetViewModel: ObservableObject {
    @Published var rangeOption: TimeRangeOption = .month
    @Published var showingPersonEditor = false
    @Published var showingRuleEditor = false
    @Published var editingPerson: PersonProfile?
    @Published var editingRule: RecurringTransactionRule?
    @Published var errorMessage: String?

    private let insightsService = BudgetInsightsService()

    func interval(settings: SettingsStore) -> DateInterval {
        DateRangeService.interval(
            for: rangeOption,
            reference: .now,
            salaryCycleStartDay: settings.salaryCycleStartDay
        )
    }

    func snapshots(
        people: [PersonProfile],
        transactions: [MoneyTransaction],
        settings: SettingsStore
    ) -> [PersonBudgetSnapshot] {
        insightsService.snapshots(
            people: people.filter { !$0.isArchived },
            transactions: transactions,
            interval: interval(settings: settings)
        )
    }

    func presentPersonEditor(for person: PersonProfile? = nil) {
        editingPerson = person
        showingPersonEditor = true
    }

    func presentRuleEditor(for rule: RecurringTransactionRule? = nil) {
        editingRule = rule
        showingRuleEditor = true
    }
}
