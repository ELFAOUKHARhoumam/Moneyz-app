import Foundation
import SwiftData

@Model
final class GroceryList {
    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \GroceryListItem.list)
    var items: [GroceryListItem]

    init(
        id: UUID = UUID(),
        title: String = "Weekly Grocery",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isArchived: Bool = false,
        items: [GroceryListItem] = []
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isArchived = isArchived
        self.items = items
    }
}
