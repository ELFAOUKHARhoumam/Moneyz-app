import Foundation
import OSLog
import SwiftData

final class PersistenceController {
    private static let logger = MoneyzLogger.persistence

    static let shared = PersistenceController()

    let container: ModelContainer

    init(inMemory: Bool = false, useCloudSync: Bool = true) {
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

        do {
            container = try Self.makeContainer(schema: schema, inMemory: inMemory, useCloudSync: useCloudSync)
            Self.logger.notice("Created model container (cloudSync=\(useCloudSync, privacy: .public), inMemory=\(inMemory, privacy: .public))")
        } catch {
            Self.logger.error("Primary model container creation failed (cloudSync=\(useCloudSync, privacy: .public), inMemory=\(inMemory, privacy: .public)): \(error.localizedDescription, privacy: .public)")

            if useCloudSync && !inMemory {
                do {
                    container = try Self.makeContainer(schema: schema, inMemory: inMemory, useCloudSync: false)
                    Self.logger.notice("Fell back to local-only model container after CloudKit-backed initialization failure")
                    return
                } catch {
                    Self.logger.fault("Local fallback model container creation failed: \(error.localizedDescription, privacy: .public)")
                }
            }

            container = Self.makeEmergencyInMemoryContainer(schema: schema)
            Self.logger.fault("Using emergency in-memory model container; app data will not persist for this run")
        }
    }

    private static func makeContainer(
        schema: Schema,
        inMemory: Bool,
        useCloudSync: Bool
    ) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            "Moneyz",
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            allowsSave: true,
            groupContainer: .automatic,
            cloudKitDatabase: useCloudSync ? .automatic : .none
        )

        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func makeEmergencyInMemoryContainer(schema: Schema) -> ModelContainer {
        do {
            let configuration = ModelConfiguration(
                "MoneyzEmergency",
                schema: schema,
                isStoredInMemoryOnly: true,
                allowsSave: true,
                groupContainer: .none,
                cloudKitDatabase: .none
            )
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create emergency in-memory model container: \(error.localizedDescription)")
        }
    }

    static func previewContainer() -> ModelContainer {
        let controller = PersistenceController(inMemory: true, useCloudSync: false)
        let context = ModelContext(controller.container)
        SeedDataSeeder.seedPreviewData(in: context)
        return controller.container
    }
}
