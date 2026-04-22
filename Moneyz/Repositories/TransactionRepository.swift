import Foundation
import SwiftData

struct TransactionDraft {
    var amountMinor: Int64
    var kind: TransactionKind
    var transactionDate: Date
    var customItemName: String?
    var note: String
    var category: TransactionCategory?
    var item: CategoryItem?
    var person: PersonProfile?
}

struct TransactionRepository {
    func upsert(existing: MoneyTransaction?, draft: TransactionDraft, in context: ModelContext) throws {
        if let existing {
            existing.amountMinor = draft.amountMinor
            existing.kind = draft.kind
            existing.transactionDate = draft.transactionDate
            existing.customItemName = draft.customItemName
            existing.note = draft.note
            existing.category = draft.category
            existing.item = draft.item
            existing.person = draft.person
            existing.updatedAt = .now
        } else {
            let transaction = MoneyTransaction(
                amountMinor: draft.amountMinor,
                kind: draft.kind,
                transactionDate: draft.transactionDate,
                customItemName: draft.customItemName,
                note: draft.note,
                category: draft.category,
                item: draft.item,
                person: draft.person
            )
            context.insert(transaction)
        }

        try context.save()
    }

    func delete(_ transaction: MoneyTransaction, in context: ModelContext) throws {
        context.delete(transaction)
        try context.save()
    }
}
