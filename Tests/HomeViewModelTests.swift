import XCTest
@testable import Moneyz

@MainActor
final class HomeViewModelTests: XCTestCase {
    func testUsesInjectedDashboardServiceForSummary() {
        let service = StubDashboardMetricsService()
        let viewModel = HomeViewModel(dashboardService: service)
        let defaults = UserDefaults(suiteName: "HomeViewModelTests")!
        defaults.removePersistentDomain(forName: "HomeViewModelTests")
        let settings = SettingsStore(defaults: defaults)

        _ = viewModel.summary(transactions: [], debts: [], settings: settings)

        XCTAssertTrue(service.didMakeSummary)
    }
}

private final class StubDashboardMetricsService: DashboardMetricsServing {
    private(set) var didMakeSummary = false

    func makeSummary(
        transactions: [MoneyTransaction],
        debts: [DebtRecord],
        interval: DateInterval,
        openingBalanceMinor: Int64
    ) -> DashboardSummary {
        didMakeSummary = true
        return DashboardSummary(
            balanceMinor: 0,
            incomeMinor: 0,
            expenseMinor: 0,
            owedToMeMinor: 0,
            iOweMinor: 0,
            intervalExpenseMinor: 0,
            intervalTransactionCount: 0
        )
    }
}
