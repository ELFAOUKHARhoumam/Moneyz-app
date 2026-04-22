import Foundation

struct DashboardSummary {
    let balanceMinor: Int64
    let incomeMinor: Int64
    let expenseMinor: Int64
    let owedToMeMinor: Int64
    let iOweMinor: Int64
    let intervalExpenseMinor: Int64
    let intervalTransactionCount: Int

    var netDebtMinor: Int64 {
        owedToMeMinor - iOweMinor
    }

    var savingsMinor: Int64 {
        incomeMinor - expenseMinor
    }

    var burnRateProgress: Double {
        guard incomeMinor > 0 else { return expenseMinor > 0 ? 1 : 0 }
        return min(max(Double(expenseMinor) / Double(incomeMinor), 0), 1)
    }
}

struct DashboardMetricsService {
    func makeSummary(
        transactions: [MoneyTransaction],
        debts: [DebtRecord],
        interval: DateInterval,
        openingBalanceMinor: Int64
    ) -> DashboardSummary {
        let balanceMinor = openingBalanceMinor + transactions.reduce(0) { $0 + $1.signedMinorAmount }

        let intervalTransactions = transactions.filter { DateRangeService.contains($0.transactionDate, in: interval) }
        let incomeMinor = intervalTransactions
            .filter { $0.kind == .income }
            .reduce(0) { $0 + $1.amountMinor }
        let expenseMinor = intervalTransactions
            .filter { $0.kind == .expense }
            .reduce(0) { $0 + $1.amountMinor }

        let openDebts = debts.filter { $0.status != .settled }
        let owedToMeMinor = openDebts
            .filter { $0.direction == .owedToMe }
            .reduce(0) { $0 + $1.amountMinor }
        let iOweMinor = openDebts
            .filter { $0.direction == .iOwe }
            .reduce(0) { $0 + $1.amountMinor }

        return DashboardSummary(
            balanceMinor: balanceMinor,
            incomeMinor: incomeMinor,
            expenseMinor: expenseMinor,
            owedToMeMinor: owedToMeMinor,
            iOweMinor: iOweMinor,
            intervalExpenseMinor: expenseMinor,
            intervalTransactionCount: intervalTransactions.count
        )
    }
}
