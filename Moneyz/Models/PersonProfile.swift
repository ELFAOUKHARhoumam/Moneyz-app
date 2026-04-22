import Foundation
import SwiftData

@Model
final class PersonProfile {
    @Attribute(.unique) var id: UUID
    var name: String
    var emoji: String
    var isArchived: Bool
    var createdAt: Date

    @Relationship(deleteRule: .cascade, inverse: \PersonBudgetPlan.person)
    var budgets: [PersonBudgetPlan]

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String = "🙂",
        isArchived: Bool = false,
        createdAt: Date = .now,
        budgets: [PersonBudgetPlan] = []
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.budgets = budgets
    }

    var activeBudget: PersonBudgetPlan? {
        budgets.first(where: { $0.isActive })
    }
}
