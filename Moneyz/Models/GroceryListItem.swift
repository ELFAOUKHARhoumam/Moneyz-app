import Foundation
import SwiftData

@Model
final class GroceryListItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var groupName: String
    var emoji: String
    var note: String
    var isChecked: Bool
    var sortOrder: Int
    var createdAt: Date

    var list: GroceryList?
    @Relationship(deleteRule: .nullify) var preset: GroceryPresetItem?

    init(
        id: UUID = UUID(),
        name: String,
        groupName: String = "Other",
        emoji: String = "🛒",
        note: String = "",
        isChecked: Bool = false,
        sortOrder: Int = 0,
        createdAt: Date = .now,
        list: GroceryList? = nil,
        preset: GroceryPresetItem? = nil
    ) {
        self.id = id
        self.name = name
        self.groupName = groupName
        self.emoji = emoji
        self.note = note
        self.isChecked = isChecked
        self.sortOrder = sortOrder
        self.createdAt = createdAt
        self.list = list
        self.preset = preset
    }
}
