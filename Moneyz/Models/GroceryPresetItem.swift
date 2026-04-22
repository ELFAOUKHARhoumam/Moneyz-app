import Foundation
import SwiftData

@Model
final class GroceryPresetItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var groupName: String
    var emoji: String
    var sortOrder: Int
    var lastUsedAt: Date?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        groupName: String,
        emoji: String = "🛒",
        sortOrder: Int = 0,
        lastUsedAt: Date? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.groupName = groupName
        self.emoji = emoji
        self.sortOrder = sortOrder
        self.lastUsedAt = lastUsedAt
        self.createdAt = createdAt
    }
}
