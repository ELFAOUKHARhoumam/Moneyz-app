#if canImport(XCTest)
import XCTest
@testable import Moneyz

final class CurrencyFormatterTests: XCTestCase {
    func testMinorUnitsFromDecimalString() {
        let locale = Locale(identifier: "en_US")
        XCTAssertEqual(CurrencyFormatter.minorUnits(from: "123.45", locale: locale), 12345)
    }
}
#endif
