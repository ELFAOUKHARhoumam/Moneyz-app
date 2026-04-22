import Foundation
import SwiftData

struct CategoryRepository {
    func createCategory(name: String, emoji: String, kind: CategoryKind, in context: ModelContext) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let categories = try context.fetch(FetchDescriptor<TransactionCategory>())
        let category = TransactionCategory(
            name: trimmedName,
            emoji: emoji.isEmpty ? "🏷️" : emoji,
            kind: kind,
            sortOrder: categories.count
        )
        context.insert(category)
        try context.save()
    }

    func createItem(
        name: String,
        groupName: String?,
        emoji: String,
        for category: TransactionCategory,
        in context: ModelContext
    ) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let item = CategoryItem(
            name: trimmedName,
            groupName: groupName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            emoji: emoji,
            sortOrder: category.items.count,
            category: category
        )
        context.insert(item)
        try context.save()
    }

    func archiveCategory(_ category: TransactionCategory, in context: ModelContext) throws {
        category.isArchived = true
        try context.save()
    }

    func archiveItem(_ item: CategoryItem, in context: ModelContext) throws {
        item.isArchived = true
        try context.save()
    }
}

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}
