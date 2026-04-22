import CloudKit
import XCTest
@testable import Moneyz

@MainActor
final class CloudSyncStatusServiceTests: XCTestCase {
    func testReadinessDetectsMissingConfiguration() {
        let bundle = MockBundle(values: [:])
        let readiness = CloudKitCapability.readiness(from: bundle)

        XCTAssertFalse(readiness.isConfigured)
        XCTAssertFalse(readiness.hasUbiquityContainerIdentifier)
        XCTAssertFalse(readiness.hasICloudServices)
    }

    func testReadinessDetectsConfiguredCloudKitEntitlements() {
        let bundle = MockBundle(values: [
            "com.apple.developer.icloud-container-identifiers": ["iCloud.com.houmam.Moneyz"],
            "com.apple.developer.icloud-services": ["CloudKit"],
            "com.apple.developer.icloud-container-environment": "Development"
        ])
        let readiness = CloudKitCapability.readiness(from: bundle)

        XCTAssertTrue(readiness.isConfigured)
        XCTAssertTrue(readiness.hasCloudKitContainerEnvironment)
    }

    func testMapStatusPrefersNoAccountErrorMapping() {
        let status = CloudSyncStatusService.mapStatus(
            accountStatus: .couldNotDetermine,
            error: CKError(.notAuthenticated)
        )

        XCTAssertEqual(status, .noAccount)
    }

    func testMapStatusReturnsRestrictedForPermissionFailure() {
        let status = CloudSyncStatusService.mapStatus(
            accountStatus: .couldNotDetermine,
            error: CKError(.permissionFailure)
        )

        XCTAssertEqual(status, .restricted)
    }

    func testMapStatusReturnsTemporarilyUnavailableForTransientCKError() {
        let status = CloudSyncStatusService.mapStatus(
            accountStatus: .couldNotDetermine,
            error: CKError(.networkUnavailable)
        )

        XCTAssertEqual(status, .temporarilyUnavailable)
    }

    func testMapStatusReturnsRuntimeErrorForUnknownError() {
        let status = CloudSyncStatusService.mapStatus(
            accountStatus: .couldNotDetermine,
            error: NSError(domain: "Test", code: 99, userInfo: [NSLocalizedDescriptionKey: "Boom"])
        )

        XCTAssertEqual(status, .error("Boom"))
    }

    func testMapStatusMapsAccountStatusValues() {
        XCTAssertEqual(CloudSyncStatusService.mapStatus(accountStatus: .available, error: nil), .available)
        XCTAssertEqual(CloudSyncStatusService.mapStatus(accountStatus: .noAccount, error: nil), .noAccount)
        XCTAssertEqual(CloudSyncStatusService.mapStatus(accountStatus: .restricted, error: nil), .restricted)
        XCTAssertEqual(CloudSyncStatusService.mapStatus(accountStatus: .temporarilyUnavailable, error: nil), .temporarilyUnavailable)
        XCTAssertEqual(CloudSyncStatusService.mapStatus(accountStatus: .couldNotDetermine, error: nil), .unavailable)
    }
}

private final class MockBundle: Bundle, @unchecked Sendable {
    private let values: [String: Any]

    init(values: [String: Any]) {
        self.values = values
        super.init()
    }

    override func object(forInfoDictionaryKey key: String) -> Any? {
        values[key]
    }
}
