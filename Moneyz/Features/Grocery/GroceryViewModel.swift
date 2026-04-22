import Foundation
import SwiftData
import Combine

@MainActor
final class GroceryViewModel: ObservableObject {
    @Published var currentListID: UUID?
    @Published var itemName = ""
    @Published var groupName = "Other"
    @Published var emoji = "🛒"
    @Published var saveAsPreset = true
    @Published var presetName = ""
    @Published var presetGroupName = "Other"
    @Published var presetEmoji = "🛒"
    @Published var errorMessage: String?

    private let repository = GroceryRepository()

    func ensureActiveList(from lists: [GroceryList], in context: ModelContext) {
        if let active = lists.first(where: { !$0.isArchived }) {
            currentListID = active.id
            return
        }

        do {
            let list = try repository.ensureActiveList(in: context)
            currentListID = list.id
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func currentList(from lists: [GroceryList]) -> GroceryList? {
        if let currentListID {
            return lists.first(where: { $0.id == currentListID })
        }
        return lists.first(where: { !$0.isArchived })
    }

    func groupedItems(for list: GroceryList) -> [(group: String, items: [GroceryListItem])] {
        let grouped = Dictionary(grouping: list.items.sorted { lhs, rhs in
            if lhs.groupName == rhs.groupName {
                return lhs.sortOrder < rhs.sortOrder
            }
            return lhs.groupName.localizedCaseInsensitiveCompare(rhs.groupName) == .orderedAscending
        }) { $0.groupName }

        return grouped
            .map { key, value in
                (group: key, items: value.sorted { $0.sortOrder < $1.sortOrder })
            }
            .sorted { $0.group.localizedCaseInsensitiveCompare($1.group) == .orderedAscending }
    }

    func quickAdd(preset: GroceryPresetItem, to list: GroceryList, in context: ModelContext) {
        do {
            try repository.addItem(
                name: preset.name,
                groupName: preset.groupName,
                emoji: preset.emoji,
                to: list,
                preset: preset,
                in: context
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addCustomItem(to list: GroceryList, in context: ModelContext) {
        let trimmedName = itemName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = AppLocalizer.string("validation.name")
            return
        }

        do {
            try repository.addItem(
                name: trimmedName,
                groupName: groupName,
                emoji: emoji,
                to: list,
                preset: nil,
                in: context
            )

            if saveAsPreset {
                try repository.addPreset(name: trimmedName, groupName: groupName, emoji: emoji, in: context)
            }

            itemName = ""
            groupName = "Other"
            emoji = "🛒"
            saveAsPreset = true
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func toggle(_ item: GroceryListItem, in context: ModelContext) {
        do {
            try repository.toggle(item, in: context)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startNewList(from currentList: GroceryList, in context: ModelContext) {
        do {
            let newList = try repository.startNewList(from: currentList, in: context)
            currentListID = newList.id
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addPreset(in context: ModelContext) {
        let trimmedName = presetName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            errorMessage = AppLocalizer.string("validation.name")
            return
        }

        do {
            try repository.addPreset(name: trimmedName, groupName: presetGroupName, emoji: presetEmoji, in: context)
            presetName = ""
            presetGroupName = "Other"
            presetEmoji = "🛒"
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
