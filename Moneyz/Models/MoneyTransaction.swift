import Foundation
import SwiftData

@Model
final class MoneyTransaction {
    @Attribute(.unique) var id: UUID
    var amountMinor: Int64
    var kind: TransactionKind
    var transactionDate: Date
    var customItemName: String?
    var note: String
    var isRecurringInstance: Bool
    var recurringSourceID: UUID?
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .nullify) var category: TransactionCategory?
    @Relationship(deleteRule: .nullify) var item: CategoryItem?
    @Relationship(deleteRule: .nullify) var person: PersonProfile?

    init(
        id: UUID = UUID(),
        amountMinor: Int64,
        kind: TransactionKind,
        transactionDate: Date = .now,
        customItemName: String? = nil,
        note: String = "",
        isRecurringInstance: Bool = false,
        recurringSourceID: UUID? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now,
        category: TransactionCategory? = nil,
        item: CategoryItem? = nil,
        person: PersonProfile? = nil
    ) {
        self.id = id
        self.amountMinor = amountMinor
        self.kind = kind
        self.transactionDate = transactionDate
        self.customItemName = customItemName
        self.note = note
        self.isRecurringInstance = isRecurringInstance
        self.recurringSourceID = recurringSourceID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.category = category
        self.item = item
        self.person = person
    }

    var signedMinorAmount: Int64 {
        kind.multiplier * amountMinor
    }

    var displayTitle: String {
        if let customItemName, !customItemName.isEmpty { return customItemName }
        if let item { return item.name }
        if let category { return category.name }
        return note.isEmpty ? "Transaction" : note
    }
}
