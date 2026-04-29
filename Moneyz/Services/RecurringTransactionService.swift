import Foundation
import OSLog
import SwiftData

struct RecurringTransactionService {
    private let calendar: Calendar
    private let logger: Logger

    init(
        calendar: Calendar = .current,
        logger: Logger = MoneyzLogger.recurring
    ) {
        self.calendar = calendar
        self.logger = logger
    }

    @discardableResult
    func applyDueRules(on referenceDate: Date = .now, in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<RecurringTransactionRule>()
        let rules = try context.fetch(descriptor)
            .filter { $0.isActive }
            .sorted { $0.nextRunDate < $1.nextRunDate }

        let cutoff = calendar.startOfDay(for: referenceDate)
        var appliedCount = 0
        var hasChanges = false

        logger.debug("Evaluating \(rules.count) active recurring rule(s) with cutoff \(cutoff, privacy: .public)")

        for rule in rules {
            while calendar.startOfDay(for: rule.nextRunDate) <= cutoff {
                let scheduledDay = calendar.startOfDay(for: rule.nextRunDate)

                if try hasExistingTransaction(for: rule, on: scheduledDay, in: context) {
                    logger.warning("Skipping duplicate recurring transaction for rule \(rule.id.uuidString, privacy: .public) on \(scheduledDay, privacy: .public)")
                    rule.nextRunDate = rule.frequency.nextDate(after: scheduledDay, calendar: calendar)
                    hasChanges = true
                    continue
                }

                let transaction = MoneyTransaction(
                    amountMinor: rule.amountMinor,
                    kind: rule.kind,
                    transactionDate: scheduledDay,
                    customItemName: rule.title,
                    note: rule.note,
                    isRecurringInstance: true,
                    recurringSourceID: rule.id,
                    category: rule.category,
                    item: rule.item,
                    person: rule.person
                )
                context.insert(transaction)

                logger.notice("Inserted recurring transaction for rule \(rule.id.uuidString, privacy: .public) on \(scheduledDay, privacy: .public)")
                rule.lastAppliedAt = referenceDate
                rule.nextRunDate = rule.frequency.nextDate(after: scheduledDay, calendar: calendar)
                appliedCount += 1
                hasChanges = true
            }
        }

        if hasChanges {
            logger.debug("Saving recurring changes after applying \(appliedCount) transaction(s)")
            try context.save()
        } else {
            logger.debug("No recurring changes detected for current evaluation")
        }
        return appliedCount
    }

    private func hasExistingTransaction(for rule: RecurringTransactionRule, on scheduledDay: Date, in context: ModelContext) throws -> Bool {
        let startOfDay = calendar.startOfDay(for: scheduledDay)
        let startOfNextDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay.addingTimeInterval(86_400)
        let ruleID = rule.id

        var descriptor = FetchDescriptor<MoneyTransaction>(
            predicate: #Predicate<MoneyTransaction> { transaction in
                transaction.isRecurringInstance &&
                transaction.recurringSourceID == ruleID &&
                transaction.transactionDate >= startOfDay &&
                transaction.transactionDate < startOfNextDay
            }
        )
        descriptor.fetchLimit = 1
        descriptor.propertiesToFetch = [\.id]
        return try !context.fetch(descriptor).isEmpty
    }
}
