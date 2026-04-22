import SwiftUI
import SwiftData

@MainActor
struct CategoryManagementView: View {
    init() {}

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query(sort: [SortDescriptor<TransactionCategory>(\.sortOrder)])
    private var categories: [TransactionCategory]

    @State private var categoryName = ""
    @State private var categoryEmoji = "🏷️"
    @State private var categoryKind: CategoryKind = .expense

    @State private var itemName = ""
    @State private var itemGroupName = ""
    @State private var itemEmoji = ""
    @State private var itemCategoryID: UUID?

    private let repository = CategoryRepository()

    var body: some View {
        Form {
            ForEach(categories.filter { !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder }, id: \.id) { category in
                Section("\(category.emoji) \(category.name)") {
                    if category.items.filter({ !$0.isArchived }).isEmpty {
                        Text("categories.empty.items")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(category.items.filter { !$0.isArchived }.sorted { $0.sortOrder < $1.sortOrder }, id: \.id) { item in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(item.emoji.isEmpty ? category.emoji : item.emoji) \(item.name)")
                                if let groupName = item.groupName, !groupName.isEmpty {
                                    Text(groupName)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .swipeActions {
                                Button(role: .destructive) {
                                    try? repository.archiveItem(item, in: modelContext)
                                } label: {
                                    Label("common.archive", systemImage: "archivebox")
                                }
                            }
                        }
                    }
                }
            }

            Section("categories.addCategory") {
                TextField("categories.name", text: $categoryName)
                TextField("categories.emoji", text: $categoryEmoji)
                Picker("categories.kind", selection: $categoryKind) {
                    ForEach(CategoryKind.allCases, id: \.id) { kind in
                        Text(AppLocalizer.string(kind.localizedKey)).tag(kind)
                    }
                }
                Button("common.save") {
                    try? repository.createCategory(name: categoryName, emoji: categoryEmoji, kind: categoryKind, in: modelContext)
                    categoryName = ""
                    categoryEmoji = "🏷️"
                }
                .disabled(categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }

            Section("categories.addItem") {
                Picker("transactions.category", selection: $itemCategoryID) {
                    Text("common.none").tag(Optional<UUID>.none)
                    ForEach(categories.filter { !$0.isArchived }, id: \.id) { category in
                        Text("\(category.emoji) \(category.name)").tag(Optional(category.id))
                    }
                }
                TextField("categories.group", text: $itemGroupName)
                TextField("categories.name", text: $itemName)
                TextField("categories.emoji", text: $itemEmoji)
                Button("common.save") {
                    guard let selected = categories.first(where: { $0.id == itemCategoryID }) else { return }
                    try? repository.createItem(name: itemName, groupName: itemGroupName, emoji: itemEmoji, for: selected, in: modelContext)
                    itemName = ""
                    itemGroupName = ""
                    itemEmoji = ""
                }
                .disabled(itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || itemCategoryID == nil)
            }
        }
        .navigationTitle(Text("categories.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("common.done") {
                    dismiss()
                }
            }
        }
    }
}
