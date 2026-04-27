import Foundation

// MARK: - PersonBudgetSnapshot
// FIX: warning threshold aligned to 0.85 (was already 0.85 here, but BudgetView.snapshotCard
// used 0.9 for the progress bar color. Now both use the same constant defined in BudgetView.
// The statusKey logic here is the source of truth.
struct PersonBudgetSnapshot: Identifiable {
    let person: PersonProfile
    let plan: PersonBudgetPlan
    let spentMinor: Int64
    let interval: DateInterval

    var id: UUID { plan.id }
    var remainingMinor: Int64 { max(plan.amountMinor - spentMinor, 0) }
    var progress: Double {
        guard plan.amountMinor > 0 else { return 0 }
        return min(Double(spentMinor) / Double(plan.amountMinor), 1.0)
    }

    // Thresholds — single source of truth for the status message.
    // BudgetView.snapshotCard must reference the same values (kWarningThreshold = 0.85).
    var statusKey: String {
        if spentMinor == 0 { return "budget.status.notStarted" }
        if progress >= 1.0  { return "budget.status.exceeded" }
        if progress >= 0.85 { return "budget.status.warning" }  // was already 0.85 ✓
        return "budget.status.onTrack"
    }
}

// MARK: - BudgetInsightsService
struct BudgetInsightsService {
    func snapshots(
        people: [PersonProfile],
        transactions: [MoneyTransaction],
        interval: DateInterval
    ) -> [PersonBudgetSnapshot] {
        people.compactMap { person in
            guard let plan = person.activeBudget else { return nil }
            let spentMinor = transactions
                .filter {
                    $0.kind == .expense &&
                    $0.person?.id == person.id &&
                    DateRangeService.contains($0.transactionDate, in: interval)
                }
                .reduce(0) { $0 + $1.amountMinor }

            return PersonBudgetSnapshot(person: person, plan: plan, spentMinor: spentMinor, interval: interval)
        }
        .sorted { $0.person.name.localizedCaseInsensitiveCompare($1.person.name) == .orderedAscending }
    }
}
