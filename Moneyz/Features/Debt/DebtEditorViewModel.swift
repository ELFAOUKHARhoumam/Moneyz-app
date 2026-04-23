import Foundation
import Combine
import SwiftData

@MainActor
final class DebtEditorViewModel: ObservableObject {
    typealias SaveDebtAction = @MainActor (_ existingDebt: DebtRecord?, _ draft: DebtDraft, _ context: ModelContext) throws -> Void
    typealias DeleteDebtAction = @MainActor (_ debt: DebtRecord, _ context: ModelContext) throws -> Void

    @Published var counterpartyName: String
    @Published var amountText: String
    @Published var direction: DebtDirection
    @Published var issueDate: Date
    @Published var includeDueDate: Bool
    @Published var dueDate: Date
    @Published var status: DebtStatus
    @Published var note: String
    @Published var errorMessage: String?

    let existingDebt: DebtRecord?

    private let saveDebtAction: SaveDebtAction
    private let deleteDebtAction: DeleteDebtAction

    init(
        debt: DebtRecord?,
        saveDebtAction: SaveDebtAction? = nil,
        deleteDebtAction: DeleteDebtAction? = nil
    ) {
        existingDebt = debt
        counterpartyName = debt?.counterpartyName ?? ""
        amountText = CurrencyFormatter.decimalString(from: debt?.amountMinor ?? 0)
        direction = debt?.direction ?? .owedToMe
        issueDate = debt?.issueDate ?? .now
        includeDueDate = debt?.dueDate != nil
        dueDate = debt?.dueDate ?? .now
        status = debt?.status ?? .open
        note = debt?.note ?? ""
        self.saveDebtAction = saveDebtAction ?? { existingDebt, draft, context in
            try DebtRepository().upsert(existing: existingDebt, draft: draft, in: context)
        }
        self.deleteDebtAction = deleteDebtAction ?? { debt, context in
            try DebtRepository().delete(debt, in: context)
        }
    }

    var titleKey: String {
        existingDebt == nil ? "debt.add" : "debt.edit"
    }

    func save(locale: Locale, in context: ModelContext) -> Bool {
        guard let amountMinor = CurrencyFormatter.minorUnits(from: amountText, locale: locale), amountMinor > 0 else {
            errorMessage = AppLocalizer.string("validation.amount")
            return false
        }

        let trimmedName = counterpartyName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = AppLocalizer.string("validation.name")
            return false
        }

        let draft = DebtDraft(
            counterpartyName: trimmedName,
            amountMinor: amountMinor,
            direction: direction,
            issueDate: issueDate,
            dueDate: includeDueDate ? dueDate : nil,
            status: status,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        do {
            try saveDebtAction(existingDebt, draft, context)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    func delete(in context: ModelContext) -> Bool {
        guard let existingDebt else { return false }

        do {
            try deleteDebtAction(existingDebt, context)
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}