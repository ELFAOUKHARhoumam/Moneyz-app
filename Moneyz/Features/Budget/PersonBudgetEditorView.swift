import SwiftUI
import SwiftData

@MainActor
struct PersonBudgetEditorView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    private let existingPerson: PersonProfile?
    private let repository = BudgetRepository()

    @State private var name: String
    @State private var emoji: String
    @State private var amountText: String
    @State private var period: BudgetPeriod
    @State private var salaryCycleStartDay: Int
    @State private var errorMessage: String?

    init(person: PersonProfile?) {
        existingPerson = person
        _name = State(initialValue: person?.name ?? "")
        _emoji = State(initialValue: person?.emoji ?? "🙂")
        _amountText = State(initialValue: CurrencyFormatter.decimalString(from: person?.activeBudget?.amountMinor ?? 0))
        _period = State(initialValue: person?.activeBudget?.period ?? .month)
        _salaryCycleStartDay = State(initialValue: person?.activeBudget?.salaryCycleStartDay ?? 1)
    }

    private var titleKey: String {
        existingPerson == nil ? "budget.person.add" : "budget.person.edit"
    }

    var body: some View {
        ZStack {
            PremiumTheme.PageBackground()
                .ignoresSafeArea()

            Form {
                Section(AppLocalizer.string("budget.person.details")) {
                    TextField(AppLocalizer.string("budget.person.name"), text: $name)
                    TextField(AppLocalizer.string("budget.person.emoji"), text: $emoji)
                }

                Section(AppLocalizer.string("budget.plan.details")) {
                    TextField(AppLocalizer.string("budget.plan.amount"), text: $amountText)
                        .keyboardType(.decimalPad)

                    Picker(AppLocalizer.string("budget.plan.period"), selection: $period) {
                        ForEach(BudgetPeriod.allCases) { option in
                            Text(AppLocalizer.string(option.localizedKey)).tag(option)
                        }
                    }

                    if period == .salaryCycle {
                        Stepper(value: $salaryCycleStartDay, in: 1...28) {
                            Text("\(AppLocalizer.string("budget.plan.salaryCycleStart")) \(salaryCycleStartDay)")
                        }
                    }
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
        }
    }

    private func save() {
        guard let amountMinor = CurrencyFormatter.minorUnits(from: amountText, locale: settings.locale), amountMinor >= 0 else {
            errorMessage = AppLocalizer.string("validation.amount")
            return
        }

        do {
            let person = try repository.upsertPerson(name: name, emoji: emoji, existing: existingPerson, in: modelContext)
            try repository.upsertBudget(
                for: person,
                title: "\(person.name) \(AppLocalizer.string("budget.plan.defaultTitle"))",
                amountMinor: amountMinor,
                period: period,
                salaryCycleStartDay: salaryCycleStartDay,
                in: modelContext
            )
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
