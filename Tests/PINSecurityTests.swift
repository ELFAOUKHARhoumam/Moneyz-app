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
        XCTAssertTrue(PINSecurity.save(pin: "2486"))
        XCTAssertTrue(PINSecurity.verify(pin: "2486"))
        XCTAssertFalse(PINSecurity.verify(pin: "9999"))
    }

    func testVerifyDetailedSupportsHashedStorage() {
        XCTAssertTrue(PINSecurity.save(pin: "2486"))

        let result = PINSecurity.verifyDetailed(pin: "2486")
        XCTAssertTrue(result.isValid)
        XCTAssertFalse(result.wasMigrated)
    }

    func testRejectsInvalidPINLength() {
        XCTAssertFalse(PINSecurity.save(pin: "12"))
        XCTAssertFalse(PINSecurity.verify(pin: "12"))
    }

    func testRejectsRepeatedDigitPINs() {
        XCTAssertEqual(PINSecurity.validateNewPIN("1111"), .repeatedDigits)
        XCTAssertFalse(PINSecurity.save(pin: "1111"))
    }

    func testRejectsSequentialPINs() {
        XCTAssertEqual(PINSecurity.validateNewPIN("1234"), .sequentialDigits)
        XCTAssertEqual(PINSecurity.validateNewPIN("4321"), .sequentialDigits)
        XCTAssertFalse(PINSecurity.save(pin: "1234"))
        XCTAssertFalse(PINSecurity.save(pin: "4321"))
    }

    func testAcceptsNonSequentialNonRepeatedPIN() {
        XCTAssertNil(PINSecurity.validateNewPIN("2486"))
        XCTAssertTrue(PINSecurity.save(pin: "2486"))
        XCTAssertTrue(PINSecurity.verify(pin: "2486"))
    }
}
