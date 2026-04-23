import SwiftData
import XCTest
@testable import Moneyz

@MainActor
final class AppBootstrapCoordinatorTests: XCTestCase {
    func testBootstrapSeedsDefaultDataAndRunsRecurringOnlyOnce() throws {
        let controller = PersistenceController(inMemory: true, useCloudSync: false)
        let container = try XCTUnwrap(controller.container)
        let context = ModelContext(container)
        let settings = SettingsStore(defaults: UserDefaults(suiteName: #function)!)
        let appLock = AppLockViewModel()
        let coordinator = AppBootstrapCoordinator()

        let dueRule = RecurringTransactionRule(
            title: "Gym",
            amountMinor: 5_000,
            kind: .expense,
            frequency: .monthly,
            nextRunDate: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        )
        context.insert(dueRule)
        try context.save()

        coordinator.bootstrapIfNeeded(in: context, settings: settings, appLock: appLock)
        coordinator.bootstrapIfNeeded(in: context, settings: settings, appLock: appLock)

        let categories = try context.fetch(FetchDescriptor<TransactionCategory>())
        let transactions = try context.fetch(FetchDescriptor<MoneyTransaction>())

        XCTAssertGreaterThanOrEqual(categories.count, 6)
        XCTAssertEqual(transactions.filter(\.isRecurringInstance).count, 1)
    }

    func testHandleScenePhaseAppliesRecurringOnlyWhenActive() throws {
        let controller = PersistenceController(inMemory: true, useCloudSync: false)
        let container = try XCTUnwrap(controller.container)
        let context = ModelContext(container)
        let settings = SettingsStore(defaults: UserDefaults(suiteName: #function)!)
        let appLock = AppLockViewModel()
        let coordinator = AppBootstrapCoordinator()

        let dueRule = RecurringTransactionRule(
            title: "Insurance",
            amountMinor: 9_000,
            kind: .expense,
            frequency: .monthly,
            nextRunDate: Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        )
        context.insert(dueRule)
        try context.save()

        coordinator.handleScenePhase(.inactive, context: context, settings: settings, appLock: appLock)
        var transactions = try context.fetch(FetchDescriptor<MoneyTransaction>())
        XCTAssertEqual(transactions.filter(\.isRecurringInstance).count, 0)

        coordinator.handleScenePhase(.active, context: context, settings: settings, appLock: appLock)
        transactions = try context.fetch(FetchDescriptor<MoneyTransaction>())
        XCTAssertEqual(transactions.filter(\.isRecurringInstance).count, 1)
    }
}

@MainActor
final class SeedDataSeederTests: XCTestCase {
    func testSeedIfNeededIsIdempotent() throws {
        let controller = PersistenceController(inMemory: true, useCloudSync: false)
        let container = try XCTUnwrap(controller.container)
        let context = ModelContext(container)

        SeedDataSeeder.seedIfNeeded(in: context)
        SeedDataSeeder.seedIfNeeded(in: context)

        let categories = try context.fetch(FetchDescriptor<TransactionCategory>())
        let items = try context.fetch(FetchDescriptor<CategoryItem>())
        let presets = try context.fetch(FetchDescriptor<GroceryPresetItem>())

        XCTAssertEqual(categories.count, 6)
        XCTAssertEqual(items.count, 12)
        XCTAssertEqual(presets.count, 4)
    }

    func testSeedPreviewDataAddsExpectedPreviewDomainEntities() throws {
        let controller = PersistenceController(inMemory: true, useCloudSync: false)
        let container = try XCTUnwrap(controller.container)
        let context = ModelContext(container)

        SeedDataSeeder.seedPreviewData(in: context)

        XCTAssertEqual(try context.fetch(FetchDescriptor<PersonProfile>()).count, 2)
        XCTAssertEqual(try context.fetch(FetchDescriptor<PersonBudgetPlan>()).count, 2)
        XCTAssertEqual(try context.fetch(FetchDescriptor<DebtRecord>()).count, 2)
        XCTAssertEqual(try context.fetch(FetchDescriptor<RecurringTransactionRule>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<GroceryList>()).count, 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<GroceryListItem>()).count, 3)
        XCTAssertGreaterThanOrEqual(try context.fetch(FetchDescriptor<MoneyTransaction>()).count, 6)
    }
}

@MainActor
final class RepositoryQualityHardeningTests: XCTestCase {
    func testCategoryRepositoryCreatesTrimmedCategoryAndNormalizedItemGroup() throws {
        let controller = PersistenceController(inMemory: true, useCloudSync: false)
        let container = try XCTUnwrap(controller.container)
        let context = ModelContext(container)
        let repository = CategoryRepository()

        try repository.createCategory(name: "  Food  ", emoji: "", kind: .expense, in: context)
        let category = try XCTUnwrap(try context.fetch(FetchDescriptor<TransactionCategory>()).first)
        XCTAssertEqual(category.name, "Food")
        XCTAssertEqual(category.emoji, "🏷️")

        try repository.createItem(name: "  Bread  ", groupName: "   ", emoji: "🥖", for: category, in: context)
        let item = try XCTUnwrap(try context.fetch(FetchDescriptor<CategoryItem>()).first)
        XCTAssertEqual(item.name, "Bread")
        XCTAssertNil(item.groupName)
    }

    func testBudgetRepositoryUpsertPersonTrimsNameAndDefaultsEmoji() throws {
        let controller = PersistenceController(inMemory: true, useCloudSync: false)
        let container = try XCTUnwrap(controller.container)
        let context = ModelContext(container)
        let repository = BudgetRepository()

        let person = try repository.upsertPerson(name: "  Sara  ", emoji: "   ", existing: nil, in: context)

        XCTAssertEqual(person.name, "Sara")
        XCTAssertEqual(person.emoji, "🙂")
    }
}

@MainActor
final class PersistenceControllerP2Tests: XCTestCase {
    func testRetryBootstrapRecoversAfterTransientFailure() throws {
        let schema = Schema(versionedSchema: MoneyzSchemaV1.self)
        var attempts = 0
        let controller = PersistenceController(
            inMemory: false,
            useCloudSync: false,
            schema: schema,
            containerFactory: { schema, _, _ in
                attempts += 1
                if attempts == 1 {
                    throw StubP2PersistenceError(message: "Store unavailable")
                }
                let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [configuration])
            },
            emergencyContainerFactory: { schema in
                let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [configuration])
            }
        )

        XCTAssertNotNil(controller.container)
        XCTAssertEqual(
            controller.bootstrapStatus,
            .degraded(fallback: .inMemory, reason: .localStoreUnavailable, details: "Store unavailable")
        )

        controller.retryBootstrap()

        XCTAssertNotNil(controller.container)
        XCTAssertEqual(controller.bootstrapStatus, .ready)
        XCTAssertEqual(attempts, 2)
    }

    func testCloudKitRuntimeFailureIsClassifiedWhenErrorIsNotConfigurationRelated() throws {
        let schema = Schema(versionedSchema: MoneyzSchemaV1.self)
        let controller = PersistenceController(
            inMemory: false,
            useCloudSync: true,
            schema: schema,
            containerFactory: { schema, _, useCloudSync in
                if useCloudSync {
                    throw StubP2PersistenceError(message: "Request timed out while contacting server")
                }
                let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [configuration])
            },
            emergencyContainerFactory: { schema in
                let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
                return try ModelContainer(for: schema, configurations: [configuration])
            }
        )

        XCTAssertEqual(
            controller.bootstrapStatus,
            .degraded(
                fallback: .localOnly,
                reason: .cloudKitRuntime,
                details: "Request timed out while contacting server"
            )
        )
    }
}

private struct StubP2PersistenceError: LocalizedError {
    let message: String
    var errorDescription: String? { message }
}