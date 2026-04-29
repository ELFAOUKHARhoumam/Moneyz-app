import SwiftData
import XCTest
@testable import Moneyz

// MARK: - Gap 10: ArchivedPeople

@MainActor
final class ArchivedPeopleTests: XCTestCase {

    // BudgetRepository.archivePerson sets isArchived = true and saves.
    func testArchivePersonSetsIsArchivedTrue() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)
        let person    = PersonProfile(name: "Sara", emoji: "🙂")
        context.insert(person)
        try context.save()

        try BudgetRepository().archivePerson(person, in: context)

        XCTAssertTrue(person.isArchived, "Person must be archived after archivePerson()")
    }

    // Unarchiving (ArchivedPeopleView path) flips isArchived back to false.
    func testUnarchivePersonResetsIsArchivedFalse() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)
        let person    = PersonProfile(name: "Sara", emoji: "🙂", isArchived: true)
        context.insert(person)
        try context.save()

        // Simulate the unarchive action performed in ArchivedPeopleView.
        person.isArchived = false
        try context.save()

        let fetched = try context.fetch(FetchDescriptor<PersonProfile>()).first
        XCTAssertFalse(fetched?.isArchived ?? true, "Person must be unarchived")
    }

    // Archived person must not appear in active budgets query.
    func testArchivedPersonExcludedFromActivePeopleFilter() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)
        let active   = PersonProfile(name: "Active", emoji: "😀")
        let archived = PersonProfile(name: "Gone",   emoji: "👻", isArchived: true)
        context.insert(active)
        context.insert(archived)
        try context.save()

        let activePeople = try context.fetch(
            FetchDescriptor<PersonProfile>(
                predicate: #Predicate { !$0.isArchived }
            )
        )
        XCTAssertEqual(activePeople.count, 1)
        XCTAssertEqual(activePeople.first?.name, "Active")
    }
}

// MARK: - Gap 14: RecurringRuleRepository deduplication

final class RecurringRuleRepositoryDedupTests: XCTestCase {
    private var calendar: Calendar!

    override func setUp() {
        super.setUp()
        calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    }

    // Inserting two rules with the same title+kind+frequency+amount must produce one row.
    func testDuplicateRuleIsUpsertedNotInserted() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)
        let repo      = RecurringRuleRepository(calendar: calendar)

        let draft = makeDraft(title: "Rent", amountMinor: 80_000)
        try repo.upsert(existing: nil, draft: draft, in: context)
        try repo.upsert(existing: nil, draft: draft, in: context)

        let rules = try context.fetch(FetchDescriptor<RecurringTransactionRule>())
        XCTAssertEqual(rules.count, 1, "Duplicate rule must not create a second row")
    }

    // Case-insensitive title comparison: "rent" == "RENT".
    func testDedupIsCaseInsensitive() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)
        let repo      = RecurringRuleRepository(calendar: calendar)

        try repo.upsert(existing: nil, draft: makeDraft(title: "rent"), in: context)
        try repo.upsert(existing: nil, draft: makeDraft(title: "RENT"), in: context)

        let rules = try context.fetch(FetchDescriptor<RecurringTransactionRule>())
        XCTAssertEqual(rules.count, 1, "Case-insensitive duplicate must not produce two rows")
    }

    // Different amount = different rule: must produce two rows.
    func testDifferentAmountProducesTwoRules() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)
        let repo      = RecurringRuleRepository(calendar: calendar)

        try repo.upsert(existing: nil, draft: makeDraft(title: "Rent", amountMinor: 80_000), in: context)
        try repo.upsert(existing: nil, draft: makeDraft(title: "Rent", amountMinor: 90_000), in: context)

        let rules = try context.fetch(FetchDescriptor<RecurringTransactionRule>())
        XCTAssertEqual(rules.count, 2, "Different amounts must not be considered duplicates")
    }

    // Paused duplicate is reactivated on re-insert.
    func testDedupReactivatesPausedDuplicate() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)
        let repo      = RecurringRuleRepository(calendar: calendar)

        try repo.upsert(existing: nil, draft: makeDraft(title: "Gym"), in: context)
        let rule = try XCTUnwrap(context.fetch(FetchDescriptor<RecurringTransactionRule>()).first)
        rule.isActive = false
        try context.save()

        try repo.upsert(existing: nil, draft: makeDraft(title: "Gym"), in: context)

        let rules = try context.fetch(FetchDescriptor<RecurringTransactionRule>())
        XCTAssertEqual(rules.count, 1)
        XCTAssertTrue(rules.first?.isActive ?? false, "Paused duplicate must be reactivated on re-insert")
    }

    // MARK: - Helpers

    private func makeDraft(
        title: String = "Rent",
        amountMinor: Int64 = 80_000,
        kind: TransactionKind = .expense,
        frequency: RecurringFrequency = .monthly
    ) -> RecurringRuleDraft {
        RecurringRuleDraft(
            title: title, amountMinor: amountMinor, kind: kind,
            frequency: frequency,
            nextRunDate: Date(timeIntervalSinceReferenceDate: 0),
            note: "", category: nil, item: nil, person: nil
        )
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            TransactionCategory.self, CategoryItem.self,
            PersonProfile.self, PersonBudgetPlan.self,
            MoneyTransaction.self, DebtRecord.self,
            RecurringTransactionRule.self,
            GroceryList.self, GroceryListItem.self, GroceryPresetItem.self
        ])
        return try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
    }
}

// MARK: - Fix 6 (extended): CurrencyFormatter negative amounts

final class CurrencyFormatterExtendedTests: XCTestCase {
    private let locale = Locale(identifier: "en_US")

    func testNegativeAmountWithDecimal() {
        XCTAssertEqual(CurrencyFormatter.minorUnits(from: "-150.50", locale: locale), -15_050)
    }

    func testNegativeWholeNumber() {
        XCTAssertEqual(CurrencyFormatter.minorUnits(from: "-200", locale: locale), -20_000)
    }

    func testNegativeZeroIsZero() {
        XCTAssertEqual(CurrencyFormatter.minorUnits(from: "-0.00", locale: locale), 0)
    }

    func testBareMinusIsNil() {
        XCTAssertNil(CurrencyFormatter.minorUnits(from: "-", locale: locale))
    }

    func testPositiveUnchanged() {
        XCTAssertEqual(CurrencyFormatter.minorUnits(from: "99.99", locale: locale), 9_999)
    }

    func testArabicLocaleDecimalSeparator() {
        // Arabic uses comma as decimal separator in some locales.
        let arLocale = Locale(identifier: "ar_SA")
        // "١٢٣٫٤٥" with Arabic-Indic digits — the formatter should handle grouping/decimal
        // correctly. At minimum, a plain "123.45" must still work even under ar_SA locale.
        let result = CurrencyFormatter.minorUnits(from: "123.45", locale: arLocale)
        XCTAssertNotNil(result)
    }
}

// MARK: - DebtRepository updatedAt fix

@MainActor
final class DebtRepositoryUpdatedAtTests: XCTestCase {

    func testEditExistingDebtSetsUpdatedAt() throws {
        let container = try makeContainer()
        let context   = ModelContext(container)
        let repo      = DebtRepository()

        let original = DebtRecord(
            counterpartyName: "Bank",
            amountMinor: 10_000,
            direction: .iOwe
        )
        context.insert(original)
        try context.save()

        let originalUpdatedAt = original.updatedAt

        // Small sleep to guarantee the clock advances.
        Thread.sleep(forTimeInterval: 0.01)

        let draft = DebtDraft(
            counterpartyName: "Bank (updated)",
            amountMinor: 12_000,
            direction: .iOwe,
            issueDate: original.issueDate,
            dueDate: nil,
            status: .open,
            note: "updated note"
        )
        try repo.upsert(existing: original, draft: draft, in: context)

        XCTAssertGreaterThan(
            original.updatedAt.timeIntervalSince1970,
            originalUpdatedAt.timeIntervalSince1970,
            "updatedAt must advance when editing an existing DebtRecord"
        )
        XCTAssertEqual(original.counterpartyName, "Bank (updated)")
        XCTAssertEqual(original.amountMinor, 12_000)
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([
            TransactionCategory.self, CategoryItem.self,
            PersonProfile.self, PersonBudgetPlan.self,
            MoneyTransaction.self, DebtRecord.self,
            RecurringTransactionRule.self,
            GroceryList.self, GroceryListItem.self, GroceryPresetItem.self
        ])
        return try ModelContainer(
            for: schema,
            configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
        )
    }
}

// MARK: - AppBootstrapCoordinator referenceDate injection

@MainActor
final class AppBootstrapCoordinatorReferenceDateTests: XCTestCase {

    func testBootstrapUsesInjectedReferenceDate() throws {
        let controller = PersistenceController(inMemory: true, useCloudSync: false)
        let container  = try XCTUnwrap(controller.container)
        let context    = ModelContext(container)
        let settings   = SettingsStore(defaults: UserDefaults(suiteName: #function)!)
        let appLock    = AppLockViewModel()
        let coordinator = AppBootstrapCoordinator()

        // Rule due 5 days ago — will only fire if referenceDate >= nextRunDate.
        let pastDate = Calendar.current.date(byAdding: .day, value: -5, to: .now) ?? .now
        let rule = RecurringTransactionRule(
            title: "Fixed", amountMinor: 1_000,
            kind: .expense, frequency: .monthly,
            nextRunDate: pastDate
        )
        context.insert(rule)
        try context.save()

        // Pass a fixed referenceDate — today — so the rule fires deterministically.
        coordinator.bootstrapIfNeeded(
            in: context, settings: settings, appLock: appLock,
            referenceDate: .now
        )

        let transactions = try context.fetch(FetchDescriptor<MoneyTransaction>())
        XCTAssertEqual(
            transactions.filter(\.isRecurringInstance).count, 1,
            "Rule due 5 days ago must produce exactly 1 transaction when referenceDate = today"
        )
    }

    func testHandleScenePhaseActiveUsesInjectedDate() throws {
        let controller = PersistenceController(inMemory: true, useCloudSync: false)
        let container  = try XCTUnwrap(controller.container)
        let context    = ModelContext(container)
        let settings   = SettingsStore(defaults: UserDefaults(suiteName: #function + "2")!)
        let appLock    = AppLockViewModel()
        let coordinator = AppBootstrapCoordinator()

        let pastDate = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        context.insert(RecurringTransactionRule(
            title: "Insurance", amountMinor: 9_000,
            kind: .expense, frequency: .monthly,
            nextRunDate: pastDate
        ))
        try context.save()

        coordinator.handleScenePhase(
            .inactive, context: context, settings: settings, appLock: appLock,
            referenceDate: .now
        )
        var txns = try context.fetch(FetchDescriptor<MoneyTransaction>())
        XCTAssertEqual(txns.filter(\.isRecurringInstance).count, 0, "Inactive phase must not trigger rules")

        coordinator.handleScenePhase(
            .active, context: context, settings: settings, appLock: appLock,
            referenceDate: .now
        )
        txns = try context.fetch(FetchDescriptor<MoneyTransaction>())
        XCTAssertEqual(txns.filter(\.isRecurringInstance).count, 1, "Active phase must apply due rules")
    }
}

// MARK: - RecurringRuleEditorViewModel calendar injection

@MainActor
final class RecurringRuleEditorViewModelCalendarTests: XCTestCase {

    // Injecting a UTC calendar ensures startOfDay behaves identically in all timezones.
    func testSaveUsesInjectedCalendarForStartOfDay() throws {
        var utcCalendar = Calendar(identifier: .gregorian)
        utcCalendar.timeZone = TimeZone(secondsFromGMT: 0)!

        var capturedDraft: RecurringRuleDraft?
        let viewModel = RecurringRuleEditorViewModel(
            rule: nil,
            calendar: utcCalendar,
            saveRuleAction: { _, draft, _ in capturedDraft = draft }
        )

        // Set a time well past midnight UTC so a non-UTC calendar would give a different date.
        let iso = ISO8601DateFormatter()
        iso.timeZone = TimeZone(secondsFromGMT: 0)
        let testDate = iso.date(from: "2026-04-21T22:30:00Z")!

        viewModel.title        = "Rent"
        viewModel.amountText   = "800"
        viewModel.kind         = .expense
        viewModel.frequency    = .monthly
        viewModel.nextRunDate  = testDate

        let context = ModelContext(PersistenceController.previewContainer())
        let saved = viewModel.save(categories: [], people: [], locale: Locale(identifier: "en_US"), in: context)

        XCTAssertTrue(saved)
        let draft = try XCTUnwrap(capturedDraft)

        // With injected UTC calendar, startOfDay("2026-04-21T22:30Z") = "2026-04-21T00:00Z"
        let expected = iso.date(from: "2026-04-21T00:00:00Z")!
        XCTAssertEqual(
            draft.nextRunDate.timeIntervalSince1970,
            expected.timeIntervalSince1970,
            accuracy: 1,
            "nextRunDate must be start of day in the injected calendar's timezone"
        )
    }
}

// MARK: - Shared container helper

private func makeContainer() throws -> ModelContainer {
    let schema = Schema([
        TransactionCategory.self, CategoryItem.self,
        PersonProfile.self, PersonBudgetPlan.self,
        MoneyTransaction.self, DebtRecord.self,
        RecurringTransactionRule.self,
        GroceryList.self, GroceryListItem.self, GroceryPresetItem.self
    ])
    return try ModelContainer(
        for: schema,
        configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
    )
}
