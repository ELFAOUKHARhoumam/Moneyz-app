import Foundation
import SwiftData
import Combine

protocol DashboardMetricsServing {
    func makeSummary(
        transactions: [MoneyTransaction],
        debts: [DebtRecord],
        interval: DateInterval,
        openingBalanceMinor: Int64
    ) -> DashboardSummary
}

extension DashboardMetricsService: DashboardMetricsServing {}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var rangeOption: TimeRangeOption = .month

    private let dashboardService: DashboardMetricsServing

    init(dashboardService: DashboardMetricsServing? = nil) {
        self.dashboardService = dashboardService ?? DashboardMetricsService()
    }

    func interval(settings: SettingsStore) -> DateInterval {
        DateRangeService.interval(
            for: rangeOption,
            reference: .now,
            salaryCycleStartDay: settings.salaryCycleStartDay
        )
    }

    func summary(transactions: [MoneyTransaction], debts: [DebtRecord], settings: SettingsStore) -> DashboardSummary {
        dashboardService.makeSummary(
            transactions: transactions,
            debts: debts,
            interval: interval(settings: settings),
            openingBalanceMinor: settings.openingBalanceMinor
        )
    }

    func recentGroups(from transactions: [MoneyTransaction], settings: SettingsStore) -> [(date: Date, transactions: [MoneyTransaction])] {
        let filtered = transactions
            .filter { DateRangeService.contains($0.transactionDate, in: interval(settings: settings)) }
            .sorted { $0.transactionDate > $1.transactionDate }

        let grouped = Dictionary(grouping: Array(filtered.prefix(20))) {
            Calendar.current.startOfDay(for: $0.transactionDate)
        }

        return grouped
            .map { (date: $0.key, transactions: $0.value.sorted { $0.transactionDate > $1.transactionDate }) }
            .sorted { $0.date > $1.date }
    }
}
