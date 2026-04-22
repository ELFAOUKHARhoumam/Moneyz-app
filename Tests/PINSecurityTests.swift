import XCTest
@testable import Moneyz

final class PINSecurityTests: XCTestCase {
    override func setUp() {
        super.setUp()
        PINSecurity.removePIN()
    }

    override func tearDown() {
        PINSecurity.removePIN()
        super.tearDown()
    }

    func testSaveAndVerifyHashedPIN() {
        XCTAssertTrue(PINSecurity.save(pin: "1234"))
        XCTAssertTrue(PINSecurity.verify(pin: "1234"))
        XCTAssertFalse(PINSecurity.verify(pin: "9999"))
    }

    func testVerifyDetailedSupportsHashedStorage() {
        XCTAssertTrue(PINSecurity.save(pin: "1234"))

        let result = PINSecurity.verifyDetailed(pin: "1234")
        XCTAssertTrue(result.isValid)
        XCTAssertFalse(result.wasMigrated)
    }

    func testRejectsInvalidPINLength() {
        XCTAssertFalse(PINSecurity.save(pin: "12"))
        XCTAssertFalse(PINSecurity.verify(pin: "12"))
    }
}
