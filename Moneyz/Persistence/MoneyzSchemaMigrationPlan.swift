import Foundation
import SwiftData

enum MoneyzSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [
            TransactionCategory.self,
            CategoryItem.self,
            PersonProfile.self,
            PersonBudgetPlan.self,
            MoneyTransaction.self,
            DebtRecord.self,
            RecurringTransactionRule.self,
            GroceryList.self,
            GroceryListItem.self,
            GroceryPresetItem.self
        ]
    }
}

enum MoneyzSchemaMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [MoneyzSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
