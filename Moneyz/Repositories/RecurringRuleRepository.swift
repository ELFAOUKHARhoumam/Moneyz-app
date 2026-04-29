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
    private let calendar: Calendar

    init(calendar: Calendar = .current) {
        self.calendar = calendar
    }

    func upsert(existing: RecurringTransactionRule?, draft: RecurringRuleDraft, in context: ModelContext) throws {
        let trimmedTitle = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else { return }

        let normalizedNextRunDate = calendar.startOfDay(for: draft.nextRunDate)

        if let existing {
            update(existing, with: draft, title: trimmedTitle, nextRunDate: normalizedNextRunDate)
        } else {
            if let duplicate = try findDuplicate(
                title: trimmedTitle,
                kind: draft.kind,
                frequency: draft.frequency,
                amountMinor: draft.amountMinor,
                in: context
            ) {
                update(duplicate, with: draft, title: trimmedTitle, nextRunDate: normalizedNextRunDate)
                duplicate.isActive = true
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
        }

        try context.save()
    }

    func delete(_ rule: RecurringTransactionRule, in context: ModelContext) throws {
        context.delete(rule)
        try context.save()
    }

    private func update(_ rule: RecurringTransactionRule, with draft: RecurringRuleDraft, title: String, nextRunDate: Date) {
        rule.title = title
        rule.amountMinor = draft.amountMinor
        rule.kind = draft.kind
        rule.frequency = draft.frequency
        rule.nextRunDate = nextRunDate
        rule.note = draft.note
        rule.category = draft.category
        rule.item = draft.item
        rule.person = draft.person
    }

    private func findDuplicate(
        title: String,
        kind: TransactionKind,
        frequency: RecurringFrequency,
        amountMinor: Int64,
        in context: ModelContext
    ) throws -> RecurringTransactionRule? {
        let all = try context.fetch(FetchDescriptor<RecurringTransactionRule>())
        return all.first { rule in
            rule.title.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(title) == .orderedSame &&
            rule.kind == kind &&
            rule.frequency == frequency &&
            rule.amountMinor == amountMinor
        }
    }
}
