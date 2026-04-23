import Foundation
import Combine
import SwiftData

@MainActor
final class CategoryManagementViewModel: ObservableObject {
    typealias CreateCategoryAction = @MainActor (_ name: String, _ emoji: String, _ kind: CategoryKind, _ context: ModelContext) throws -> Void
    typealias CreateItemAction = @MainActor (_ name: String, _ groupName: String?, _ emoji: String, _ category: TransactionCategory, _ context: ModelContext) throws -> Void
    typealias ArchiveItemAction = @MainActor (_ item: CategoryItem, _ context: ModelContext) throws -> Void

    @Published var categoryName = ""
    @Published var categoryEmoji = "🏷️"
    @Published var categoryKind: CategoryKind = .expense

    @Published var itemName = ""
    @Published var itemGroupName = ""
    @Published var itemEmoji = ""
    @Published var itemCategoryID: UUID?
    @Published var pendingArchiveItem: CategoryItem?

    @Published var errorMessage: String?

    private let createCategoryAction: CreateCategoryAction
    private let createItemAction: CreateItemAction
    private let archiveItemAction: ArchiveItemAction

    init(
        createCategoryAction: CreateCategoryAction? = nil,
        createItemAction: CreateItemAction? = nil,
        archiveItemAction: ArchiveItemAction? = nil
    ) {
        self.createCategoryAction = createCategoryAction ?? { name, emoji, kind, context in
            try CategoryRepository().createCategory(name: name, emoji: emoji, kind: kind, in: context)
        }
        self.createItemAction = createItemAction ?? { name, groupName, emoji, category, context in
            try CategoryRepository().createItem(name: name, groupName: groupName, emoji: emoji, for: category, in: context)
        }
        self.archiveItemAction = archiveItemAction ?? { item, context in
            try CategoryRepository().archiveItem(item, in: context)
        }
    }

    var canSaveCategory: Bool {
        !categoryName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var canSaveItem: Bool {
        !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && itemCategoryID != nil
    }

    func activeCategories(from categories: [TransactionCategory]) -> [TransactionCategory] {
        categories
            .filter { !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func activeItems(in category: TransactionCategory) -> [CategoryItem] {
        category.items
            .filter { !$0.isArchived }
            .sorted { $0.sortOrder < $1.sortOrder }
    }

    func archive(_ item: CategoryItem, in context: ModelContext) {
        do {
            try archiveItemAction(item, context)
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func requestArchive(_ item: CategoryItem) {
        pendingArchiveItem = item
    }

    func confirmArchive(in context: ModelContext) {
        guard let item = pendingArchiveItem else { return }
        archive(item, in: context)
        pendingArchiveItem = nil
    }

    func cancelPendingArchive() {
        pendingArchiveItem = nil
    }

    func saveCategory(in context: ModelContext) {
        do {
            try createCategoryAction(categoryName, categoryEmoji, categoryKind, context)
            categoryName = ""
            categoryEmoji = "🏷️"
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveItem(from categories: [TransactionCategory], in context: ModelContext) {
        guard let itemCategoryID, let selectedCategory = categories.first(where: { $0.id == itemCategoryID }) else {
            return
        }

        do {
            try createItemAction(itemName, itemGroupName, itemEmoji, selectedCategory, context)
            itemName = ""
            itemGroupName = ""
            itemEmoji = ""
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}