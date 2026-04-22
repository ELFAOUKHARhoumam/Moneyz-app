import Foundation
import SwiftData
import XCTest
@testable import Moneyz

final class RecurringTransactionServiceTests: XCTestCase {
    private var calendar: Calendar!
    private var service: RecurringTransactionService!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        service = RecurringTransactionService(calendar: calendar)
    }

    func testRepeatedLaunchesDoNotCreateDuplicates() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let referenceDate = date("2026-04-21")
        let rule = makeRule(nextRunDate: date("2026-04-21"))
        context.insert(rule)
        try context.save()

        XCTAssertEqual(try service.applyDueRules(on: referenceDate, in: context), 1)
        XCTAssertEqual(try service.applyDueRules(on: referenceDate, in: context), 0)
        XCTAssertEqual(try fetchTransactions(in: context).count, 1)
        XCTAssertEqual(try fetchRule(id: rule.id, in: context)?.nextRunDate, date("2026-05-21"))
    }

    func testRepeatedForegroundEventsDoNotCreateDuplicates() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let referenceDate = date("2026-04-21")
        context.insert(makeRule(nextRunDate: date("2026-04-20")))
        try context.save()

        XCTAssertEqual(try service.applyDueRules(on: referenceDate, in: context), 1)
        XCTAssertEqual(try service.applyDueRules(on: referenceDate, in: context), 0)

        let transactions = try fetchTransactions(in: context)
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.map(\.transactionDate).sorted(), [date("2026-04-20")])
    }

    func testMissedIntervalsCatchUpExactlyOncePerInterval() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let referenceDate = date("2026-05-05")
        context.insert(makeRule(frequency: .weekly, nextRunDate: date("2026-04-14")))
        try context.save()

        XCTAssertEqual(try service.applyDueRules(on: referenceDate, in: context), 4)

        let transactions = try fetchTransactions(in: context)
        XCTAssertEqual(transactions.map(\.transactionDate).sorted(), [
            date("2026-04-14"), date("2026-04-21"), date("2026-04-28"), date("2026-05-05")
        ])
    }

    func testInactiveRulesAreIgnored() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.insert(makeRule(nextRunDate: date("2026-04-21"), isActive: false))
        try context.save()

        XCTAssertEqual(try service.applyDueRules(on: date("2026-04-21"), in: context), 0)
        XCTAssertTrue(try fetchTransactions(in: context).isEmpty)
    }

    func testSameDayRunsApplyOnlyOnce() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.insert(makeRule(nextRunDate: date("2026-04-21")))
        try context.save()

        XCTAssertEqual(try service.applyDueRules(on: date("2026-04-21"), in: context), 1)
        XCTAssertEqual(try service.applyDueRules(on: date("2026-04-21"), in: context), 0)
        XCTAssertEqual(try fetchTransactions(in: context).count, 1)
    }

    func testExistingTransactionPreventsDuplicateAndAdvancesRule() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let rule = makeRule(nextRunDate: date("2026-04-21"))
        context.insert(rule)
        context.insert(
            MoneyTransaction(
                amountMinor: rule.amountMinor,
                kind: rule.kind,
                transactionDate: date("2026-04-21"),
                customItemName: rule.title,
                note: rule.note,
                isRecurringInstance: true,
                recurringSourceID: rule.id
            )
        )
        try context.save()

        XCTAssertEqual(try service.applyDueRules(on: date("2026-04-21"), in: context), 0)
        XCTAssertEqual(try fetchTransactions(in: context).count, 1)
        XCTAssertEqual(try fetchRule(id: rule.id, in: context)?.nextRunDate, date("2026-05-21"))
    }

    func testDateBoundaryUsesStartOfDay() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        context.insert(makeRule(nextRunDate: date("2026-04-21")))
        try context.save()

        XCTAssertEqual(try service.applyDueRules(on: dateTime("2026-04-21T23:59:00Z"), in: context), 1)
        let transactions = try fetchTransactions(in: context)
        XCTAssertEqual(transactions.count, 1)
        XCTAssertEqual(transactions.first?.transactionDate, date("2026-04-21"))
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            TransactionCategory.self,
            CategoryItem.self,
            PersonProfile.self,
            PersonBudgetPlan.self,
            MoneyTransaction.self,
            DebtRecord.self,
            RecurringTransactionRule.self,
            GroceryList.self,
            GroceryListItem.self,
            GroceryPresetItem.self
        ])
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private func makeRule(
        frequency: RecurringFrequency = .monthly,
        nextRunDate: Date,
        isActive: Bool = true
    ) -> RecurringTransactionRule {
        RecurringTransactionRule(
            title: "Salary",
            amountMinor: 125_000,
            kind: .income,
            frequency: frequency,
            nextRunDate: nextRunDate,
            isActive: isActive,
            note: "Recurring"
        )
    }

    private func fetchTransactions(in context: ModelContext) throws -> [MoneyTransaction] {
        try context.fetch(FetchDescriptor<MoneyTransaction>()).sorted { $0.transactionDate < $1.transactionDate }
    }

    private func fetchRule(id: UUID, in context: ModelContext) throws -> RecurringTransactionRule? {
        try context.fetch(FetchDescriptor<RecurringTransactionRule>()).first(where: { $0.id == id })
    }

    private func date(_ string: String) -> Date {
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.timeZone = calendar.timeZone
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: string)!
    }

    private func dateTime(_ string: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = calendar.timeZone
        return formatter.date(from: string)!
    }
}
