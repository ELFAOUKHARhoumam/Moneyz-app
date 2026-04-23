import Foundation
import Combine
import OSLog
import SwiftData

@MainActor
final class PersistenceController: ObservableObject {
    enum FailureReason: Equatable {
        case cloudKitConfiguration
        case cloudKitRuntime
        case localStoreCorrupted
        case migrationFailure
        case localStoreUnavailable
        case unknown
    }

    enum FallbackMode: Equatable {
        case localOnly
        case inMemory
    }

    enum BootstrapStatus: Equatable {
        case ready
        case degraded(fallback: FallbackMode, reason: FailureReason, details: String)
        case failed(reason: FailureReason, details: String)
    }

    private enum CreationStage {
        case primaryCloudKit
        case primaryLocalOnly
        case emergencyInMemory
    }

    private struct BootstrapOutcome {
        let container: ModelContainer?
        let status: BootstrapStatus
    }

    typealias ContainerFactory = (Schema, Bool, Bool) throws -> ModelContainer
    typealias EmergencyContainerFactory = (Schema) throws -> ModelContainer

    private static let logger = MoneyzLogger.persistence

    static let shared = PersistenceController()

    @Published private(set) var bootstrapStatus: BootstrapStatus = .ready
    private(set) var container: ModelContainer?

    private let inMemory: Bool
    private let useCloudSync: Bool
    private let schema: Schema
    private let containerFactory: ContainerFactory
    private let emergencyContainerFactory: EmergencyContainerFactory

    init(
        inMemory: Bool = false,
        useCloudSync: Bool = true,
        schema: Schema? = nil,
        containerFactory: ContainerFactory? = nil,
        emergencyContainerFactory: EmergencyContainerFactory? = nil
    ) {
        self.inMemory = inMemory
        self.useCloudSync = useCloudSync
        self.schema = schema ?? Self.defaultSchema()
        self.containerFactory = containerFactory ?? Self.makeContainer
        self.emergencyContainerFactory = emergencyContainerFactory ?? Self.makeEmergencyInMemoryContainer

        let outcome = Self.bootstrap(
            schema: self.schema,
            inMemory: inMemory,
            useCloudSync: useCloudSync,
            containerFactory: self.containerFactory,
            emergencyContainerFactory: self.emergencyContainerFactory
        )
        self.container = outcome.container
        self.bootstrapStatus = outcome.status
    }

    func retryBootstrap() {
        let outcome = Self.bootstrap(
            schema: schema,
            inMemory: inMemory,
            useCloudSync: useCloudSync,
            containerFactory: containerFactory,
            emergencyContainerFactory: emergencyContainerFactory
        )
        container = outcome.container
        bootstrapStatus = outcome.status
    }

    private static func defaultSchema() -> Schema {
        Schema(versionedSchema: MoneyzSchemaV1.self)
    }

    private static func migrationPlan(for schema: Schema) -> (any SchemaMigrationPlan.Type)? {
        schema == defaultSchema() ? MoneyzSchemaMigrationPlan.self : nil
    }

    private static func bootstrap(
        schema: Schema,
        inMemory: Bool,
        useCloudSync: Bool,
        containerFactory: ContainerFactory,
        emergencyContainerFactory: EmergencyContainerFactory
    ) -> BootstrapOutcome {
        do {
            let container = try containerFactory(schema, inMemory, useCloudSync)
            Self.logger.notice("Created model container (cloudSync=\(useCloudSync, privacy: .public), inMemory=\(inMemory, privacy: .public))")
            return BootstrapOutcome(container: container, status: .ready)
        } catch {
            Self.logger.error("Primary model container creation failed (cloudSync=\(useCloudSync, privacy: .public), inMemory=\(inMemory, privacy: .public)): \(error.localizedDescription, privacy: .public)")

            let primaryStage: CreationStage = (useCloudSync && !inMemory) ? .primaryCloudKit : .primaryLocalOnly
            let primaryReason = classify(error, during: primaryStage)

            if useCloudSync && !inMemory {
                do {
                    let container = try containerFactory(schema, inMemory, false)
                    Self.logger.notice("Fell back to local-only model container after CloudKit-backed initialization failure")
                    return BootstrapOutcome(
                        container: container,
                        status: .degraded(
                            fallback: .localOnly,
                            reason: primaryReason,
                            details: failureDetails(from: error)
                        )
                    )
                } catch {
                    Self.logger.fault("Local fallback model container creation failed: \(error.localizedDescription, privacy: .public)")
                    return makeEmergencyOutcome(
                        schema: schema,
                        failure: error,
                        reason: classify(error, during: .primaryLocalOnly),
                        emergencyContainerFactory: emergencyContainerFactory
                    )
                }
            }

            return makeEmergencyOutcome(
                schema: schema,
                failure: error,
                reason: primaryReason,
                emergencyContainerFactory: emergencyContainerFactory
            )
        }
    }

    private static func makeEmergencyOutcome(
        schema: Schema,
        failure: Error,
        reason: FailureReason,
        emergencyContainerFactory: EmergencyContainerFactory
    ) -> BootstrapOutcome {
        do {
            let container = try emergencyContainerFactory(schema)
            Self.logger.fault("Using emergency in-memory model container; app data will not persist for this run")
            return BootstrapOutcome(
                container: container,
                status: .degraded(
                    fallback: .inMemory,
                    reason: reason,
                    details: failureDetails(from: failure)
                )
            )
        } catch {
            let finalReason = classify(error, during: .emergencyInMemory)
            Self.logger.fault("Emergency in-memory model container creation failed: \(error.localizedDescription, privacy: .public)")
            return BootstrapOutcome(
                container: nil,
                status: .failed(reason: finalReason, details: failureDetails(from: error))
            )
        }
    }

    private static func classify(_ error: Error, during stage: CreationStage) -> FailureReason {
        let description = failureDetails(from: error).lowercased()

        if description.contains("migration") || description.contains("schema") || description.contains("model version") {
            return .migrationFailure
        }

        if description.contains("corrupt") ||
            description.contains("malformed") ||
            description.contains("file is not a database") ||
            description.contains("integrity") {
            return .localStoreCorrupted
        }

        switch stage {
        case .primaryCloudKit:
            if description.contains("entitlement") ||
                description.contains("ubiquity") ||
                description.contains("icloud") ||
                description.contains("cloudkit") ||
                description.contains("container") ||
                description.contains("capability") {
                return .cloudKitConfiguration
            }
            return .cloudKitRuntime
        case .primaryLocalOnly, .emergencyInMemory:
            return .localStoreUnavailable
        }
    }

    private static func failureDetails(from error: Error) -> String {
        let localizedDescription = error.localizedDescription.trimmingCharacters(in: .whitespacesAndNewlines)
        if !localizedDescription.isEmpty {
            return localizedDescription
        }
        return String(describing: error)
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

        return try ModelContainer(
            for: schema,
            migrationPlan: migrationPlan(for: schema),
            configurations: [configuration]
        )
    }

    private static func makeEmergencyInMemoryContainer(schema: Schema) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            "MoneyzEmergency",
            schema: schema,
            isStoredInMemoryOnly: true,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: migrationPlan(for: schema),
            configurations: [configuration]
        )
    }

    static func previewContainer() -> ModelContainer {
        let controller = PersistenceController(inMemory: true, useCloudSync: false)
        if let container = controller.container {
            let context = ModelContext(container)
            SeedDataSeeder.seedPreviewData(in: context)
            return container
        }

        do {
            let fallbackContainer = try Self.makeEmergencyInMemoryContainer(schema: Self.defaultSchema())
            let context = ModelContext(fallbackContainer)
            SeedDataSeeder.seedPreviewData(in: context)
            return fallbackContainer
        } catch {
            preconditionFailure("Preview model container unavailable: \(error.localizedDescription)")
        }
    }
}
