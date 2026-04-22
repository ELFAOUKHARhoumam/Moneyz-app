import Foundation

struct CloudKitReadiness: Equatable, Sendable {
    let hasUbiquityContainerIdentifier: Bool
    let hasICloudServices: Bool
    let hasCloudKitContainerEnvironment: Bool

    nonisolated var isConfigured: Bool {
        hasUbiquityContainerIdentifier && hasICloudServices
    }
}

enum CloudKitCapability {
    nonisolated static var readiness: CloudKitReadiness {
        readiness(from: Bundle.main)
    }

    nonisolated static var isCloudKitEntitlementAvailable: Bool {
        readiness.isConfigured
    }

    nonisolated static func readiness(from bundle: Bundle) -> CloudKitReadiness {
        let ubiquityIdentifiers = bundle.object(forInfoDictionaryKey: "com.apple.developer.icloud-container-identifiers") as? [String]
        let services = bundle.object(forInfoDictionaryKey: "com.apple.developer.icloud-services") as? [String]
        let environment = bundle.object(forInfoDictionaryKey: "com.apple.developer.icloud-container-environment") as? String

        let normalizedServices = (services ?? []).map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
        let hasCloudKitService = normalizedServices.contains { $0 == "cloudkit" || $0 == "icloudkit" || $0 == "icloudkit-anonymous" }

        return CloudKitReadiness(
            hasUbiquityContainerIdentifier: !(ubiquityIdentifiers ?? []).isEmpty,
            hasICloudServices: hasCloudKitService,
            hasCloudKitContainerEnvironment: !(environment ?? "").isEmpty
        )
    }
}
