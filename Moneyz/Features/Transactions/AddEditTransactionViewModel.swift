import Foundation
import SwiftData
import Combine

@MainActor
final class AddEditTransactionViewModel: ObservableObject {
    @Published var amountText: String
    @Published var kind: TransactionKind
    @Published var transactionDate: Date
    @Published var customItemName: String
    @Published var note: String
    @Published var selectedCategoryID: UUID?
    @Published var selectedItemID: UUID?
    @Published var selectedPersonID: UUID?
    @Published var errorMessage: String?

    let existingTransaction: MoneyTransaction?
    private let repository = TransactionRepository()
    private let deleteTransactionAction: @MainActor (MoneyTransaction, ModelContext) throws -> Void

    init(
        transaction: MoneyTransaction?,
        deleteTransactionAction: (@MainActor (MoneyTransaction, ModelContext) throws -> Void)? = nil
    ) {
        existingTransaction = transaction
        amountText = CurrencyFormatter.decimalString(from: transaction?.amountMinor ?? 0)
        kind = transaction?.kind ?? .expense
        transactionDate = transaction?.transactionDate ?? .now
        customItemName = transaction?.customItemName ?? ""
        note = transaction?.note ?? ""
        selectedCategoryID = transaction?.category?.id
        selectedItemID = transaction?.item?.id
        selectedPersonID = transaction?.person?.id
        self.deleteTransactionAction = deleteTransactionAction ?? { existingTransaction, context in
            try TransactionRepository().delete(existingTransaction, in: context)
        }
    }

    var titleKey: String {
        existingTransaction == nil ? "transactions.add" : "transactions.edit"
    }

    func save(
        categories: [TransactionCategory],
        people: [PersonProfile],
        locale: Locale,
        in context: ModelContext
    ) -> Bool {
        guard let amountMinor = CurrencyFormatter.minorUnits(from: amountText, locale: locale), amountMinor > 0 else {
            errorMessage = AppLocalizer.string("validation.amount")
            return false
        }

        let selectedCategory = categories.first(where: { $0.id == selectedCategoryID })
        let selectedItem = selectedCategory?.items.first(where: { $0.id == selectedItemID })
        let selectedPerson = people.first(where: { $0.id == selectedPersonID })

        let draft = TransactionDraft(
            amountMinor: amountMinor,
            kind: kind,
            transactionDate: transactionDate,
            customItemName: customItemName.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            category: selectedCategory,
            item: selectedItem,
            person: selectedPerson
        )

        do {
            try repository.upsert(existing: existingTransaction, draft: draft, in: context)
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete(in context: ModelContext) -> Bool {
        guard let existingTransaction else { return false }

        do {
            try deleteTransactionAction(existingTransaction, context)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
