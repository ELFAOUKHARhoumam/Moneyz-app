import Foundation
import SwiftData

struct DebtDraft {
    var counterpartyName: String
    var amountMinor: Int64
    var direction: DebtDirection
    var issueDate: Date
    var dueDate: Date?
    var status: DebtStatus
    var note: String
}

struct DebtRepository {
    func upsert(existing: DebtRecord?, draft: DebtDraft, in context: ModelContext) throws {
        if let existing {
            existing.counterpartyName = draft.counterpartyName
            existing.amountMinor = draft.amountMinor
            existing.direction = draft.direction
            existing.issueDate = draft.issueDate
            existing.dueDate = draft.dueDate
            existing.status = draft.status
            existing.note = draft.note
            existing.updatedAt = .now
        } else {
            let record = DebtRecord(
                counterpartyName: draft.counterpartyName,
                amountMinor: draft.amountMinor,
                direction: draft.direction,
                issueDate: draft.issueDate,
                dueDate: draft.dueDate,
                status: draft.status,
                note: draft.note
            )
            context.insert(record)
        }

        try context.save()
    }

    func delete(_ debt: DebtRecord, in context: ModelContext) throws {
        context.delete(debt)
        try context.save()
    }
}
