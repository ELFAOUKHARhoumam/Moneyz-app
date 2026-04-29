import Foundation
import SwiftData

struct GroceryRepository {
    func ensureActiveList(in context: ModelContext) throws -> GroceryList {
        let descriptor = FetchDescriptor<GroceryList>(sortBy: [SortDescriptor<GroceryList>(\.updatedAt, order: .reverse)])
        if let list = try context.fetch(descriptor).first(where: { !$0.isArchived }) {
            return list
        }

        let list = GroceryList(
            title: AppLocalizer.string("grocery.list.thisWeek", fallback: "This Week")
        )
        context.insert(list)
        try context.save()
        return list
    }

    func addItem(
        name: String,
        groupName: String,
        emoji: String,
        to list: GroceryList,
        preset: GroceryPresetItem?,
        in context: ModelContext
    ) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let item = GroceryListItem(
            name: trimmedName,
            groupName: groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? AppLocalizer.string("grocery.group.other", fallback: "Other")
                : groupName,
            emoji: emoji.isEmpty ? "🛒" : emoji,
            sortOrder: list.items.count,
            list: list,
            preset: preset
        )
        list.updatedAt = .now
        preset?.lastUsedAt = .now
        context.insert(item)
        try context.save()
    }

    func toggle(_ item: GroceryListItem, in context: ModelContext) throws {
        item.isChecked.toggle()
        item.list?.updatedAt = .now
        try context.save()
    }

    func startNewList(from currentList: GroceryList, in context: ModelContext) throws -> GroceryList {
        currentList.isArchived = true
        currentList.updatedAt = .now

        let list = GroceryList(
            title: AppLocalizer.string("grocery.list.nextWeek", fallback: "Next Week")
        )
        context.insert(list)
        try context.save()
        return list
    }

    func addPreset(name: String, groupName: String, emoji: String, in context: ModelContext) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { return }

        let normalizedGroupName = groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ? AppLocalizer.string("grocery.group.other", fallback: "Other")
                : groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedEmoji = emoji.isEmpty ? "🛒" : emoji

        if let existing = try fetchPreset(named: trimmedName, in: context) {
            existing.groupName = normalizedGroupName
            existing.emoji = normalizedEmoji
            existing.lastUsedAt = .now
            try context.save()
            return
        }

        let preset = GroceryPresetItem(
            name: trimmedName,
            groupName: normalizedGroupName,
            emoji: normalizedEmoji
        )
        context.insert(preset)
        try context.save()
    }

    func deleteItem(_ item: GroceryListItem, in context: ModelContext) throws {
        item.list?.updatedAt = .now
        context.delete(item)
        try context.save()
    }

    func deletePreset(_ preset: GroceryPresetItem, in context: ModelContext) throws {
        context.delete(preset)
        try context.save()
    }

    private func fetchPreset(named name: String, in context: ModelContext) throws -> GroceryPresetItem? {
        let presets = try context.fetch(FetchDescriptor<GroceryPresetItem>())
        return presets.first { preset in
            preset.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(name) == .orderedSame
        }
    }
}
