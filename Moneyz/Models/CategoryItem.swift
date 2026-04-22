import Foundation
import SwiftData

@Model
final class CategoryItem {
    @Attribute(.unique) var id: UUID
    var name: String
    var groupName: String?
    var emoji: String
    var sortOrder: Int
    var isArchived: Bool

    var category: TransactionCategory?

    init(
        id: UUID = UUID(),
        name: String,
        groupName: String? = nil,
        emoji: String = "",
        sortOrder: Int = 0,
        isArchived: Bool = false,
        category: TransactionCategory? = nil
    ) {
        self.id = id
        self.name = name
        self.groupName = groupName
        self.emoji = emoji
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.category = category
    }
}
