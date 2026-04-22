import Foundation
import SwiftData

@Model
final class DebtRecord {
    @Attribute(.unique) var id: UUID
    var counterpartyName: String
    var amountMinor: Int64
    var direction: DebtDirection
    var issueDate: Date
    var dueDate: Date?
    var status: DebtStatus
    var note: String
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        counterpartyName: String,
        amountMinor: Int64,
        direction: DebtDirection,
        issueDate: Date = .now,
        dueDate: Date? = nil,
        status: DebtStatus = .open,
        note: String = "",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.counterpartyName = counterpartyName
        self.amountMinor = amountMinor
        self.direction = direction
        self.issueDate = issueDate
        self.dueDate = dueDate
        self.status = status
        self.note = note
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
