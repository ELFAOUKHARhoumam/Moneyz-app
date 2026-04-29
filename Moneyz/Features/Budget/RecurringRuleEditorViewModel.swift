import Foundation
import Combine
import SwiftData

@MainActor
final class RecurringRuleEditorViewModel: ObservableObject {
    typealias SaveRuleAction = @MainActor (_ existingRule: RecurringTransactionRule?, _ draft: RecurringRuleDraft, _ context: ModelContext) throws -> Void
    typealias DeleteRuleAction = @MainActor (_ rule: RecurringTransactionRule, _ context: ModelContext) throws -> Void

    @Published var title: String
    @Published var amountText: String
    @Published var kind: TransactionKind
    @Published var frequency: RecurringFrequency
    @Published var nextRunDate: Date
    @Published var note: String
    @Published var selectedCategoryID: UUID?
    @Published var selectedItemID: UUID?
    @Published var selectedPersonID: UUID?
    @Published var errorMessage: String?

    let existingRule: RecurringTransactionRule?

    private let calendar: Calendar
    private let saveRuleAction: SaveRuleAction
    private let deleteRuleAction: DeleteRuleAction

    init(
        rule: RecurringTransactionRule?,
        calendar: Calendar = .current,
        saveRuleAction: SaveRuleAction? = nil,
        deleteRuleAction: DeleteRuleAction? = nil
    ) {
        existingRule = rule
        self.calendar = calendar
        title = rule?.title ?? ""
        amountText = CurrencyFormatter.decimalString(from: rule?.amountMinor ?? 0)
        kind = rule?.kind ?? .expense
        frequency = rule?.frequency ?? .monthly
        nextRunDate = rule?.nextRunDate ?? .now
        note = rule?.note ?? ""
        selectedCategoryID = rule?.category?.id
        selectedItemID = rule?.item?.id
        selectedPersonID = rule?.person?.id
        self.saveRuleAction = saveRuleAction ?? { existingRule, draft, context in
            try RecurringRuleRepository().upsert(existing: existingRule, draft: draft, in: context)
        }
        self.deleteRuleAction = deleteRuleAction ?? { rule, context in
            try RecurringRuleRepository().delete(rule, in: context)
        }
    }

    var titleKey: String {
        existingRule == nil ? "budget.fixed.add" : "budget.fixed.edit"
    }

    func save(
        categories: [TransactionCategory],
        people: [PersonProfile],
        locale: Locale,
        in context: ModelContext
    ) -> Bool {
        guard let amountMinor = CurrencyFormatter.minorUnits(from: amountText, locale: locale), amountMinor > 0 else {
            errorMessage = AppLocalizer.string("validation.amount")
            return false
        }

        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = AppLocalizer.string("validation.name")
            return false
        }

        let selectedCategory = categories.first(where: { $0.id == selectedCategoryID })
        let selectedItem = selectedCategory?.items.first(where: { $0.id == selectedItemID })
        let selectedPerson = people.first(where: { $0.id == selectedPersonID })

        let draft = RecurringRuleDraft(
            title: trimmedTitle,
            amountMinor: amountMinor,
            kind: kind,
            frequency: frequency,
            nextRunDate: calendar.startOfDay(for: nextRunDate),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            category: selectedCategory,
            item: selectedItem,
            person: selectedPerson
        )

        do {
            try saveRuleAction(existingRule, draft, context)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete(in context: ModelContext) -> Bool {
        guard let existingRule else { return false }

        do {
            try deleteRuleAction(existingRule, context)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}