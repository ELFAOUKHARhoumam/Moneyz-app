import Foundation

struct DebtSummary {
    let owedToMeMinor: Int64
    let iOweMinor: Int64
    let openCount: Int
    let overdueCount: Int
    let dueSoonCount: Int

    var netMinor: Int64 {
        owedToMeMinor - iOweMinor
    }
}

struct DebtSummaryService {
    func summarize(_ debts: [DebtRecord]) -> DebtSummary {
        let now = Date()
        let upcomingCutoff = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now
        let openDebts = debts.filter { $0.status != .settled }
        let owedToMe = openDebts
            .filter { $0.direction == .owedToMe }
            .reduce(0) { $0 + $1.amountMinor }
        let iOwe = openDebts
            .filter { $0.direction == .iOwe }
            .reduce(0) { $0 + $1.amountMinor }
        let overdueCount = openDebts.filter {
            guard let dueDate = $0.dueDate else { return false }
            return dueDate < now
        }.count
        let dueSoonCount = openDebts.filter {
            guard let dueDate = $0.dueDate else { return false }
            return dueDate >= now && dueDate <= upcomingCutoff
        }.count

        return DebtSummary(
            owedToMeMinor: owedToMe,
            iOweMinor: iOwe,
            openCount: openDebts.count,
            overdueCount: overdueCount,
            dueSoonCount: dueSoonCount
        )
    }
}
