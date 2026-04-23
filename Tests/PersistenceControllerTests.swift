import SwiftData
import XCTest
@testable import Moneyz

@MainActor
final class PersistenceControllerTests: XCTestCase {
    func testPrimaryBootstrapSuccessMarksReady() throws {
        let schema = makeSchema()
        let controller = PersistenceController(
            inMemory: true,
            useCloudSync: false,
            schema: schema,
            containerFactory: { schema, _, _ in
                try Self.makeContainer(schema: schema)
            },
            emergencyContainerFactory: { schema in
                try Self.makeContainer(schema: schema)
            }
        )

        XCTAssertNotNil(controller.container)
        XCTAssertEqual(controller.bootstrapStatus, .ready)
    }

    func testDefaultBootstrapWiresMigrationPlan() {
        let controller = PersistenceController(inMemory: true, useCloudSync: false)

        XCTAssertNotNil(controller.container)
        XCTAssertEqual(
            String(describing: controller.container?.migrationPlan),
            String(describing: Optional(MoneyzSchemaMigrationPlan.self))
        )
    }

    func testCloudKitFailureFallsBackToLocalOnly() throws {
        let schema = makeSchema()
        let controller = PersistenceController(
            inMemory: false,
            useCloudSync: true,
            schema: schema,
            containerFactory: { schema, _, useCloudSync in
                if useCloudSync {
                    throw StubPersistenceError(message: "CloudKit entitlement missing")
                }
                return try Self.makeContainer(schema: schema)
            },
            emergencyContainerFactory: { schema in
                try Self.makeContainer(schema: schema)
            }
        )

        XCTAssertNotNil(controller.container)
        XCTAssertEqual(
            controller.bootstrapStatus,
            .degraded(
                fallback: .localOnly,
                reason: .cloudKitConfiguration,
                details: "CloudKit entitlement missing"
            )
        )
    }

    func testLocalStoreFailureFallsBackToInMemory() throws {
        let schema = makeSchema()
        let controller = PersistenceController(
            inMemory: false,
            useCloudSync: false,
            schema: schema,
            containerFactory: { _, _, _ in
                throw StubPersistenceError(message: "Database appears corrupt")
            },
            emergencyContainerFactory: { schema in
                try Self.makeContainer(schema: schema)
            }
        )

        XCTAssertNotNil(controller.container)
        XCTAssertEqual(
            controller.bootstrapStatus,
            .degraded(
                fallback: .inMemory,
                reason: .localStoreCorrupted,
                details: "Database appears corrupt"
            )
        )
    }

    func testEmergencyFailureReturnsFailedStateInsteadOfCrashing() {
        let schema = makeSchema()
        let controller = PersistenceController(
            inMemory: false,
            useCloudSync: false,
            schema: schema,
            containerFactory: { _, _, _ in
                throw StubPersistenceError(message: "Migration failed")
            },
            emergencyContainerFactory: { _ in
                throw StubPersistenceError(message: "Migration failed")
            }
        )

        XCTAssertNil(controller.container)
        XCTAssertEqual(
            controller.bootstrapStatus,
            .failed(reason: .migrationFailure, details: "Migration failed")
        )
    }

    private func makeSchema() -> Schema {
        Schema([
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
    }

    private static func makeContainer(schema: Schema) throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [configuration])
    }
}

private struct StubPersistenceError: LocalizedError {
    let message: String

    var errorDescription: String? { message }
}