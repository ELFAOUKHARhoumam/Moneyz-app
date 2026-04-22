import Foundation
import SwiftData

@Model
final class TransactionCategory {
    @Attribute(.unique) var id: UUID
    var name: String
    var emoji: String
    var kind: CategoryKind
    var sortOrder: Int
    var isArchived: Bool

    @Relationship(deleteRule: .cascade, inverse: \CategoryItem.category)
    var items: [CategoryItem]

    init(
        id: UUID = UUID(),
        name: String,
        emoji: String,
        kind: CategoryKind = .expense,
        sortOrder: Int = 0,
        isArchived: Bool = false,
        items: [CategoryItem] = []
    ) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.kind = kind
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.items = items
    }
}
