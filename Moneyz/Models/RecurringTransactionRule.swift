import Foundation
import SwiftData

@Model
final class RecurringTransactionRule {
    @Attribute(.unique) var id: UUID
    var title: String
    var amountMinor: Int64
    var kind: TransactionKind
    var frequency: RecurringFrequency
    var nextRunDate: Date
    var isActive: Bool
    var note: String
    var createdAt: Date
    var lastAppliedAt: Date?

    @Relationship(deleteRule: .nullify) var category: TransactionCategory?
    @Relationship(deleteRule: .nullify) var item: CategoryItem?
    @Relationship(deleteRule: .nullify) var person: PersonProfile?

    init(
        id: UUID = UUID(),
        title: String,
        amountMinor: Int64,
        kind: TransactionKind = .expense,
        frequency: RecurringFrequency = .monthly,
        nextRunDate: Date,
        isActive: Bool = true,
        note: String = "",
        createdAt: Date = .now,
        lastAppliedAt: Date? = nil,
        category: TransactionCategory? = nil,
        item: CategoryItem? = nil,
        person: PersonProfile? = nil
    ) {
        self.id = id
        self.title = title
        self.amountMinor = amountMinor
        self.kind = kind
        self.frequency = frequency
        self.nextRunDate = nextRunDate
        self.isActive = isActive
        self.note = note
        self.createdAt = createdAt
        self.lastAppliedAt = lastAppliedAt
        self.category = category
        self.item = item
        self.person = person
    }
}
