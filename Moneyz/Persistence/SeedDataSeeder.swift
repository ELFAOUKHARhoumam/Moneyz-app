import Foundation
import OSLog
import SwiftData

// MARK: - SeedDataSeeder
// FIX 1: All category/item/group names now use AppLocalizer with English fallbacks.
//         Root cause: hardcoded English strings meant Arabic users saw English seed data.
// FIX 2: previewReferences now matches categories by a stable internal tag stored in the
//         category's emoji field prefix — robust against localization changes.
//         Root cause: matching by localized name broke when the name changed per language.

enum SeedDataSeeder {
    private static let logger = Logger(subsystem: "com.houmam.Moneyz", category: "SeedDataSeeder")

    private struct PreviewReferences {
        let grocery: TransactionCategory?
        let salary: TransactionCategory?
        let car: TransactionCategory?
        let bills: TransactionCategory?
        let home: TransactionCategory?
        let tomato: CategoryItem?
        let banana: CategoryItem?
        let fuel: CategoryItem?
        let rent: CategoryItem?
        let salaryItem: CategoryItem?
        let internet: CategoryItem?
    }

    // MARK: - Localization Keys

    private enum SeedKey {
        static let grocery       = "seed.category.grocery"
        static let car           = "seed.category.car"
        static let home          = "seed.category.home"
        static let bills         = "seed.category.bills"
        static let dining        = "seed.category.dining"
        static let salary        = "seed.category.salary"

        static let banana        = "seed.item.banana"
        static let apple         = "seed.item.apple"
        static let tomato        = "seed.item.tomato"
        static let carrot        = "seed.item.carrot"
        static let fuel          = "seed.item.fuel"
        static let loan          = "seed.item.loan"
        static let maintenance   = "seed.item.maintenance"
        static let rent          = "seed.item.rent"
        static let internet      = "seed.item.internet"
        static let electricity   = "seed.item.electricity"
        static let coffee        = "seed.item.coffee"
        static let monthlySalary = "seed.item.monthlySalary"

        static let groupFruits     = "seed.group.fruits"
        static let groupVegetables = "seed.group.vegetables"
        static let groupDairy      = "seed.group.dairy"
        static let groupPantry     = "seed.group.pantry"
        static let groupProtein    = "seed.group.protein"

        static let presetMilk    = "seed.preset.milk"
        static let presetRice    = "seed.preset.rice"
        static let presetChicken = "seed.preset.chicken"
        static let presetOrange  = "seed.preset.orange"
    }

    // Stable emoji identifiers — these are pure Unicode scalars with no variation selectors.
    // We use these to look up seeded categories later, independently of their localized name.
    // This avoids the variation-selector matching issue with emoji like ⛽️ vs ⛽.
    private enum SeedEmoji {
        static let grocery = "🛒"
        static let car     = "🚗"
        static let home    = "🏠"
        static let bills   = "📄"
        static let dining  = "🍽️"
        static let salary  = "💼"

        static let banana  = "🍌"
        static let tomato  = "🍅"
        static let fuel    = "⛽"    // no variation selector — safe for string matching
        static let rent    = "🏘️"
        static let salary2 = "💰"
        static let internet = "🌐"
    }

    // MARK: - Seed If Needed (idempotent)

    static func seedIfNeeded(in context: ModelContext) {
        do {
            var descriptor = FetchDescriptor<TransactionCategory>()
            descriptor.fetchLimit = 1
            guard try context.fetch(descriptor).isEmpty else { return }

            let grocery = TransactionCategory(name: AppLocalizer.string(SeedKey.grocery, fallback: "Grocery"), emoji: SeedEmoji.grocery, kind: .expense, sortOrder: 0)
            let car     = TransactionCategory(name: AppLocalizer.string(SeedKey.car, fallback: "Car"), emoji: SeedEmoji.car, kind: .expense, sortOrder: 1)
            let home    = TransactionCategory(name: AppLocalizer.string(SeedKey.home, fallback: "Home"), emoji: SeedEmoji.home, kind: .expense, sortOrder: 2)
            let bills   = TransactionCategory(name: AppLocalizer.string(SeedKey.bills, fallback: "Bills"), emoji: SeedEmoji.bills, kind: .expense, sortOrder: 3)
            let dining  = TransactionCategory(name: AppLocalizer.string(SeedKey.dining, fallback: "Dining"), emoji: SeedEmoji.dining, kind: .expense, sortOrder: 4)
            let salary  = TransactionCategory(name: AppLocalizer.string(SeedKey.salary, fallback: "Salary"), emoji: SeedEmoji.salary, kind: .income, sortOrder: 5)

            [grocery, car, home, bills, dining, salary].forEach(context.insert)

            let fruits = AppLocalizer.string(SeedKey.groupFruits, fallback: "Fruits")
            let veg    = AppLocalizer.string(SeedKey.groupVegetables, fallback: "Vegetables")

            [
                CategoryItem(name: AppLocalizer.string(SeedKey.banana, fallback: "Banana"), groupName: fruits, emoji: SeedEmoji.banana, sortOrder: 0, category: grocery),
                CategoryItem(name: AppLocalizer.string(SeedKey.apple, fallback: "Apple"), groupName: fruits, emoji: "🍎", sortOrder: 1, category: grocery),
                CategoryItem(name: AppLocalizer.string(SeedKey.tomato, fallback: "Tomato"), groupName: veg, emoji: SeedEmoji.tomato, sortOrder: 2, category: grocery),
                CategoryItem(name: AppLocalizer.string(SeedKey.carrot, fallback: "Carrot"), groupName: veg, emoji: "🥕", sortOrder: 3, category: grocery),
                CategoryItem(name: AppLocalizer.string(SeedKey.fuel, fallback: "Fuel"), emoji: SeedEmoji.fuel, sortOrder: 0, category: car),
                CategoryItem(name: AppLocalizer.string(SeedKey.loan, fallback: "Loan"), emoji: "💳", sortOrder: 1, category: car),
                CategoryItem(name: AppLocalizer.string(SeedKey.maintenance, fallback: "Maintenance"), emoji: "🧰", sortOrder: 2, category: car),
                CategoryItem(name: AppLocalizer.string(SeedKey.rent, fallback: "Rent"), emoji: SeedEmoji.rent, sortOrder: 0, category: home),
                CategoryItem(name: AppLocalizer.string(SeedKey.internet, fallback: "Internet"), emoji: SeedEmoji.internet, sortOrder: 0, category: bills),
                CategoryItem(name: AppLocalizer.string(SeedKey.electricity, fallback: "Electricity"), emoji: "💡", sortOrder: 1, category: bills),
                CategoryItem(name: AppLocalizer.string(SeedKey.coffee, fallback: "Coffee"), emoji: "☕", sortOrder: 0, category: dining),
                CategoryItem(name: AppLocalizer.string(SeedKey.monthlySalary, fallback: "Monthly Salary"), emoji: SeedEmoji.salary2, sortOrder: 0, category: salary)
            ].forEach(context.insert)

            [
                GroceryPresetItem(name: AppLocalizer.string(SeedKey.presetMilk, fallback: "Milk"), groupName: AppLocalizer.string(SeedKey.groupDairy, fallback: "Dairy"), emoji: "🥛", sortOrder: 0),
                GroceryPresetItem(name: AppLocalizer.string(SeedKey.presetRice, fallback: "Rice"), groupName: AppLocalizer.string(SeedKey.groupPantry, fallback: "Pantry"), emoji: "🍚", sortOrder: 1),
                GroceryPresetItem(name: AppLocalizer.string(SeedKey.presetChicken, fallback: "Chicken"), groupName: AppLocalizer.string(SeedKey.groupProtein, fallback: "Protein"), emoji: "🍗", sortOrder: 2),
                GroceryPresetItem(name: AppLocalizer.string(SeedKey.presetOrange, fallback: "Orange"), groupName: AppLocalizer.string(SeedKey.groupFruits, fallback: "Fruits"), emoji: "🍊", sortOrder: 3)
            ].forEach(context.insert)

            try context.save()
        } catch {
            logger.error("Failed to seed default data: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Seed Preview Data

    static func seedPreviewData(in context: ModelContext) {
        do {
            seedIfNeeded(in: context)
            let refs = try previewReferences(in: context)

            let family = PersonProfile(name: "Family", emoji: "👨‍👩‍👧")
            let wife   = PersonProfile(name: "Wife", emoji: "🧕")
            context.insert(family)
            context.insert(wife)

            let familyBudget = PersonBudgetPlan(title: "Family Monthly", amountMinor: 90000, period: .month)
            familyBudget.person = family
            let wifeBudget = PersonBudgetPlan(title: "Wife Monthly", amountMinor: 30000, period: .month)
            wifeBudget.person = wife
            context.insert(familyBudget)
            context.insert(wifeBudget)

            let now = Date()
            let calendar = Calendar.current
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now

            let transactionData: [(Int64, TransactionKind, Int, String, TransactionCategory?, CategoryItem?, PersonProfile?)] = [
                (250000, .income,  0, "Main salary",      refs.salary,  refs.salaryItem, family),
                (12000,  .expense, 1, "Weekly groceries", refs.grocery, refs.banana,     family),
                (4500,   .expense, 2, "Vegetables",       refs.grocery, refs.tomato,     wife),
                (7000,   .expense, 3, "Fuel top-up",      refs.car,     refs.fuel,       family),
                (80000,  .expense, 4, "Rent paid",        refs.home,    refs.rent,       family),
                (3500,   .expense, 5, "Internet bill",    refs.bills,   refs.internet,   family),
            ]

            for (amount, kind, dayOffset, note, category, item, person) in transactionData {
                context.insert(MoneyTransaction(
                    amountMinor: amount,
                    kind: kind,
                    transactionDate: calendar.date(byAdding: .day, value: dayOffset, to: monthStart) ?? now,
                    note: note,
                    category: category,
                    item: item,
                    person: person
                ))
            }

            context.insert(DebtRecord(counterpartyName: "Ahmed", amountMinor: 25000, direction: .owedToMe, dueDate: calendar.date(byAdding: .day, value: 10, to: now), note: "Lent for school fees"))
            context.insert(DebtRecord(counterpartyName: "Garage", amountMinor: 18000, direction: .iOwe, dueDate: calendar.date(byAdding: .day, value: 20, to: now), note: "Car repair balance"))

            context.insert(RecurringTransactionRule(
                title: AppLocalizer.string(SeedKey.rent, fallback: "Rent"),
                amountMinor: 80000, kind: .expense, frequency: .monthly,
                nextRunDate: calendar.date(byAdding: .month, value: 1, to: monthStart) ?? now,
                note: "Monthly rent",
                category: refs.home, item: refs.rent, person: family
            ))

            let groceryList = GroceryList(title: AppLocalizer.string("grocery.list.thisWeek", fallback: "This Week"))
            context.insert(groceryList)
            [
                GroceryListItem(name: AppLocalizer.string(SeedKey.presetMilk, fallback: "Milk"), groupName: AppLocalizer.string(SeedKey.groupDairy, fallback: "Dairy"), emoji: "🥛", sortOrder: 0, list: groceryList),
                GroceryListItem(name: AppLocalizer.string(SeedKey.banana, fallback: "Banana"), groupName: AppLocalizer.string(SeedKey.groupFruits, fallback: "Fruits"), emoji: SeedEmoji.banana, sortOrder: 1, list: groceryList),
                GroceryListItem(name: AppLocalizer.string(SeedKey.presetRice, fallback: "Rice"), groupName: AppLocalizer.string(SeedKey.groupPantry, fallback: "Pantry"), emoji: "🍚", sortOrder: 2, list: groceryList)
            ].forEach(context.insert)

            try context.save()
        } catch {
            logger.error("Failed to seed preview data: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Preview References
    // FIX: match by the stable emoji string stored in SeedEmoji, not by localized name.
    // Root cause of previous approach: matching "Grocery".localizedCaseInsensitiveCompare
    // broke in Arabic because the seeded name was "البقالة", not "Grocery".
    // Now we match by emoji which is language-independent and set from SeedEmoji constants.

    private static func previewReferences(in context: ModelContext) throws -> PreviewReferences {
        let categories = try context.fetch(FetchDescriptor<TransactionCategory>())

        let grocery = categories.first(where: { $0.emoji == SeedEmoji.grocery })
        let salary  = categories.first(where: { $0.emoji == SeedEmoji.salary })
        let car     = categories.first(where: { $0.emoji == SeedEmoji.car })
        let bills   = categories.first(where: { $0.emoji == SeedEmoji.bills })
        let home    = categories.first(where: { $0.emoji == SeedEmoji.home })

        return PreviewReferences(
            grocery:    grocery,
            salary:     salary,
            car:        car,
            bills:      bills,
            home:       home,
            tomato:     grocery?.items.first(where: { $0.emoji == SeedEmoji.tomato }),
            banana:     grocery?.items.first(where: { $0.emoji == SeedEmoji.banana }),
            fuel:       car?.items.first(where: { $0.emoji.hasPrefix("⛽") }),   // handles variation selectors
            rent:       home?.items.first(where: { $0.emoji.hasPrefix("🏘") }),  // handles variation selectors
            salaryItem: salary?.items.first(where: { $0.emoji == SeedEmoji.salary2 }),
            internet:   bills?.items.first(where: { $0.emoji == SeedEmoji.internet })
        )
    }
}
