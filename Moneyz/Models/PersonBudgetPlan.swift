import Foundation
import SwiftData

@Model
final class PersonBudgetPlan {
    @Attribute(.unique) var id: UUID
    var title: String
    var amountMinor: Int64
    var period: BudgetPeriod
    var salaryCycleStartDay: Int
    var isActive: Bool
    var createdAt: Date

    var person: PersonProfile?

    init(
        id: UUID = UUID(),
        title: String,
        amountMinor: Int64,
        period: BudgetPeriod = .month,
        salaryCycleStartDay: Int = 1,
        isActive: Bool = true,
        createdAt: Date = .now,
        person: PersonProfile? = nil
    ) {
        self.id = id
        self.title = title
        self.amountMinor = amountMinor
        self.period = period
        self.salaryCycleStartDay = salaryCycleStartDay
        self.isActive = isActive
        self.createdAt = createdAt
        self.person = person
    }
}
