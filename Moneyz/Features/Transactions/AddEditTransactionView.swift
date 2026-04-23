import SwiftUI
import SwiftData

@MainActor
struct AddEditTransactionView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor<TransactionCategory>(\.sortOrder)])
    private var categories: [TransactionCategory]

    @Query(sort: [SortDescriptor<PersonProfile>(\.createdAt)])
    private var people: [PersonProfile]

    @StateObject private var viewModel: AddEditTransactionViewModel
    @State private var showingDeleteConfirmation = false

    init(transaction: MoneyTransaction?) {
        _viewModel = StateObject(wrappedValue: AddEditTransactionViewModel(transaction: transaction))
    }

    private var availableCategories: [TransactionCategory] {
        categories
            .filter { !$0.isArchived }
            .filter {
                switch $0.kind {
                case .both: return true
                case .expense: return viewModel.kind == .expense
                case .income: return viewModel.kind == .income
                }
            }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    private var selectedCategory: TransactionCategory? {
        availableCategories.first(where: { $0.id == viewModel.selectedCategoryID })
    }

    var body: some View {
        ZStack {
            PremiumTheme.PageBackground()
                .ignoresSafeArea()

            Form {
                Section {
                    TextField(AppLocalizer.string("transactions.amount.placeholder"), text: $viewModel.amountText)
                        .keyboardType(.decimalPad)

                    Picker(AppLocalizer.string("transactions.type"), selection: $viewModel.kind) {
                        ForEach(TransactionKind.allCases) { kind in
                            Text(AppLocalizer.string(kind.localizedKey)).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)

                    DatePicker(AppLocalizer.string("transactions.date"), selection: $viewModel.transactionDate, displayedComponents: .date)
                }

                Section(AppLocalizer.string("transactions.categorySection")) {
                    Picker(AppLocalizer.string("transactions.category"), selection: $viewModel.selectedCategoryID) {
                        Text(AppLocalizer.string("common.none")).tag(Optional<UUID>.none)
                        ForEach(availableCategories, id: \.id) { category in
                            Text("\(category.emoji) \(category.name)").tag(Optional(category.id))
                        }
                    }

                    if let selectedCategory {
                        Picker(AppLocalizer.string("transactions.item"), selection: $viewModel.selectedItemID) {
                            Text(AppLocalizer.string("common.none")).tag(Optional<UUID>.none)
                            ForEach(selectedCategory.items.filter { !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder }, id: \.id) { item in
                                Text([item.groupName, item.name].compactMap { $0 }.joined(separator: " • ")).tag(Optional(item.id))
                            }
                        }
                    }

                    TextField(AppLocalizer.string("transactions.customItem"), text: $viewModel.customItemName)
                }

                Section(AppLocalizer.string("transactions.personSection")) {
                    Picker(AppLocalizer.string("transactions.person"), selection: $viewModel.selectedPersonID) {
                        Text(AppLocalizer.string("common.none")).tag(Optional<UUID>.none)
                        ForEach(people.filter { !$0.isArchived }, id: \.id) { person in
                            Text("\(person.emoji) \(person.name)").tag(Optional(person.id))
                        }
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
                    if viewModel.save(categories: availableCategories, people: people.filter { !$0.isArchived }, locale: settings.locale, in: modelContext) {
                        dismiss()
                    }
                }
            }

            if viewModel.existingTransaction != nil {
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
                deleteTransaction()
            }
            Button(AppLocalizer.string("common.cancel"), role: .cancel) { }
        } message: {
            Text(AppLocalizer.string("common.deleteConfirmMessage"))
        }
        .onChange(of: viewModel.kind) { _, _ in
            if !availableCategories.contains(where: { $0.id == viewModel.selectedCategoryID }) {
                viewModel.selectedCategoryID = nil
                viewModel.selectedItemID = nil
            }
        }
        .onChange(of: viewModel.selectedCategoryID) { _, newValue in
            guard let selectedCategory, selectedCategory.id == newValue else {
                viewModel.selectedItemID = nil
                return
            }

            if !selectedCategory.items.contains(where: { $0.id == viewModel.selectedItemID }) {
                viewModel.selectedItemID = nil
            }
        }
    }

    private func deleteTransaction() {
        if viewModel.delete(in: modelContext) {
            dismiss()
        }
    }
}
