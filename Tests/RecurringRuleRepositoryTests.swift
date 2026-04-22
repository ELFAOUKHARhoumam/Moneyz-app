#if canImport(XCTest)
import SwiftData
import XCTest
@testable import Moneyz

final class RecurringRuleRepositoryTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    func testUpsertTrimsTitleAndNormalizesNextRunDate() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let repository = RecurringRuleRepository(calendar: calendar)

        let draft = RecurringRuleDraft(
            title: "  Salary  ",
            amountMinor: 125_000,
            kind: .income,
            frequency: .monthly,
            nextRunDate: dateTime("2026-04-21T18:30:00Z"),
            note: "Recurring",
            category: nil,
            item: nil,
            person: nil
        )

        try repository.upsert(existing: nil, draft: draft, in: context)

        let rules = try context.fetch(FetchDescriptor<RecurringTransactionRule>())
        XCTAssertEqual(rules.count, 1)
        let storedRule = try XCTUnwrap(rules.first)
        XCTAssertEqual(storedRule.title, "Salary")
        XCTAssertEqual(storedRule.nextRunDate.timeIntervalSince1970, date("2026-04-21").timeIntervalSince1970, accuracy: 1)
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
#endif