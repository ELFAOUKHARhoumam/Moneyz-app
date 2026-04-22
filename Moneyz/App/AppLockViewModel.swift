import Combine
import OSLog
import SwiftUI

@MainActor
final class AppLockViewModel: ObservableObject {
    @Published var isLocked = false
    @Published var isAuthenticating = false
    @Published var errorMessage: String?
    @Published private(set) var isPINEntryTemporarilyBlocked = false
    @Published private(set) var remainingRetryDelay: Int = 0

    private let authService: BiometricAuthServing
    private let logger = MoneyzLogger.auth
    private var shouldSkipNextPrepareLock = false
    private var failedPINAttempts = 0
    private var retryTask: Task<Void, Never>?

    init(authService: BiometricAuthServing? = nil) {
        self.authService = authService ?? BiometricAuthService()
    }

    deinit {
        retryTask?.cancel()
    }

    func prepareIfNeeded(settings: SettingsStore) {
        errorMessage = nil

        if shouldSkipNextPrepareLock {
            shouldSkipNextPrepareLock = false
            isLocked = false
            logger.debug("Skipping next prepare lock by explicit request")
            return
        }

        isLocked = requiresLock(settings: settings)
        logger.debug("Prepared lock state. isLocked=\(self.isLocked, privacy: .public)")
    }

    func skipNextPrepareLock() {
        shouldSkipNextPrepareLock = true
    }

    func handleScenePhase(_ phase: ScenePhase, settings: SettingsStore) {
        guard requiresLock(settings: settings) else {
            isLocked = false
            errorMessage = nil
            clearRetryBlockState()
            logger.debug("Lock not required for current settings")
            return
        }

        switch phase {
        case .background, .inactive:
            isLocked = true
            errorMessage = nil
            logger.notice("Lock activated due to scene phase change")
        case .active:
            guard settings.useFaceIDLock else { return }
            logger.debug("Attempting biometric unlock after becoming active")
            Task { @MainActor in
                await unlockIfPossible(settings: settings)
            }
        @unknown default:
            break
        }
    }

    func unlockIfPossible(settings: SettingsStore) async {
        guard settings.useFaceIDLock, isLocked, !isAuthenticating else { return }

        isAuthenticating = true
        let success = await authService.authenticate(reason: AppLocalizer.string("lock.biometricReason"))
        isAuthenticating = false

        if success {
            errorMessage = nil
            isLocked = false
            resetFailedPINAttempts()
            logger.notice("Biometric unlock succeeded")
        } else {
            logger.debug("Biometric unlock was not completed successfully")
        }
    }

    func unlock(withPIN pin: String, settings: SettingsStore) {
        guard settings.usePINLock else { return }

        guard !isPINEntryTemporarilyBlocked else {
            errorMessage = AppLocalizer.string("pin.retryDelay")
            logger.notice("Rejected PIN entry because retry delay is active")
            return
        }

        let normalizedPIN = pin.filter { $0.isNumber }

        guard normalizedPIN.count == 4 else {
            errorMessage = AppLocalizer.string("pin.validation.length")
            logger.debug("Rejected PIN entry because length was invalid")
            return
        }

        let verificationResult = PINSecurity.verifyDetailed(pin: normalizedPIN)
        guard verificationResult.isValid else {
            registerFailedPINAttempt()
            errorMessage = AppLocalizer.string(isPINEntryTemporarilyBlocked ? "pin.retryDelay" : "pin.validation.invalid")
            logger.notice("PIN verification failed")
            return
        }

        errorMessage = nil
        isLocked = false
        resetFailedPINAttempts()
        logger.notice("PIN unlock succeeded")
    }

    func clearError() {
        errorMessage = nil
    }

    private func requiresLock(settings: SettingsStore) -> Bool {
        settings.useFaceIDLock || settings.usePINLock
    }

    private func registerFailedPINAttempt() {
        failedPINAttempts += 1
        logger.notice("Registered failed PIN attempt count=\(self.failedPINAttempts, privacy: .public)")
        guard failedPINAttempts >= 3 else { return }
        beginRetryBlock(seconds: 10)
    }

    private func resetFailedPINAttempts() {
        failedPINAttempts = 0
        clearRetryBlockState()
    }

    private func beginRetryBlock(seconds: Int) {
        retryTask?.cancel()
        isPINEntryTemporarilyBlocked = true
        remainingRetryDelay = seconds
        logger.notice("Started PIN retry delay for \(seconds, privacy: .public) second(s)")

        retryTask = Task { @MainActor in
            while remainingRetryDelay > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                remainingRetryDelay -= 1
            }
            clearRetryBlockState()
        }
    }

    private func clearRetryBlockState() {
        retryTask?.cancel()
        retryTask = nil
        isPINEntryTemporarilyBlocked = false
        remainingRetryDelay = 0
    }
}
