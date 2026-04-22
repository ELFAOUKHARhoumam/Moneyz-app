import Combine
import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    enum RecurringApplyFeedback: Equatable {
        case success(appliedCount: Int)
        case failure(message: String)

        var message: String {
            switch self {
            case .success(let appliedCount):
                if appliedCount > 0 {
                    return "Applied \(appliedCount) recurring transaction(s)."
                }
                return "No recurring transactions were due."
            case .failure(let message):
                return message
            }
        }

        var isError: Bool {
            if case .failure = self { return true }
            return false
        }
    }

    @Published var openingBalanceText: String
    @Published private(set) var syncStatus: SyncAvailabilityStatus = .checking
    @Published private(set) var biometricsAvailable: Bool
    @Published var saveErrorMessage: String?
    @Published private(set) var recurringApplyFeedback: RecurringApplyFeedback?

    private let cloudService: CloudSyncStatusService
    private let authService: BiometricAuthServing
    private var cancellables: Set<AnyCancellable> = []

    init(
        cloudService: CloudSyncStatusService? = nil,
        authService: BiometricAuthServing? = nil
    ) {
        let resolvedAuthService = authService ?? BiometricAuthService()
        self.cloudService = cloudService ?? CloudSyncStatusService()
        self.authService = resolvedAuthService
        self.openingBalanceText = ""
        self.biometricsAvailable = resolvedAuthService.canAuthenticate()

        self.cloudService.$status
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.syncStatus = status
            }
            .store(in: &cancellables)
    }

    var hasStoredPIN: Bool {
        PINSecurity.hasStoredPIN
    }

    func refreshSyncStatus() {
        cloudService.refresh()
    }

    func syncOpeningBalance(from settings: SettingsStore) {
        openingBalanceText = CurrencyFormatter.decimalString(from: settings.openingBalanceMinor, locale: settings.locale)
    }

    func applyOpeningBalance(to settings: SettingsStore) {
        guard let amountMinor = CurrencyFormatter.minorUnits(from: openingBalanceText, locale: settings.locale) else {
            saveErrorMessage = AppLocalizer.string("validation.amount")
            return
        }

        settings.openingBalanceMinor = amountMinor
        saveErrorMessage = nil
    }

    @discardableResult
    func savePIN(_ pin: String, settings: SettingsStore) -> Bool {
        guard PINSecurity.save(pin: pin) else {
            saveErrorMessage = AppLocalizer.string("pin.saveFailed")
            return false
        }

        settings.usePINLock = true
        saveErrorMessage = nil
        return true
    }

    func disablePINLock(settings: SettingsStore) {
        PINSecurity.removePIN()
        settings.usePINLock = false
        saveErrorMessage = nil
    }

    func recordRecurringApplySuccess(appliedCount: Int) {
        recurringApplyFeedback = .success(appliedCount: appliedCount)
    }

    func recordRecurringApplyFailure(_ error: Error) {
        recurringApplyFeedback = .failure(message: error.localizedDescription)
    }

    func clearRecurringApplyFeedback() {
        recurringApplyFeedback = nil
    }
}
