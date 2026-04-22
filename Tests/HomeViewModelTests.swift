import SwiftData
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

@MainActor
final class TransactionsViewModelActionTests: XCTestCase {
    func testDeleteUsesInjectedAction() {
        var deletedTransactionID: UUID?
        let viewModel = TransactionsViewModel { transaction, _ in
            deletedTransactionID = transaction.id
        }
        let context = ModelContext(PersistenceController.previewContainer())
        let transaction = MoneyTransaction(amountMinor: 1_000, kind: .expense)

        viewModel.delete(transaction, in: context)

        XCTAssertEqual(deletedTransactionID, transaction.id)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testDeleteStoresErrorMessageWhenInjectedActionFails() {
        let viewModel = TransactionsViewModel { _, _ in
            throw NSError(domain: "TransactionsViewModelTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Delete failed"])
        }
        let context = ModelContext(PersistenceController.previewContainer())

        viewModel.delete(MoneyTransaction(amountMinor: 500, kind: .expense), in: context)

        XCTAssertEqual(viewModel.errorMessage, "Delete failed")
    }
}

@MainActor
final class BudgetViewModelActionTests: XCTestCase {
    func testDeleteRuleUsesInjectedAction() {
        var deletedRuleID: UUID?
        let viewModel = BudgetViewModel { rule, _ in
            deletedRuleID = rule.id
        }
        let context = ModelContext(PersistenceController.previewContainer())
        let rule = RecurringTransactionRule(title: "Rent", amountMinor: 80_000, nextRunDate: .now)

        viewModel.delete(rule, in: context)

        XCTAssertEqual(deletedRuleID, rule.id)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testDeleteRuleStoresErrorMessageWhenInjectedActionFails() {
        let viewModel = BudgetViewModel { _, _ in
            throw NSError(domain: "BudgetViewModelTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Rule delete failed"])
        }
        let context = ModelContext(PersistenceController.previewContainer())

        viewModel.delete(RecurringTransactionRule(title: "Salary", amountMinor: 125_000, kind: .income, nextRunDate: .now), in: context)

        XCTAssertEqual(viewModel.errorMessage, "Rule delete failed")
    }
}
