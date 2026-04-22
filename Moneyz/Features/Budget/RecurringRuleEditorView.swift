import SwiftUI
import SwiftData

@MainActor
struct RecurringRuleEditorView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor<TransactionCategory>(\.sortOrder)])
    private var categories: [TransactionCategory]

    @Query(sort: [SortDescriptor<PersonProfile>(\.createdAt)])
    private var people: [PersonProfile]

    private let existingRule: RecurringTransactionRule?
    private let repository = RecurringRuleRepository()

    @State private var title: String
    @State private var amountText: String
    @State private var kind: TransactionKind
    @State private var frequency: RecurringFrequency
    @State private var nextRunDate: Date
    @State private var note: String
    @State private var selectedCategoryID: UUID?
    @State private var selectedItemID: UUID?
    @State private var selectedPersonID: UUID?
    @State private var errorMessage: String?
    @State private var showingDeleteConfirmation = false

    init(rule: RecurringTransactionRule?) {
        existingRule = rule
        _title = State(initialValue: rule?.title ?? "")
        _amountText = State(initialValue: CurrencyFormatter.decimalString(from: rule?.amountMinor ?? 0))
        _kind = State(initialValue: rule?.kind ?? .expense)
        _frequency = State(initialValue: rule?.frequency ?? .monthly)
        _nextRunDate = State(initialValue: rule?.nextRunDate ?? .now)
        _note = State(initialValue: rule?.note ?? "")
        _selectedCategoryID = State(initialValue: rule?.category?.id)
        _selectedItemID = State(initialValue: rule?.item?.id)
        _selectedPersonID = State(initialValue: rule?.person?.id)
    }

    private var titleKey: String {
        existingRule == nil ? "budget.fixed.add" : "budget.fixed.edit"
    }

    private var availableCategories: [TransactionCategory] {
        categories
            .filter { !$0.isArchived }
            .filter {
                switch $0.kind {
                case .both: return true
                case .expense: return kind == .expense
                case .income: return kind == .income
                }
            }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var selectedCategory: TransactionCategory? {
        availableCategories.first(where: { $0.id == selectedCategoryID })
    }

    var body: some View {
        ZStack {
            PremiumTheme.PageBackground()
                .ignoresSafeArea()

            Form {
                Section(AppLocalizer.string("budget.fixed.details")) {
                    TextField(AppLocalizer.string("budget.fixed.title"), text: $title)
                    TextField(AppLocalizer.string("budget.fixed.amount"), text: $amountText)
                        .keyboardType(.decimalPad)

                    Picker(AppLocalizer.string("transactions.type"), selection: $kind) {
                        ForEach(TransactionKind.allCases) { option in
                            Text(AppLocalizer.string(option.localizedKey)).tag(option)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker(AppLocalizer.string("budget.fixed.frequency"), selection: $frequency) {
                        ForEach(RecurringFrequency.allCases) { option in
                            Text(AppLocalizer.string(option.localizedKey)).tag(option)
                        }
                    }

                    DatePicker(AppLocalizer.string("budget.fixed.nextDate"), selection: $nextRunDate, displayedComponents: .date)

                    TextField(AppLocalizer.string("transactions.note"), text: $note, axis: .vertical)
                        .lineLimit(3, reservesSpace: true)
                }

                Section(AppLocalizer.string("transactions.categorySection")) {
                    Picker(AppLocalizer.string("transactions.category"), selection: $selectedCategoryID) {
                        Text(AppLocalizer.string("common.none")).tag(Optional<UUID>.none)
                        ForEach(availableCategories, id: \.id) { category in
                            Text("\(category.emoji) \(category.name)").tag(Optional(category.id))
                        }
                    }

                    if let selectedCategory {
                        Picker(AppLocalizer.string("transactions.item"), selection: $selectedItemID) {
                            Text(AppLocalizer.string("common.none")).tag(Optional<UUID>.none)
                            ForEach(selectedCategory.items.filter { !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder }, id: \.id) { item in
                                Text([item.groupName, item.name].compactMap { $0 }.joined(separator: " • ")).tag(Optional(item.id))
                            }
                        }
                    }

                    Picker(AppLocalizer.string("transactions.person"), selection: $selectedPersonID) {
                        Text(AppLocalizer.string("common.none")).tag(Optional<UUID>.none)
                        ForEach(people.filter { !$0.isArchived }, id: \.id) { person in
                            Text("\(person.emoji) \(person.name)").tag(Optional(person.id))
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

            if existingRule != nil {
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
                deleteRule()
            }

            Button(AppLocalizer.string("common.cancel"), role: .cancel) { }
        } message: {
            Text(AppLocalizer.string("common.deleteConfirmMessage"))
        }
        .onChange(of: kind) { _, _ in
            if !availableCategories.contains(where: { $0.id == selectedCategoryID }) {
                selectedCategoryID = nil
                selectedItemID = nil
            }
        }
        .onChange(of: selectedCategoryID) { _, newValue in
            guard let selectedCategory, selectedCategory.id == newValue else {
                selectedItemID = nil
                return
            }

            if !selectedCategory.items.contains(where: { $0.id == selectedItemID }) {
                selectedItemID = nil
            }
        }
    }

    private func save() {
        guard let amountMinor = CurrencyFormatter.minorUnits(from: amountText, locale: settings.locale), amountMinor > 0 else {
            errorMessage = AppLocalizer.string("validation.amount")
            return
        }

        let selectedCategory = availableCategories.first(where: { $0.id == selectedCategoryID })
        let selectedItem = selectedCategory?.items.first(where: { $0.id == selectedItemID })
        let selectedPerson = people.first(where: { $0.id == selectedPersonID })

        let draft = RecurringRuleDraft(
            title: title,
            amountMinor: amountMinor,
            kind: kind,
            frequency: frequency,
            nextRunDate: Calendar.current.startOfDay(for: nextRunDate),
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            category: selectedCategory,
            item: selectedItem,
            person: selectedPerson
        )

        do {
            try repository.upsert(existing: existingRule, draft: draft, in: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func deleteRule() {
        guard let existingRule else { return }

        do {
            try repository.delete(existingRule, in: modelContext)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
