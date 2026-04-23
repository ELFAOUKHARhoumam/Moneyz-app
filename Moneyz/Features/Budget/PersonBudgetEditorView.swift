import SwiftUI
import SwiftData

@MainActor
struct PersonBudgetEditorView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject private var viewModel: PersonBudgetEditorViewModel

    init(person: PersonProfile?) {
        _viewModel = StateObject(wrappedValue: PersonBudgetEditorViewModel(person: person))
    }

    var body: some View {
        ZStack {
            PremiumTheme.PageBackground()
                .ignoresSafeArea()

            Form {
                Section(AppLocalizer.string("budget.person.details")) {
                    TextField(AppLocalizer.string("budget.person.name"), text: $viewModel.name)
                    TextField(AppLocalizer.string("budget.person.emoji"), text: $viewModel.emoji)
                }

                Section(AppLocalizer.string("budget.plan.details")) {
                    TextField(AppLocalizer.string("budget.plan.amount"), text: $viewModel.amountText)
                        .keyboardType(.decimalPad)

                    Picker(AppLocalizer.string("budget.plan.period"), selection: $viewModel.period) {
                        ForEach(BudgetPeriod.allCases) { option in
                            Text(AppLocalizer.string(option.localizedKey)).tag(option)
                        }
                    }

                    if viewModel.period == .salaryCycle {
                        Stepper(value: $viewModel.salaryCycleStartDay, in: 1...28) {
                            Text("\(AppLocalizer.string("budget.plan.salaryCycleStart")) \(viewModel.salaryCycleStartDay)")
                        }
                    }
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
        }
    }
}
