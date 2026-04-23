import SwiftUI
import SwiftData

@MainActor
struct DebtEditorView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel: DebtEditorViewModel
    @State private var showingDeleteConfirmation = false

    init(debt: DebtRecord?) {
        _viewModel = StateObject(wrappedValue: DebtEditorViewModel(debt: debt))
    }

    var body: some View {
        ZStack {
            PremiumTheme.PageBackground()
                .ignoresSafeArea()

            Form {
                Section(AppLocalizer.string("debt.details")) {
                    TextField(AppLocalizer.string("debt.counterparty"), text: $viewModel.counterpartyName)

                    TextField(AppLocalizer.string("debt.amount"), text: $viewModel.amountText)
                        .keyboardType(.decimalPad)

                    Picker(AppLocalizer.string("debt.direction"), selection: $viewModel.direction) {
                        ForEach(DebtDirection.allCases) { option in
                            Text(AppLocalizer.string(option.localizedKey)).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker(AppLocalizer.string("debt.status"), selection: $viewModel.status) {
                        ForEach(DebtStatus.allCases) { option in
                            Text(AppLocalizer.string(option.localizedKey)).tag(option)
                        }
                    }

                    DatePicker(AppLocalizer.string("debt.issueDate"), selection: $viewModel.issueDate, displayedComponents: .date)
                    Toggle(AppLocalizer.string("debt.includeDueDate"), isOn: $viewModel.includeDueDate)

                    if viewModel.includeDueDate {
                        DatePicker(AppLocalizer.string("debt.dueDate"), selection: $viewModel.dueDate, displayedComponents: .date)
                    }

                    TextField(AppLocalizer.string("transactions.note"), text: $viewModel.note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                if let errorMessage = viewModel.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(PremiumTheme.Palette.danger)
                            .font(.footnote)
                    }
                }
            }
            .scrollContentBackground(.hidden)
        }
        .navigationTitle(Text(AppLocalizer.string(viewModel.titleKey)))
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
                    if viewModel.save(locale: settings.locale, in: modelContext) {
                        dismiss()
                    }
                }
            }

            if viewModel.existingDebt != nil {
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
                if viewModel.delete(in: modelContext) {
                    dismiss()
                }
            }

            Button(AppLocalizer.string("common.cancel"), role: .cancel) { }
        } message: {
            Text(AppLocalizer.string("common.deleteConfirmMessage"))
        }
    }
}
