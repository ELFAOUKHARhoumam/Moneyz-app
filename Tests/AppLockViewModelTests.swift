import XCTest
@testable import Moneyz

@MainActor
final class AppLockViewModelTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "AppLockViewModelTests")!
        defaults.removePersistentDomain(forName: "AppLockViewModelTests")
        PINSecurity.removePIN()
    }

    override func tearDown() {
        PINSecurity.removePIN()
        defaults.removePersistentDomain(forName: "AppLockViewModelTests")
        super.tearDown()
    }

    func testThreeInvalidPINAttemptsTriggerRetryBlock() {
        let settings = SettingsStore(defaults: defaults)
        settings.usePINLock = true
        XCTAssertTrue(PINSecurity.save(pin: "2486"))

        let viewModel = AppLockViewModel(authService: StubBiometricAuthService())
        viewModel.prepareIfNeeded(settings: settings)

        viewModel.unlock(withPIN: "0000", settings: settings)
        viewModel.unlock(withPIN: "0000", settings: settings)
        viewModel.unlock(withPIN: "0000", settings: settings)

        XCTAssertTrue(viewModel.isPINEntryTemporarilyBlocked)
        XCTAssertEqual(viewModel.remainingRetryDelay, 10)
    }

    func testSuccessfulPINUnlockClearsLockState() {
        let settings = SettingsStore(defaults: defaults)
        settings.usePINLock = true
        XCTAssertTrue(PINSecurity.save(pin: "2486"))

        let viewModel = AppLockViewModel(authService: StubBiometricAuthService())
        viewModel.prepareIfNeeded(settings: settings)
        viewModel.unlock(withPIN: "2486", settings: settings)

        XCTAssertFalse(viewModel.isLocked)
        XCTAssertFalse(viewModel.isPINEntryTemporarilyBlocked)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testPrepareIfNeededSkipsLockOnceWhenRequested() {
        let settings = SettingsStore(defaults: defaults)
        settings.usePINLock = true

        let viewModel = AppLockViewModel(authService: StubBiometricAuthService())
        viewModel.skipNextPrepareLock()
        viewModel.prepareIfNeeded(settings: settings)

        XCTAssertFalse(viewModel.isLocked)

        viewModel.prepareIfNeeded(settings: settings)

        XCTAssertTrue(viewModel.isLocked)
    }

    func testHandleScenePhaseClearsRetryStateWhenLockNotRequired() {
        let settings = SettingsStore(defaults: defaults)
        settings.usePINLock = true
        XCTAssertTrue(PINSecurity.save(pin: "2486"))

        let viewModel = AppLockViewModel(authService: StubBiometricAuthService())
        viewModel.prepareIfNeeded(settings: settings)
        viewModel.unlock(withPIN: "0000", settings: settings)
        viewModel.unlock(withPIN: "0000", settings: settings)
        viewModel.unlock(withPIN: "0000", settings: settings)

        XCTAssertTrue(viewModel.isPINEntryTemporarilyBlocked)

        settings.usePINLock = false
        viewModel.handleScenePhase(.active, settings: settings)

        XCTAssertFalse(viewModel.isLocked)
        XCTAssertFalse(viewModel.isPINEntryTemporarilyBlocked)
        XCTAssertEqual(viewModel.remainingRetryDelay, 0)
        XCTAssertNil(viewModel.errorMessage)
    }
}

private struct StubBiometricAuthService: BiometricAuthServing {
    func canAuthenticate() -> Bool { false }
    func authenticate(reason: String) async -> Bool { false }
}
