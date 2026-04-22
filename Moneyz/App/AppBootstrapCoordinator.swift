import Combine
import OSLog
import SwiftUI
import SwiftData

@MainActor
final class AppBootstrapCoordinator: ObservableObject {
    private let logger = MoneyzLogger.bootstrap
    private let recurringService: RecurringTransactionService
    private var hasBootstrapped = false

    init(recurringService: RecurringTransactionService? = nil) {
        self.recurringService = recurringService ?? RecurringTransactionService()
    }

    func bootstrapIfNeeded(in context: ModelContext, settings: SettingsStore, appLock: AppLockViewModel) {
        guard !hasBootstrapped else {
            logger.debug("Skipping bootstrap because app already bootstrapped")
            return
        }

        logger.notice("Starting bootstrap sequence")
        hasBootstrapped = true

        SeedDataSeeder.seedIfNeeded(in: context)
        applyRecurringTransactions(in: context, reason: "initial bootstrap")
        appLock.prepareIfNeeded(settings: settings)
        logger.notice("Bootstrap sequence completed")
    }

    func handleScenePhase(_ phase: ScenePhase, context: ModelContext, settings: SettingsStore, appLock: AppLockViewModel) {
        logger.debug("Handling scene phase change: \(String(describing: phase), privacy: .public)")
        if phase == .active {
            applyRecurringTransactions(in: context, reason: "scene became active")
        }
        appLock.handleScenePhase(phase, settings: settings)
    }

    private func applyRecurringTransactions(in context: ModelContext, reason: String) {
        do {
            let appliedCount = try recurringService.applyDueRules(in: context)
            logger.notice("Recurring run for \(reason, privacy: .public) finished with \(appliedCount) applied transaction(s)")
        } catch {
            logger.error("Failed to apply recurring transactions during \(reason, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }
}
