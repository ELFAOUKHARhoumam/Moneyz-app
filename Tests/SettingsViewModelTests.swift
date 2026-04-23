import CloudKit
import SwiftData
import XCTest
@testable import Moneyz

@MainActor
final class SettingsViewModelTests: XCTestCase {
    func testUsesInjectedCloudServiceForStatusRefresh() async {
        let checker = StubCloudChecker(status: .available, error: nil)
        let service = CloudSyncStatusService(
            accountStatusChecker: checker,
            readinessProvider: {
                CloudKitReadiness(
                    hasUbiquityContainerIdentifier: true,
                    hasICloudServices: true,
                    hasCloudKitContainerEnvironment: true
                )
            }
        )

        let viewModel = SettingsViewModel(cloudService: service, authService: StubBiometricAuthService(canAuthenticateValue: true))
        let expectation = expectation(description: "sync status updated")
        viewModel.refreshSyncStatus()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(viewModel.syncStatus, .available)
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testUsesInjectedAuthServiceForBiometricsAvailability() {
        let viewModel = SettingsViewModel(
            cloudService: CloudSyncStatusService(
                accountStatusChecker: StubCloudChecker(status: .available, error: nil),
                readinessProvider: {
                    CloudKitReadiness(
                        hasUbiquityContainerIdentifier: true,
                        hasICloudServices: true,
                        hasCloudKitContainerEnvironment: true
                    )
                }
            ),
            authService: StubBiometricAuthService(canAuthenticateValue: false)
        )

        XCTAssertFalse(viewModel.biometricsAvailable)
    }

    func testApplyRecurringUsesInjectedActionAndStoresSuccessFeedback() {
        let context = ModelContext(PersistenceController.previewContainer())
        let viewModel = SettingsViewModel(
            cloudService: CloudSyncStatusService(
                accountStatusChecker: StubCloudChecker(status: .available, error: nil),
                readinessProvider: {
                    CloudKitReadiness(
                        hasUbiquityContainerIdentifier: true,
                        hasICloudServices: true,
                        hasCloudKitContainerEnvironment: true
                    )
                }
            ),
            authService: StubBiometricAuthService(canAuthenticateValue: true),
            applyRecurringAction: { _ in 3 }
        )

        viewModel.applyRecurring(in: context)

        XCTAssertEqual(viewModel.recurringApplyFeedback, .success(appliedCount: 3))
    }

    func testApplyRecurringStoresFailureFeedbackWhenInjectedActionFails() {
        let context = ModelContext(PersistenceController.previewContainer())
        let viewModel = SettingsViewModel(
            cloudService: CloudSyncStatusService(
                accountStatusChecker: StubCloudChecker(status: .available, error: nil),
                readinessProvider: {
                    CloudKitReadiness(
                        hasUbiquityContainerIdentifier: true,
                        hasICloudServices: true,
                        hasCloudKitContainerEnvironment: true
                    )
                }
            ),
            authService: StubBiometricAuthService(canAuthenticateValue: true),
            applyRecurringAction: { _ in
                throw NSError(domain: "SettingsViewModelTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Recurring run failed"])
            }
        )

        viewModel.applyRecurring(in: context)

        XCTAssertEqual(viewModel.recurringApplyFeedback, .failure(message: "Recurring run failed"))
    }
}

private struct StubBiometricAuthService: BiometricAuthServing {
    let canAuthenticateValue: Bool

    func canAuthenticate() -> Bool { canAuthenticateValue }
    func authenticate(reason: String) async -> Bool { false }
}

private final class StubCloudChecker: CloudKitAccountStatusChecking {
    let status: CKAccountStatus
    let error: Error?

    init(status: CKAccountStatus, error: Error?) {
        self.status = status
        self.error = error
    }

    func accountStatus(completionHandler: @escaping @Sendable (CKAccountStatus, (any Error)?) -> Void) {
        completionHandler(status, error)
    }
}
