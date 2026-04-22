import Foundation
import SwiftData

struct BudgetRepository {
    func upsertPerson(name: String, emoji: String, existing: PersonProfile?, in context: ModelContext) throws -> PersonProfile {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw NSError(domain: "Moneyz", code: 1, userInfo: [NSLocalizedDescriptionKey: "Name is required."])
        }

        let person = existing ?? PersonProfile(name: trimmedName, emoji: trimmedEmoji.isEmpty ? "🙂" : trimmedEmoji)
        person.name = trimmedName
        person.emoji = trimmedEmoji.isEmpty ? "🙂" : trimmedEmoji
        if existing == nil {
            context.insert(person)
        }
        try context.save()
        return person
    }

    func upsertBudget(
        for person: PersonProfile,
        title: String,
        amountMinor: Int64,
        period: BudgetPeriod,
        salaryCycleStartDay: Int,
        in context: ModelContext
    ) throws {
        let existingBudget = person.budgets.first(where: { $0.isActive }) ?? person.budgets.first
        person.budgets.forEach { $0.isActive = false }

        if let existing = existingBudget {
            existing.title = title
            existing.amountMinor = amountMinor
            existing.period = period
            existing.salaryCycleStartDay = salaryCycleStartDay
            existing.isActive = true
        } else {
            let plan = PersonBudgetPlan(
                title: title,
                amountMinor: amountMinor,
                period: period,
                salaryCycleStartDay: salaryCycleStartDay,
                isActive: true,
                person: person
            )
            context.insert(plan)
        }

        try context.save()
    }

    func archivePerson(_ person: PersonProfile, in context: ModelContext) throws {
        person.isArchived = true
        try context.save()
    }
}
