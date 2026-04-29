import SwiftData
import XCTest
@testable import Moneyz

// MARK: - Fix 1 & 5: RecurringTransactionService

final class RecurringTransactionServiceFixTests: XCTestCase {
    private var calendar: Calendar!
    private var service: RecurringTransactionService!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        service = RecurringTransactionService(calendar: calendar)
    }

    // Fix 1: applying a rule twice on the same day must produce exactly 1 transaction,
    // confirming the targeted-fetch duplicate guard works correctly.
    func testTargetedFetchDeduplicationPreventsDoubleInsert() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let ref = makeDate("2026-04-21")
        context.insert(makeRule(nextRunDate: ref))
        try context.save()

        XCTAssertEqual(try service.applyDueRules(on: ref, in: context), 1)
        XCTAssertEqual(try service.applyDueRules(on: ref, in: context), 0)
        XCTAssertEqual(try fetchTransactions(in: context).count, 1)
    }

    // Fix 1: catch-up over multiple missed intervals must insert the correct number of
    // transactions and advance nextRunDate correctly — confirms the while-loop + targeted
    // fetch combination works under catch-up conditions.
    func testCatchUpCreatesCorrectTransactionCount() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let ref = makeDate("2026-05-05")
        context.insert(makeRule(frequency: .weekly, nextRunDate: makeDate("2026-04-14")))
        try context.save()

        XCTAssertEqual(try service.applyDueRules(on: ref, in: context), 4)
        XCTAssertEqual(try fetchTransactions(in: context).count, 4)
    }

    // Fix 5: lastAppliedAt must NOT be updated when a duplicate is skipped.
    // The value should remain nil (never applied) if the only "application" was a skip.
    func testLastAppliedAtNotUpdatedOnDuplicateSkip() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let ref = makeDate("2026-04-21")
        let rule = makeRule(nextRunDate: ref)
        context.insert(rule)
        // Pre-insert a transaction that will be detected as a duplicate.
        context.insert(MoneyTransaction(
            amountMinor: rule.amountMinor,
            kind: rule.kind,
            transactionDate: ref,
            customItemName: rule.title,
            note: rule.note,
            isRecurringInstance: true,
            recurringSourceID: rule.id
        ))
        try context.save()

        // lastAppliedAt is nil before any applyDueRules call.
        XCTAssertNil(rule.lastAppliedAt)

        let applied = try service.applyDueRules(on: ref, in: context)

        XCTAssertEqual(applied, 0)
        // Fix 5: lastAppliedAt must still be nil — the rule was skipped, not applied.
        XCTAssertNil(try fetchRule(id: rule.id, in: context)?.lastAppliedAt,
                     "lastAppliedAt must not be set when a duplicate is skipped")
    }

    // Fix 5 positive case: lastAppliedAt IS set when a transaction is actually inserted.
    func testLastAppliedAtSetOnActualInsert() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let ref = makeDate("2026-04-21")
        let rule = makeRule(nextRunDate: ref)
        context.insert(rule)
        try context.save()

        let applied = try service.applyDueRules(on: ref, in: context)

        XCTAssertEqual(applied, 1)
        XCTAssertNotNil(try fetchRule(id: rule.id, in: context)?.lastAppliedAt,
                        "lastAppliedAt must be set after a successful insert")
    }

    // MARK: - Helpers

    private func makeRule(
        frequency: RecurringFrequency = .monthly,
        nextRunDate: Date,
        isActive: Bool = true
    ) -> RecurringTransactionRule {
        RecurringTransactionRule(
            title: "Test Rule",
            amountMinor: 10_000,
            kind: .expense,
            frequency: frequency,
            nextRunDate: nextRunDate,
            isActive: isActive
        )
    }

    private func fetchTransactions(in context: ModelContext) throws -> [MoneyTransaction] {
        try context.fetch(FetchDescriptor<MoneyTransaction>())
    }

    private func fetchRule(id: UUID, in context: ModelContext) throws -> RecurringTransactionRule? {
        try context.fetch(FetchDescriptor<RecurringTransactionRule>()).first { $0.id == id }
    }

    private func makeDate(_ string: String) -> Date {
        let f = DateFormatter()
        f.calendar = calendar
        f.timeZone = calendar.timeZone
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.date(from: string)!
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            TransactionCategory.self, CategoryItem.self,
            PersonProfile.self, PersonBudgetPlan.self,
            MoneyTransaction.self, DebtRecord.self,
            RecurringTransactionRule.self,
            GroceryList.self, GroceryListItem.self, GroceryPresetItem.self
        ])
        return try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    }
}

// MARK: - Fix 2: GroceryRepository deduplication

@MainActor
final class GroceryRepositoryDeduplicationTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private let repository = GroceryRepository()

    override func setUp() async throws {
        try await super.setUp()
        let schema = Schema([
            TransactionCategory.self, CategoryItem.self,
            PersonProfile.self, PersonBudgetPlan.self,
            MoneyTransaction.self, DebtRecord.self,
            RecurringTransactionRule.self,
            GroceryList.self, GroceryListItem.self, GroceryPresetItem.self
        ])
        container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        context = ModelContext(container)
    }

    // Fix 2: calling addPreset twice with the same name must produce exactly 1 row.
    func testAddPresetIsDeduplicated() throws {
        try repository.addPreset(name: "Milk", groupName: "Dairy", emoji: "🥛", in: context)
        try repository.addPreset(name: "Milk", groupName: "Dairy", emoji: "🥛", in: context)

        let all = try context.fetch(FetchDescriptor<GroceryPresetItem>())
        XCTAssertEqual(all.count, 1, "Duplicate preset must not be inserted")
    }

    // Fix 2: deduplication is case-insensitive.
    func testAddPresetDeduplicatesCaseInsensitive() throws {
        try repository.addPreset(name: "milk", groupName: "Dairy", emoji: "🥛", in: context)
        try repository.addPreset(name: "MILK", groupName: "Dairy", emoji: "🥛", in: context)

        let all = try context.fetch(FetchDescriptor<GroceryPresetItem>())
        XCTAssertEqual(all.count, 1, "Case-insensitive duplicate must not produce two rows")
    }

    // Fix 2: deduplication updates emoji when it changes (upsert behaviour).
    func testAddPresetUpdatesEmojiOnDuplicate() throws {
        try repository.addPreset(name: "Milk", groupName: "Dairy", emoji: "🥛", in: context)
        try repository.addPreset(name: "Milk", groupName: "Dairy", emoji: "🍼", in: context)

        let all = try context.fetch(FetchDescriptor<GroceryPresetItem>())
        XCTAssertEqual(all.count, 1)
        XCTAssertEqual(all.first?.emoji, "🍼", "Emoji must be updated on deduplication")
    }

    // Fix 3: deletePreset removes the row.
    func testDeletePresetRemovesRow() throws {
        try repository.addPreset(name: "Rice", groupName: "Pantry", emoji: "🍚", in: context)
        let preset = try XCTUnwrap(context.fetch(FetchDescriptor<GroceryPresetItem>()).first)

        try repository.deletePreset(preset, in: context)

        let remaining = try context.fetch(FetchDescriptor<GroceryPresetItem>())
        XCTAssertTrue(remaining.isEmpty, "Preset must be removed after delete")
    }

    // Fix 3: deleteItem removes the grocery list item.
    func testDeleteItemRemovesRow() throws {
        let list = GroceryList(title: "Test List")
        context.insert(list)
        try repository.addItem(name: "Banana", groupName: "Fruits", emoji: "🍌", to: list, preset: nil, in: context)
        let item = try XCTUnwrap(context.fetch(FetchDescriptor<GroceryListItem>()).first)

        try repository.deleteItem(item, in: context)

        let remaining = try context.fetch(FetchDescriptor<GroceryListItem>())
        XCTAssertTrue(remaining.isEmpty, "Item must be removed after delete")
    }
}

// MARK: - Fix 4: BudgetRepository safe upsert

@MainActor
final class BudgetRepositorySafeUpsertTests: XCTestCase {
    private var container: ModelContainer!
    private var context: ModelContext!
    private let repository = BudgetRepository()

    override func setUp() async throws {
        try await super.setUp()
        let schema = Schema([
            TransactionCategory.self, CategoryItem.self,
            PersonProfile.self, PersonBudgetPlan.self,
            MoneyTransaction.self, DebtRecord.self,
            RecurringTransactionRule.self,
            GroceryList.self, GroceryListItem.self, GroceryPresetItem.self
        ])
        container = try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
        context = ModelContext(container)
    }

    // Fix 4: upserting a budget must leave exactly one active budget.
    // Previously if save failed after mass-deactivation, ALL budgets would be left inactive.
    func testUpsertBudgetLeavesExactlyOneActiveBudget() throws {
        let person = PersonProfile(name: "Test", emoji: "🙂")
        context.insert(person)

        try repository.upsertBudget(
            for: person, title: "Budget 1", amountMinor: 100_000,
            period: .month, salaryCycleStartDay: 1, in: context
        )
        try repository.upsertBudget(
            for: person, title: "Budget 2", amountMinor: 200_000,
            period: .month, salaryCycleStartDay: 1, in: context
        )

        let activeBudgets = person.budgets.filter { $0.isActive }
        XCTAssertEqual(activeBudgets.count, 1, "Exactly one budget must be active after upsert")
        XCTAssertEqual(activeBudgets.first?.amountMinor, 200_000)
    }

    // Fix 4: confirm the updated budget retains the new title and amount.
    func testUpsertBudgetUpdatesExistingRecord() throws {
        let person = PersonProfile(name: "Test", emoji: "🙂")
        context.insert(person)

        try repository.upsertBudget(
            for: person, title: "Old Title", amountMinor: 50_000,
            period: .month, salaryCycleStartDay: 1, in: context
        )
        try repository.upsertBudget(
            for: person, title: "New Title", amountMinor: 75_000,
            period: .year, salaryCycleStartDay: 5, in: context
        )

        let budget = try XCTUnwrap(person.activeBudget)
        XCTAssertEqual(budget.title, "New Title")
        XCTAssertEqual(budget.amountMinor, 75_000)
        XCTAssertEqual(budget.period, .year)
        XCTAssertEqual(budget.salaryCycleStartDay, 5)
    }
}

// MARK: - Fix 6: CurrencyFormatter negative amounts

final class CurrencyFormatterNegativeTests: XCTestCase {
    private let locale = Locale(identifier: "en_US")

    // Fix 6: negative amount typed with a leading minus must parse correctly.
    func testNegativeAmountPreservesMinus() {
        let result = CurrencyFormatter.minorUnits(from: "-150.00", locale: locale)
        XCTAssertEqual(result, -15_000, "Negative opening balance must parse as negative minor units")
    }

    // Fix 6: positive amounts must be unchanged.
    func testPositiveAmountUnchanged() {
        let result = CurrencyFormatter.minorUnits(from: "150.00", locale: locale)
        XCTAssertEqual(result, 15_000)
    }

    // Fix 6: zero must parse as zero.
    func testZeroAmount() {
        let result = CurrencyFormatter.minorUnits(from: "0.00", locale: locale)
        XCTAssertEqual(result, 0)
    }

    // Fix 6: a minus-only string with no digits is invalid — must return nil.
    func testBareMinusIsInvalid() {
        let result = CurrencyFormatter.minorUnits(from: "-", locale: locale)
        XCTAssertNil(result, "A bare minus sign with no digits is not a valid amount")
    }
}

// MARK: - Fix 9: BudgetViewModel pause/resume

@MainActor
final class BudgetViewModelPauseResumeTests: XCTestCase {
    // Fix 9: toggleActive must flip isActive from true → false (pause).
    func testToggleActivePausesActiveRule() {
        var toggled = false
        let viewModel = BudgetViewModel(
            toggleActiveAction: { rule, _ in
                rule.isActive.toggle()
                toggled = true
            }
        )
        let context = ModelContext(PersistenceController.previewContainer())
        let rule = RecurringTransactionRule(
            title: "Rent", amountMinor: 80_000, nextRunDate: .now, isActive: true
        )

        viewModel.toggleActive(rule, in: context)

        XCTAssertTrue(toggled)
        XCTAssertFalse(rule.isActive, "Active rule must be paused after toggle")
        XCTAssertNil(viewModel.errorMessage)
    }

    // Fix 9: toggleActive must flip isActive from false → true (resume).
    func testToggleActiveResumesInactiveRule() {
        let viewModel = BudgetViewModel(
            toggleActiveAction: { rule, _ in rule.isActive.toggle() }
        )
        let context = ModelContext(PersistenceController.previewContainer())
        let rule = RecurringTransactionRule(
            title: "Gym", amountMinor: 5_000, nextRunDate: .now, isActive: false
        )

        viewModel.toggleActive(rule, in: context)

        XCTAssertTrue(rule.isActive, "Inactive rule must be resumed after toggle")
    }

    // Fix 9: errors from the toggle action are surfaced in errorMessage.
    func testToggleActiveStoresErrorMessageOnFailure() {
        let viewModel = BudgetViewModel(
            toggleActiveAction: { _, _ in
                throw NSError(
                    domain: "BudgetViewModelTests",
                    code: 1,
                    userInfo: [NSLocalizedDescriptionKey: "Toggle failed"]
                )
            }
        )
        let context = ModelContext(PersistenceController.previewContainer())
        let rule = RecurringTransactionRule(title: "Test", amountMinor: 1_000, nextRunDate: .now)

        viewModel.toggleActive(rule, in: context)

        XCTAssertEqual(viewModel.errorMessage, "Toggle failed")
    }
}
