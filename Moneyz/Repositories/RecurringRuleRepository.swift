import Foundation
import SwiftData

struct RecurringRuleDraft {
    var title: String
    var amountMinor: Int64
    var kind: TransactionKind
    var frequency: RecurringFrequency
    var nextRunDate: Date
    var note: String
    var category: TransactionCategory?
    var item: CategoryItem?
    var person: PersonProfile?
}

struct RecurringRuleRepository {
    func upsert(existing: RecurringTransactionRule?, draft: RecurringRuleDraft, in context: ModelContext) throws {
        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let normalizedNextRunDate = Calendar.current.startOfDay(for: draft.nextRunDate)

        if let existing {
            existing.title = trimmedTitle
            existing.amountMinor = draft.amountMinor
            existing.kind = draft.kind
            existing.frequency = draft.frequency
            existing.nextRunDate = normalizedNextRunDate
            existing.note = draft.note
            existing.category = draft.category
            existing.item = draft.item
            existing.person = draft.person
        } else {
            let rule = RecurringTransactionRule(
                title: trimmedTitle,
                amountMinor: draft.amountMinor,
                kind: draft.kind,
                frequency: draft.frequency,
                nextRunDate: normalizedNextRunDate,
                note: draft.note,
                category: draft.category,
                item: draft.item,
                person: draft.person
            )
            context.insert(rule)
        }

        try context.save()
    }

    func delete(_ rule: RecurringTransactionRule, in context: ModelContext) throws {
        context.delete(rule)
        try context.save()
    }
}
