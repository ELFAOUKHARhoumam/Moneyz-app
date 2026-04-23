import Foundation
import Combine
import SwiftData

@MainActor
final class PersonBudgetEditorViewModel: ObservableObject {
    typealias UpsertPersonAction = @MainActor (_ name: String, _ emoji: String, _ existingPerson: PersonProfile?, _ context: ModelContext) throws -> PersonProfile
    typealias UpsertBudgetAction = @MainActor (_ person: PersonProfile, _ title: String, _ amountMinor: Int64, _ period: BudgetPeriod, _ salaryCycleStartDay: Int, _ context: ModelContext) throws -> Void

    @Published var name: String
    @Published var emoji: String
    @Published var amountText: String
    @Published var period: BudgetPeriod
    @Published var salaryCycleStartDay: Int
    @Published var errorMessage: String?

    let existingPerson: PersonProfile?

    private let upsertPersonAction: UpsertPersonAction
    private let upsertBudgetAction: UpsertBudgetAction

    init(
        person: PersonProfile?,
        upsertPersonAction: UpsertPersonAction? = nil,
        upsertBudgetAction: UpsertBudgetAction? = nil
    ) {
        existingPerson = person
        name = person?.name ?? ""
        emoji = person?.emoji ?? "🙂"
        amountText = CurrencyFormatter.decimalString(from: person?.activeBudget?.amountMinor ?? 0)
        period = person?.activeBudget?.period ?? .month
        salaryCycleStartDay = person?.activeBudget?.salaryCycleStartDay ?? 1
        self.upsertPersonAction = upsertPersonAction ?? { name, emoji, existingPerson, context in
            try BudgetRepository().upsertPerson(name: name, emoji: emoji, existing: existingPerson, in: context)
        }
        self.upsertBudgetAction = upsertBudgetAction ?? { person, title, amountMinor, period, salaryCycleStartDay, context in
            try BudgetRepository().upsertBudget(
                for: person,
                title: title,
                amountMinor: amountMinor,
                period: period,
                salaryCycleStartDay: salaryCycleStartDay,
                in: context
            )
        }
    }

    var titleKey: String {
        existingPerson == nil ? "budget.person.add" : "budget.person.edit"
    }

    func save(locale: Locale, in context: ModelContext) -> Bool {
        guard let amountMinor = CurrencyFormatter.minorUnits(from: amountText, locale: locale), amountMinor >= 0 else {
            errorMessage = AppLocalizer.string("validation.amount")
            return false
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = AppLocalizer.string("validation.name")
            return false
        }

        do {
            let person = try upsertPersonAction(trimmedName, emoji, existingPerson, context)
            try upsertBudgetAction(
                person,
                "\(person.name) \(AppLocalizer.string("budget.plan.defaultTitle"))",
                amountMinor,
                period,
                salaryCycleStartDay,
                context
            )
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}