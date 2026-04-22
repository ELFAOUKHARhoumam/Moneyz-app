import CloudKit
import Combine
import Foundation

protocol CloudKitAccountStatusChecking {
    func accountStatus(completionHandler: @escaping @Sendable (CKAccountStatus, Error?) -> Void)
}

extension CKContainer: CloudKitAccountStatusChecking {}

@MainActor
final class CloudSyncStatusService: ObservableObject {
    @Published private(set) var status: SyncAvailabilityStatus = .checking

    private let accountStatusChecker: CloudKitAccountStatusChecking?
    private let readinessProvider: () -> CloudKitReadiness
    private let initialReadiness: CloudKitReadiness

    init(
        accountStatusChecker: CloudKitAccountStatusChecking? = nil,
        readinessProvider: @escaping () -> CloudKitReadiness = { CloudKitCapability.readiness(from: Bundle.main) }
    ) {
        let resolvedReadiness = readinessProvider()
        self.readinessProvider = readinessProvider
        self.initialReadiness = resolvedReadiness
        self.accountStatusChecker = accountStatusChecker ?? Self.makeDefaultAccountStatusChecker(readiness: resolvedReadiness)
    }

    nonisolated private static func makeDefaultAccountStatusChecker(readiness: CloudKitReadiness) -> CloudKitAccountStatusChecking? {
        guard readiness.isConfigured else { return nil }
        return CKContainer.default()
    }

    func refresh() {
        status = .checking

        let readiness = initialReadiness
        guard readiness.isConfigured, let accountStatusChecker else {
            status = .notConfigured
            return
        }

        guard NSClassFromString("CKContainer") != nil else {
            status = .unavailable
            return
        }

        accountStatusChecker.accountStatus { [weak self] accountStatus, error in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.status = Self.mapStatus(accountStatus: accountStatus, error: error)
            }
        }
    }

    static func mapStatus(accountStatus: CKAccountStatus, error: Error?) -> SyncAvailabilityStatus {
        if let ckError = error as? CKError {
            switch ckError.code {
            case .notAuthenticated:
                return .noAccount
            case .permissionFailure:
                return .restricted
            case .networkUnavailable, .networkFailure, .serviceUnavailable, .requestRateLimited, .zoneBusy:
                return .temporarilyUnavailable
            default:
                return .error(ckError.localizedDescription)
            }
        }

        if let error {
            return .error(error.localizedDescription)
        }

        switch accountStatus {
        case .available:
            return .available
        case .noAccount:
            return .noAccount
        case .restricted:
            return .restricted
        case .couldNotDetermine:
            return .unavailable
        case .temporarilyUnavailable:
            return .temporarilyUnavailable
        @unknown default:
            return .unavailable
        }
    }
}
