import SwiftUI
import SwiftData

@MainActor
struct CategoryManagementView: View {
    init(viewModel: CategoryManagementViewModel? = nil) {
        _viewModel = StateObject(wrappedValue: viewModel ?? CategoryManagementViewModel())
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor<TransactionCategory>(\.sortOrder)])
    private var categories: [TransactionCategory]

    @StateObject private var viewModel: CategoryManagementViewModel

    private var activeCategories: [TransactionCategory] {
        viewModel.activeCategories(from: categories)
    }

    var body: some View {
        Form {
            ForEach(activeCategories, id: \.id) { category in
                CategoryItemSection(
                    category: category,
                    items: viewModel.activeItems(in: category),
                    archiveAction: { item in
                        viewModel.requestArchive(item)
                    }
                )
            }

            AddCategorySection(
                viewModel: viewModel,
                saveAction: {
                    viewModel.saveCategory(in: modelContext)
                }
            )

            AddCategoryItemSection(
                viewModel: viewModel,
                categories: activeCategories,
                saveAction: {
                    viewModel.saveItem(from: activeCategories, in: modelContext)
                }
            )

            if let errorMessage = viewModel.errorMessage {
                Section {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(PremiumTheme.Palette.danger)
                }
            }
        }
        .navigationTitle(Text(AppLocalizer.string("categories.title")))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(AppLocalizer.string("common.done")) {
                    dismiss()
                }
            }
        }
        .confirmationDialog(
            AppLocalizer.string("common.archiveConfirmTitle"),
            isPresented: Binding(
                get: { viewModel.pendingArchiveItem != nil },
                set: { if !$0 { viewModel.cancelPendingArchive() } }
            ),
            titleVisibility: .visible
        ) {
            Button(AppLocalizer.string("common.archive"), role: .destructive) {
                viewModel.confirmArchive(in: modelContext)
            }
            Button(AppLocalizer.string("common.cancel"), role: .cancel) {
                viewModel.cancelPendingArchive()
            }
        } message: {
            Text(AppLocalizer.string("common.archiveConfirmMessage"))
        }
    }
}

@MainActor
private struct CategoryItemSection: View {
    let category: TransactionCategory
    let items: [CategoryItem]
    let archiveAction: (CategoryItem) -> Void

    var body: some View {
        Section("\(category.emoji) \(category.name)") {
            if items.isEmpty {
                Text(AppLocalizer.string("categories.empty.items"))
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items, id: \.id) { item in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(item.emoji.isEmpty ? category.emoji : item.emoji) \(item.name)")
                        if let groupName = item.groupName, !groupName.isEmpty {
                            Text(groupName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            archiveAction(item)
                        } label: {
                            Label(AppLocalizer.string("common.archive"), systemImage: "archivebox")
                        }
                    }
                }
            }
        }
    }
}

@MainActor
private struct AddCategorySection: View {
    @ObservedObject var viewModel: CategoryManagementViewModel
    let saveAction: () -> Void

    var body: some View {
        Section(AppLocalizer.string("categories.addCategory")) {
            TextField(AppLocalizer.string("categories.name"), text: $viewModel.categoryName)
            TextField(AppLocalizer.string("categories.emoji"), text: $viewModel.categoryEmoji)
            Picker(AppLocalizer.string("categories.kind"), selection: $viewModel.categoryKind) {
                ForEach(CategoryKind.allCases, id: \.id) { kind in
                    Text(AppLocalizer.string(kind.localizedKey)).tag(kind)
                }
            }
            Button(AppLocalizer.string("common.save")) {
                saveAction()
            }
            .disabled(!viewModel.canSaveCategory)
        }
    }
}

@MainActor
private struct AddCategoryItemSection: View {
    @ObservedObject var viewModel: CategoryManagementViewModel
    let categories: [TransactionCategory]
    let saveAction: () -> Void

    var body: some View {
        Section(AppLocalizer.string("categories.addItem")) {
            Picker(AppLocalizer.string("transactions.category"), selection: $viewModel.itemCategoryID) {
                Text(AppLocalizer.string("common.none")).tag(Optional<UUID>.none)
                ForEach(categories, id: \.id) { category in
                    Text("\(category.emoji) \(category.name)").tag(Optional(category.id))
                }
            }
            TextField(AppLocalizer.string("categories.group"), text: $viewModel.itemGroupName)
            TextField(AppLocalizer.string("categories.name"), text: $viewModel.itemName)
            TextField(AppLocalizer.string("categories.emoji"), text: $viewModel.itemEmoji)
            Button(AppLocalizer.string("common.save")) {
                saveAction()
            }
            .disabled(!viewModel.canSaveItem)
        }
    }
}
