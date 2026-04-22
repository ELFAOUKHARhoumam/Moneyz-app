import XCTest
@testable import Moneyz

@MainActor
final class SettingsStoreTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "SettingsStoreTests")!
        defaults.removePersistentDomain(forName: "SettingsStoreTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "SettingsStoreTests")
        super.tearDown()
    }

    func testCompleteOnboardingTrimsNameAndClampsSalaryCycle() {
        let store = SettingsStore(defaults: defaults)

        store.completeOnboarding(
            displayName: "  Houmam  ",
            currencyCode: "eur",
            salaryCycleStartDay: 99,
            usePINLock: true
        )

        XCTAssertEqual(store.displayName, "Houmam")
        XCTAssertEqual(store.currencyCode, "EUR")
        XCTAssertEqual(store.salaryCycleStartDay, 28)
        XCTAssertTrue(store.usePINLock)
        XCTAssertTrue(store.hasCompletedOnboarding)
    }

    func testInterfaceRefreshIDReflectsLanguageAndDirection() {
        let store = SettingsStore(defaults: defaults)
        store.languagePreference = .arabic

        XCTAssertTrue(store.interfaceRefreshID.contains("lang-arabic"))
        XCTAssertTrue(store.interfaceRefreshID.contains("rtl"))
        XCTAssertEqual(store.layoutDirection, .rightToLeft)
    }
}
