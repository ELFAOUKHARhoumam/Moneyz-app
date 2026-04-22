import Foundation
import OSLog
import SwiftData

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

    static func seedIfNeeded(in context: ModelContext) {
        do {
            var categoryDescriptor = FetchDescriptor<TransactionCategory>()
            categoryDescriptor.fetchLimit = 1
            let hasCategories = try !context.fetch(categoryDescriptor).isEmpty
            guard !hasCategories else { return }

            let grocery = TransactionCategory(name: "Grocery", emoji: "🛒", kind: .expense, sortOrder: 0)
            let car = TransactionCategory(name: "Car", emoji: "🚗", kind: .expense, sortOrder: 1)
            let home = TransactionCategory(name: "Home", emoji: "🏠", kind: .expense, sortOrder: 2)
            let bills = TransactionCategory(name: "Bills", emoji: "📄", kind: .expense, sortOrder: 3)
            let dining = TransactionCategory(name: "Dining", emoji: "🍽️", kind: .expense, sortOrder: 4)
            let salary = TransactionCategory(name: "Salary", emoji: "💼", kind: .income, sortOrder: 5)

            [grocery, car, home, bills, dining, salary].forEach(context.insert)

            [
                CategoryItem(name: "Banana", groupName: "Fruits", emoji: "🍌", sortOrder: 0, category: grocery),
                CategoryItem(name: "Apple", groupName: "Fruits", emoji: "🍎", sortOrder: 1, category: grocery),
                CategoryItem(name: "Tomato", groupName: "Vegetables", emoji: "🍅", sortOrder: 2, category: grocery),
                CategoryItem(name: "Carrot", groupName: "Vegetables", emoji: "🥕", sortOrder: 3, category: grocery),
                CategoryItem(name: "Fuel", emoji: "⛽️", sortOrder: 0, category: car),
                CategoryItem(name: "Loan", emoji: "💳", sortOrder: 1, category: car),
                CategoryItem(name: "Maintenance", emoji: "🧰", sortOrder: 2, category: car),
                CategoryItem(name: "Rent", emoji: "🏘️", sortOrder: 0, category: home),
                CategoryItem(name: "Internet", emoji: "🌐", sortOrder: 0, category: bills),
                CategoryItem(name: "Electricity", emoji: "💡", sortOrder: 1, category: bills),
                CategoryItem(name: "Coffee", emoji: "☕️", sortOrder: 0, category: dining),
                CategoryItem(name: "Monthly Salary", emoji: "💰", sortOrder: 0, category: salary)
            ].forEach(context.insert)

            let presets = [
                GroceryPresetItem(name: "Milk", groupName: "Dairy", emoji: "🥛", sortOrder: 0),
                GroceryPresetItem(name: "Rice", groupName: "Pantry", emoji: "🍚", sortOrder: 1),
                GroceryPresetItem(name: "Chicken", groupName: "Protein", emoji: "🍗", sortOrder: 2),
                GroceryPresetItem(name: "Orange", groupName: "Fruits", emoji: "🍊", sortOrder: 3)
            ]
            presets.forEach(context.insert)

            try context.save()
        } catch {
            logger.error("Failed to seed default data: \(error.localizedDescription, privacy: .public)")
        }
    }

    static func seedPreviewData(in context: ModelContext) {
        do {
            seedIfNeeded(in: context)

            let refs = try previewReferences(in: context)

            let family = PersonProfile(name: "Family", emoji: "👨‍👩‍👧")
            let wife = PersonProfile(name: "Wife", emoji: "🧕")
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

            context.insert(MoneyTransaction(
                amountMinor: 250000,
                kind: .income,
                transactionDate: monthStart,
                customItemName: nil,
                note: "Main salary",
                category: refs.salary,
                item: refs.salaryItem,
                person: family
            ))

            context.insert(MoneyTransaction(
                amountMinor: 12000,
                kind: .expense,
                transactionDate: calendar.date(byAdding: .day, value: 1, to: monthStart) ?? now,
                note: "Weekly groceries",
                category: refs.grocery,
                item: refs.banana,
                person: family
            ))

            context.insert(MoneyTransaction(
                amountMinor: 4500,
                kind: .expense,
                transactionDate: calendar.date(byAdding: .day, value: 2, to: monthStart) ?? now,
                note: "Vegetables",
                category: refs.grocery,
                item: refs.tomato,
                person: wife
            ))

            context.insert(MoneyTransaction(
                amountMinor: 7000,
                kind: .expense,
                transactionDate: calendar.date(byAdding: .day, value: 3, to: monthStart) ?? now,
                note: "Fuel top-up",
                category: refs.car,
                item: refs.fuel,
                person: family
            ))

            context.insert(MoneyTransaction(
                amountMinor: 80000,
                kind: .expense,
                transactionDate: calendar.date(byAdding: .day, value: 4, to: monthStart) ?? now,
                note: "Rent paid",
                category: refs.home,
                item: refs.rent,
                person: family
            ))

            context.insert(MoneyTransaction(
                amountMinor: 3500,
                kind: .expense,
                transactionDate: calendar.date(byAdding: .day, value: 5, to: monthStart) ?? now,
                note: "Internet bill",
                category: refs.bills,
                item: refs.internet,
                person: family
            ))

            let debt1 = DebtRecord(counterpartyName: "Ahmed", amountMinor: 25000, direction: .owedToMe, dueDate: calendar.date(byAdding: .day, value: 10, to: now), note: "Lent for school fees")
            let debt2 = DebtRecord(counterpartyName: "Garage", amountMinor: 18000, direction: .iOwe, dueDate: calendar.date(byAdding: .day, value: 20, to: now), note: "Car repair balance")
            context.insert(debt1)
            context.insert(debt2)

            let recurring = RecurringTransactionRule(title: "Rent", amountMinor: 80000, kind: .expense, frequency: .monthly, nextRunDate: calendar.date(byAdding: .month, value: 1, to: monthStart) ?? now, note: "Monthly rent", category: refs.home, item: refs.rent, person: family)
            context.insert(recurring)

            let groceryList = GroceryList(
                title: AppLocalizer.string("grocery.list.thisWeek", fallback: "This Week")
            )
            context.insert(groceryList)
            [
                GroceryListItem(name: "Milk", groupName: "Dairy", emoji: "🥛", sortOrder: 0, list: groceryList),
                GroceryListItem(name: "Banana", groupName: "Fruits", emoji: "🍌", sortOrder: 1, list: groceryList),
                GroceryListItem(name: "Rice", groupName: "Pantry", emoji: "🍚", sortOrder: 2, list: groceryList)
            ].forEach(context.insert)

            try context.save()
        } catch {
            logger.error("Failed to seed preview data: \(error.localizedDescription, privacy: .public)")
        }
    }

    private static func previewReferences(in context: ModelContext) throws -> PreviewReferences {
        let categories = try context.fetch(FetchDescriptor<TransactionCategory>())
        let grocery = categories.first(where: { $0.name == "Grocery" })
        let salary = categories.first(where: { $0.name == "Salary" })
        let car = categories.first(where: { $0.name == "Car" })
        let bills = categories.first(where: { $0.name == "Bills" })
        let home = categories.first(where: { $0.name == "Home" })

        return PreviewReferences(
            grocery: grocery,
            salary: salary,
            car: car,
            bills: bills,
            home: home,
            tomato: grocery?.items.first(where: { $0.name == "Tomato" }),
            banana: grocery?.items.first(where: { $0.name == "Banana" }),
            fuel: car?.items.first(where: { $0.name == "Fuel" }),
            rent: home?.items.first(where: { $0.name == "Rent" }),
            salaryItem: salary?.items.first(where: { $0.name == "Monthly Salary" }),
            internet: bills?.items.first(where: { $0.name == "Internet" })
        )
    }
}
