#if canImport(XCTest)
import XCTest
@testable import Moneyz

final class DebtSummaryServiceTests: XCTestCase {
    func testSummaryIgnoresSettledDebts() {
        let openOwed = DebtRecord(counterpartyName: "Ali", amountMinor: 10000, direction: .owedToMe, status: .open)
        let openIOwe = DebtRecord(counterpartyName: "Shop", amountMinor: 4000, direction: .iOwe, status: .open)
        let settled = DebtRecord(counterpartyName: "Old Loan", amountMinor: 9000, direction: .owedToMe, status: .settled)

        let summary = DebtSummaryService().summarize([openOwed, openIOwe, settled])

        XCTAssertEqual(summary.owedToMeMinor, 10000)
        XCTAssertEqual(summary.iOweMinor, 4000)
        XCTAssertEqual(summary.netMinor, 6000)
        XCTAssertEqual(summary.openCount, 2)
    }

    func testSummaryTracksOverdueAndDueSoonCounts() {
        let overdue = DebtRecord(
            counterpartyName: "Late",
            amountMinor: 1_000,
            direction: .iOwe,
            issueDate: .now,
            dueDate: Calendar.current.date(byAdding: .day, value: -2, to: .now),
            status: .open
        )
        let dueSoon = DebtRecord(
            counterpartyName: "Soon",
            amountMinor: 2_000,
            direction: .owedToMe,
            issueDate: .now,
            dueDate: Calendar.current.date(byAdding: .day, value: 3, to: .now),
            status: .open
        )
        let later = DebtRecord(
            counterpartyName: "Later",
            amountMinor: 3_000,
            direction: .owedToMe,
            issueDate: .now,
            dueDate: Calendar.current.date(byAdding: .day, value: 20, to: .now),
            status: .open
        )

        let summary = DebtSummaryService().summarize([overdue, dueSoon, later])

        XCTAssertEqual(summary.overdueCount, 1)
        XCTAssertEqual(summary.dueSoonCount, 1)
        XCTAssertEqual(summary.openCount, 3)
    }
}
#endif