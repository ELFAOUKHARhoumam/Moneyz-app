import Foundation
import Combine
import SwiftData

@MainActor
final class BudgetViewModel: ObservableObject {
    @Published var rangeOption: TimeRangeOption = .month
    @Published var showingPersonEditor = false
    @Published var showingRuleEditor = false
    @Published var editingPerson: PersonProfile?
    @Published var editingRule: RecurringTransactionRule?
    @Published var pendingDeletionRule: RecurringTransactionRule?
    @Published var errorMessage: String?

    private let insightsService = BudgetInsightsService()
    private let deleteRuleAction: @MainActor (RecurringTransactionRule, ModelContext) throws -> Void
    private let toggleActiveAction: @MainActor (RecurringTransactionRule, ModelContext) throws -> Void

    init(
        deleteRuleAction: (@MainActor (RecurringTransactionRule, ModelContext) throws -> Void)? = nil,
        toggleActiveAction: (@MainActor (RecurringTransactionRule, ModelContext) throws -> Void)? = nil
    ) {
        self.deleteRuleAction = deleteRuleAction ?? { rule, context in
            try RecurringRuleRepository().delete(rule, in: context)
        }
        self.toggleActiveAction = toggleActiveAction ?? { rule, context in
            rule.isActive.toggle()
            try context.save()
        }
    }

    convenience init(
        _ deleteRuleAction: @escaping @MainActor (RecurringTransactionRule, ModelContext) throws -> Void
    ) {
        self.init(deleteRuleAction: deleteRuleAction, toggleActiveAction: nil)
    }

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

    func delete(_ rule: RecurringTransactionRule, in context: ModelContext) {
        do {
            try deleteRuleAction(rule, context)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func requestDelete(_ rule: RecurringTransactionRule) {
        pendingDeletionRule = rule
    }

    func confirmDelete(in context: ModelContext) {
        guard let rule = pendingDeletionRule else { return }
        delete(rule, in: context)
        pendingDeletionRule = nil
    }

    func cancelPendingDelete() {
        pendingDeletionRule = nil
    }

    func toggleActive(_ rule: RecurringTransactionRule, in context: ModelContext) {
        do {
            try toggleActiveAction(rule, context)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
