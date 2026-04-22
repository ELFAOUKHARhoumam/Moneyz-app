import SwiftUI
import SwiftData

@MainActor
struct DebtEditorView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let existingDebt: DebtRecord?
    private let repository = DebtRepository()

    @State private var counterpartyName: String
    @State private var amountText: String
    @State private var direction: DebtDirection
    @State private var issueDate: Date
    @State private var includeDueDate: Bool
    @State private var dueDate: Date
    @State private var status: DebtStatus
    @State private var note: String
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false

    init(debt: DebtRecord?) {
        existingDebt = debt
        _counterpartyName = State(initialValue: debt?.counterpartyName ?? "")
        _amountText = State(initialValue: CurrencyFormatter.decimalString(from: debt?.amountMinor ?? 0))
        _direction = State(initialValue: debt?.direction ?? .owedToMe)
        _issueDate = State(initialValue: debt?.issueDate ?? .now)
        _includeDueDate = State(initialValue: debt?.dueDate != nil)
        _dueDate = State(initialValue: debt?.dueDate ?? .now)
        _status = State(initialValue: debt?.status ?? .open)
        _note = State(initialValue: debt?.note ?? "")
    }

    private var titleKey: String {
        existingDebt == nil ? "debt.add" : "debt.edit"
    }

    var body: some View {
        ZStack {
            PremiumTheme.PageBackground()
                .ignoresSafeArea()

            Form {
                Section(AppLocalizer.string("debt.details")) {
                    TextField(AppLocalizer.string("debt.counterparty"), text: $counterpartyName)

                    TextField(AppLocalizer.string("debt.amount"), text: $amountText)
                        .keyboardType(.decimalPad)

                    Picker(AppLocalizer.string("debt.direction"), selection: $direction) {
                        ForEach(DebtDirection.allCases) { option in
                            Text(AppLocalizer.string(option.localizedKey)).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker(AppLocalizer.string("debt.status"), selection: $status) {
                        ForEach(DebtStatus.allCases) { option in
                            Text(AppLocalizer.string(option.localizedKey)).tag(option)
                        }
                    }

                    DatePicker(AppLocalizer.string("debt.issueDate"), selection: $issueDate, displayedComponents: .date)
                    Toggle(AppLocalizer.string("debt.includeDueDate"), isOn: $includeDueDate)

                    if includeDueDate {
                        DatePicker(AppLocalizer.string("debt.dueDate"), selection: $dueDate, displayedComponents: .date)
                    }

                    TextField(AppLocalizer.string("transactions.note"), text: $note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(PremiumTheme.Palette.danger)
                            .font(.footnote)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(Text(AppLocalizer.string(titleKey)))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(AppLocalizer.string("common.cancel")) {
                    dismiss()
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Button(AppLocalizer.string("common.save")) {
                    save()
                }
            }

            if existingDebt != nil {
                ToolbarItem(placement: .bottomBar) {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Label(AppLocalizer.string("common.delete"), systemImage: "trash")
                    }
                }
            }
        }
        .confirmationDialog(
            AppLocalizer.string("common.deleteConfirmTitle"),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(AppLocalizer.string("common.delete"), role: .destructive) {
                deleteDebt()
            }

            Button(AppLocalizer.string("common.cancel"), role: .cancel) { }
        } message: {
            Text(AppLocalizer.string("common.deleteConfirmMessage"))
        }
    }

    private func save() {
        guard let amountMinor = CurrencyFormatter.minorUnits(from: amountText, locale: settings.locale), amountMinor > 0 else {
            errorMessage = AppLocalizer.string("validation.amount")
            return
        }

        let trimmedName = counterpartyName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = AppLocalizer.string("validation.name")
            return
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
            try repository.upsert(existing: existingDebt, draft: draft, in: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteDebt() {
        guard let existingDebt else { return }

        do {
            try repository.delete(existingDebt, in: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
