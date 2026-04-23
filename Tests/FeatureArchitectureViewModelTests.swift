import SwiftData
import XCTest
@testable import Moneyz

@MainActor
final class DebtViewModelActionTests: XCTestCase {
    func testRequestDeleteDoesNotDeleteUntilConfirmed() {
        var deleted = false
        let viewModel = DebtViewModel { _, _ in
            deleted = true
        }
        let debt = DebtRecord(counterpartyName: "Bank", amountMinor: 15_000, direction: .iOwe)

        viewModel.requestDelete(debt)

        XCTAssertFalse(deleted)
        XCTAssertEqual(viewModel.pendingDeletionDebt?.id, debt.id)
    }

    func testDeleteUsesInjectedAction() {
        var deletedDebtID: UUID?
        let viewModel = DebtViewModel { debt, _ in
            deletedDebtID = debt.id
        }
        let context = ModelContext(PersistenceController.previewContainer())
        let debt = DebtRecord(counterpartyName: "Bank", amountMinor: 15_000, direction: .iOwe)

        viewModel.delete(debt, in: context)

        XCTAssertEqual(deletedDebtID, debt.id)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testDeleteStoresErrorMessageWhenInjectedActionFails() {
        let viewModel = DebtViewModel { _, _ in
            throw NSError(domain: "DebtViewModelTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Debt delete failed"])
        }
        let context = ModelContext(PersistenceController.previewContainer())

        viewModel.delete(DebtRecord(counterpartyName: "Loan", amountMinor: 12_000, direction: .iOwe), in: context)

        XCTAssertEqual(viewModel.errorMessage, "Debt delete failed")
    }

    func testConfirmDeleteUsesPendingDebtAndClearsState() {
        var deletedDebtID: UUID?
        let viewModel = DebtViewModel { debt, _ in
            deletedDebtID = debt.id
        }
        let context = ModelContext(PersistenceController.previewContainer())
        let debt = DebtRecord(counterpartyName: "Loan", amountMinor: 12_000, direction: .iOwe)

        viewModel.requestDelete(debt)
        viewModel.confirmDelete(in: context)

        XCTAssertEqual(deletedDebtID, debt.id)
        XCTAssertNil(viewModel.pendingDeletionDebt)
    }
}

@MainActor
final class AddEditTransactionViewModelActionTests: XCTestCase {
    func testDeleteUsesInjectedAction() {
        var deletedTransactionID: UUID?
        let transaction = MoneyTransaction(amountMinor: 2_000, kind: .expense)
        let viewModel = AddEditTransactionViewModel(transaction: transaction) { existingTransaction, _ in
            deletedTransactionID = existingTransaction.id
        }
        let context = ModelContext(PersistenceController.previewContainer())

        let result = viewModel.delete(in: context)

        XCTAssertTrue(result)
        XCTAssertEqual(deletedTransactionID, transaction.id)
        XCTAssertNil(viewModel.errorMessage)
    }

    func testDeleteStoresErrorMessageWhenInjectedActionFails() {
        let viewModel = AddEditTransactionViewModel(transaction: MoneyTransaction(amountMinor: 1_000, kind: .income)) { _, _ in
            throw NSError(domain: "AddEditTransactionViewModelTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Transaction delete failed"])
        }
        let context = ModelContext(PersistenceController.previewContainer())

        let result = viewModel.delete(in: context)

        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "Transaction delete failed")
    }
}

@MainActor
final class TransactionsViewModelSafetyTests: XCTestCase {
    func testRequestDeleteDoesNotDeleteUntilConfirmed() {
        var deleted = false
        let transaction = MoneyTransaction(amountMinor: 2_000, kind: .expense)
        let viewModel = TransactionsViewModel { _, _ in
            deleted = true
        }

        viewModel.requestDelete(transaction)

        XCTAssertFalse(deleted)
        XCTAssertEqual(viewModel.pendingDeletionTransaction?.id, transaction.id)
    }

    func testConfirmDeleteUsesPendingTransactionAndClearsState() {
        var deletedTransactionID: UUID?
        let transaction = MoneyTransaction(amountMinor: 2_000, kind: .expense)
        let viewModel = TransactionsViewModel { existingTransaction, _ in
            deletedTransactionID = existingTransaction.id
        }
        let context = ModelContext(PersistenceController.previewContainer())

        viewModel.requestDelete(transaction)
        viewModel.confirmDelete(in: context)

        XCTAssertEqual(deletedTransactionID, transaction.id)
        XCTAssertNil(viewModel.pendingDeletionTransaction)
    }
}

@MainActor
final class DebtEditorViewModelTests: XCTestCase {
    func testSaveUsesInjectedActionWithValidatedDraft() {
        var capturedDraft: DebtDraft?
        let viewModel = DebtEditorViewModel(
            debt: nil,
            saveDebtAction: { _, draft, _ in
                capturedDraft = draft
            }
        )
        let context = ModelContext(PersistenceController.previewContainer())

        viewModel.counterpartyName = "  Bank  "
        viewModel.amountText = "150"
        viewModel.direction = .iOwe
        viewModel.status = .open
        viewModel.note = "  monthly  "

        let result = viewModel.save(locale: Locale(identifier: "en_US"), in: context)

        XCTAssertTrue(result)
        XCTAssertEqual(capturedDraft?.counterpartyName, "Bank")
        XCTAssertEqual(capturedDraft?.amountMinor, 15_000)
        XCTAssertEqual(capturedDraft?.note, "monthly")
    }

    func testDeleteStoresErrorMessageWhenInjectedActionFails() {
        let debt = DebtRecord(counterpartyName: "Bank", amountMinor: 10_000, direction: .iOwe)
        let viewModel = DebtEditorViewModel(
            debt: debt,
            deleteDebtAction: { _, _ in
                throw NSError(domain: "DebtEditorViewModelTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Delete debt failed"])
            }
        )
        let context = ModelContext(PersistenceController.previewContainer())

        let result = viewModel.delete(in: context)

        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "Delete debt failed")
    }
}

@MainActor
final class RecurringRuleEditorViewModelTests: XCTestCase {
    func testSaveUsesInjectedActionWithNormalizedDraft() {
        var capturedDraft: RecurringRuleDraft?
        let category = TransactionCategory(name: "Housing", emoji: "🏠", kind: .expense, sortOrder: 0)
        let person = PersonProfile(name: "Alex", emoji: "🙂")
        let viewModel = RecurringRuleEditorViewModel(
            rule: nil,
            saveRuleAction: { _, draft, _ in
                capturedDraft = draft
            }
        )
        let context = ModelContext(PersistenceController.previewContainer())
        let nextRunDate = ISO8601DateFormatter().date(from: "2026-04-22T16:30:00Z")!

        viewModel.title = "  Rent  "
        viewModel.amountText = "800"
        viewModel.kind = .expense
        viewModel.frequency = .monthly
        viewModel.nextRunDate = nextRunDate
        viewModel.note = "  fixed  "
        viewModel.selectedCategoryID = category.id
        viewModel.selectedPersonID = person.id

        let result = viewModel.save(
            categories: [category],
            people: [person],
            locale: Locale(identifier: "en_US"),
            in: context
        )

        XCTAssertTrue(result)
        XCTAssertEqual(capturedDraft?.title, "Rent")
        XCTAssertEqual(capturedDraft?.amountMinor, 80_000)
        XCTAssertEqual(Calendar.current.startOfDay(for: capturedDraft?.nextRunDate ?? .distantPast), capturedDraft?.nextRunDate)
        XCTAssertEqual(capturedDraft?.note, "fixed")
        XCTAssertEqual(capturedDraft?.category?.id, category.id)
        XCTAssertEqual(capturedDraft?.person?.id, person.id)
    }

    func testDeleteStoresErrorMessageWhenInjectedActionFails() {
        let rule = RecurringTransactionRule(title: "Rent", amountMinor: 80_000, nextRunDate: .now)
        let viewModel = RecurringRuleEditorViewModel(
            rule: rule,
            deleteRuleAction: { _, _ in
                throw NSError(domain: "RecurringRuleEditorViewModelTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Delete rule failed"])
            }
        )
        let context = ModelContext(PersistenceController.previewContainer())

        let result = viewModel.delete(in: context)

        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, "Delete rule failed")
    }
}

@MainActor
final class BudgetViewModelSafetyTests: XCTestCase {
    func testRequestDeleteDoesNotDeleteUntilConfirmed() {
        var deleted = false
        let rule = RecurringTransactionRule(title: "Rent", amountMinor: 80_000, nextRunDate: .now)
        let viewModel = BudgetViewModel { _, _ in
            deleted = true
        }

        viewModel.requestDelete(rule)

        XCTAssertFalse(deleted)
        XCTAssertEqual(viewModel.pendingDeletionRule?.id, rule.id)
    }

    func testConfirmDeleteUsesPendingRuleAndClearsState() {
        var deletedRuleID: UUID?
        let rule = RecurringTransactionRule(title: "Rent", amountMinor: 80_000, nextRunDate: .now)
        let viewModel = BudgetViewModel { pendingRule, _ in
            deletedRuleID = pendingRule.id
        }
        let context = ModelContext(PersistenceController.previewContainer())

        viewModel.requestDelete(rule)
        viewModel.confirmDelete(in: context)

        XCTAssertEqual(deletedRuleID, rule.id)
        XCTAssertNil(viewModel.pendingDeletionRule)
    }
}

@MainActor
final class PersonBudgetEditorViewModelTests: XCTestCase {
    func testSaveUsesInjectedActionsWithValidatedInput() {
        var didSavePerson = false
        var capturedBudgetTitle: String?
        var capturedAmountMinor: Int64?
        var capturedPeriod: BudgetPeriod?
        var capturedSalaryCycleStartDay: Int?

        let viewModel = PersonBudgetEditorViewModel(
            person: nil,
            upsertPersonAction: { name, emoji, _, _ in
                didSavePerson = true
                return PersonProfile(name: name, emoji: emoji)
            },
            upsertBudgetAction: { _, title, amountMinor, period, salaryCycleStartDay, _ in
                capturedBudgetTitle = title
                capturedAmountMinor = amountMinor
                capturedPeriod = period
                capturedSalaryCycleStartDay = salaryCycleStartDay
            }
        )
        let context = ModelContext(PersistenceController.previewContainer())

        viewModel.name = "  Sam  "
        viewModel.emoji = "🧑🏽"
        viewModel.amountText = "2500"
        viewModel.period = .salaryCycle
        viewModel.salaryCycleStartDay = 7

        let result = viewModel.save(locale: Locale(identifier: "en_US"), in: context)

        XCTAssertTrue(result)
        XCTAssertTrue(didSavePerson)
        XCTAssertEqual(capturedBudgetTitle, "Sam Budget")
        XCTAssertEqual(capturedAmountMinor, 250_000)
        XCTAssertEqual(capturedPeriod, .salaryCycle)
        XCTAssertEqual(capturedSalaryCycleStartDay, 7)
    }

    func testSaveRejectsEmptyName() {
        let viewModel = PersonBudgetEditorViewModel(person: nil)
        let context = ModelContext(PersistenceController.previewContainer())

        viewModel.name = "   "
        viewModel.amountText = "250"

        let result = viewModel.save(locale: Locale(identifier: "en_US"), in: context)

        XCTAssertFalse(result)
        XCTAssertEqual(viewModel.errorMessage, AppLocalizer.string("validation.name"))
    }
}

@MainActor
final class CategoryManagementViewModelTests: XCTestCase {
    func testRequestArchiveDoesNotArchiveUntilConfirmed() {
        var archived = false
        let item = CategoryItem(name: "Milk", emoji: "🥛")
        let viewModel = CategoryManagementViewModel(
            archiveItemAction: { _, _ in
                archived = true
            }
        )

        viewModel.requestArchive(item)

        XCTAssertFalse(archived)
        XCTAssertEqual(viewModel.pendingArchiveItem?.id, item.id)
    }

    func testSaveCategoryUsesInjectedActionAndResetsInputs() {
        var capturedName: String?
        var capturedEmoji: String?
        var capturedKind: CategoryKind?
        let viewModel = CategoryManagementViewModel(
            createCategoryAction: { name, emoji, kind, _ in
                capturedName = name
                capturedEmoji = emoji
                capturedKind = kind
            }
        )
        let context = ModelContext(PersistenceController.previewContainer())

        viewModel.categoryName = "Food"
        viewModel.categoryEmoji = "🍔"
        viewModel.categoryKind = .expense

        viewModel.saveCategory(in: context)

        XCTAssertEqual(capturedName, "Food")
        XCTAssertEqual(capturedEmoji, "🍔")
        XCTAssertEqual(capturedKind, .expense)
        XCTAssertEqual(viewModel.categoryName, "")
        XCTAssertEqual(viewModel.categoryEmoji, "🏷️")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testSaveItemUsesInjectedActionAndResetsItemDraft() {
        var capturedName: String?
        var capturedGroupName: String?
        var capturedEmoji: String?
        var capturedCategoryID: UUID?
        let category = TransactionCategory(name: "Bills", emoji: "💡", kind: .expense, sortOrder: 0)
        let viewModel = CategoryManagementViewModel(
            createItemAction: { name, groupName, emoji, selectedCategory, _ in
                capturedName = name
                capturedGroupName = groupName
                capturedEmoji = emoji
                capturedCategoryID = selectedCategory.id
            }
        )
        let context = ModelContext(PersistenceController.previewContainer())

        viewModel.itemCategoryID = category.id
        viewModel.itemName = "Electricity"
        viewModel.itemGroupName = "Utilities"
        viewModel.itemEmoji = "⚡️"

        viewModel.saveItem(from: [category], in: context)

        XCTAssertEqual(capturedName, "Electricity")
        XCTAssertEqual(capturedGroupName, "Utilities")
        XCTAssertEqual(capturedEmoji, "⚡️")
        XCTAssertEqual(capturedCategoryID, category.id)
        XCTAssertEqual(viewModel.itemName, "")
        XCTAssertEqual(viewModel.itemGroupName, "")
        XCTAssertEqual(viewModel.itemEmoji, "")
        XCTAssertNil(viewModel.errorMessage)
    }

    func testArchiveItemStoresErrorMessageWhenInjectedActionFails() {
        let viewModel = CategoryManagementViewModel(
            archiveItemAction: { _, _ in
                throw NSError(domain: "CategoryManagementViewModelTests", code: 1, userInfo: [NSLocalizedDescriptionKey: "Archive failed"])
            }
        )
        let context = ModelContext(PersistenceController.previewContainer())

        viewModel.archive(CategoryItem(name: "Milk", emoji: "🥛"), in: context)

        XCTAssertEqual(viewModel.errorMessage, "Archive failed")
    }

    func testConfirmArchiveUsesPendingItemAndClearsState() {
        var archivedItemID: UUID?
        let item = CategoryItem(name: "Milk", emoji: "🥛")
        let viewModel = CategoryManagementViewModel(
            archiveItemAction: { pendingItem, _ in
                archivedItemID = pendingItem.id
            }
        )
        let context = ModelContext(PersistenceController.previewContainer())

        viewModel.requestArchive(item)
        viewModel.confirmArchive(in: context)

        XCTAssertEqual(archivedItemID, item.id)
        XCTAssertNil(viewModel.pendingArchiveItem)
    }
}