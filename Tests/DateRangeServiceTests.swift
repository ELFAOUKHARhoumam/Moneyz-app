#if canImport(XCTest)
import XCTest
@testable import Moneyz

final class DateRangeServiceTests: XCTestCase {
    func testSalaryCycleAnchorsAroundReferenceDate() {
        let calendar = Calendar(identifier: .gregorian)
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.dateFormat = "yyyy-MM-dd"

        let reference = formatter.date(from: "2026-04-14")!
        let interval = DateRangeService.salaryCycleInterval(reference: reference, cycleStartDay: 10, calendar: calendar)

        XCTAssertEqual(formatter.string(from: interval.start), "2026-04-10")
        XCTAssertEqual(formatter.string(from: interval.end), "2026-05-10")
    }
}
#endif
