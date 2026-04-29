import Foundation
import SwiftData

// MARK: - MoneyTransaction display helpers (View layer)
//
// Gap 3 fix: MoneyTransaction.displayTitle previously called AppLocalizer.string() directly
// inside the @Model class. Models should be pure data — they must not depend on the
// localisation layer because:
//   1. @Model objects can be accessed from background contexts where AppLocalizer's
//      UserDefaults read (currentLanguageCode) is not guaranteed to be correct.
//   2. It creates an untestable coupling: unit tests that create MoneyTransaction objects
//      would implicitly pull in localisation infrastructure.
//   3. SwiftData generates code around @Model properties; adding side-effecting computed
//      properties increases the risk of unexpected behaviour during model graph traversal.
//
// Fix: keep the model pure. Move display-level helpers into this separate extension file
// which lives in the UI/Utilities layer (not in Models/). Views call these helpers;
// the model itself has no knowledge of strings or localisation.
//
// IMPORTANT: remove `var displayTitle: String` from MoneyTransaction.swift in the @Model
// class and replace it with `var fallbackNote: String` (see below). All call sites that
// used `transaction.displayTitle` should be updated to `transaction.displayTitle(locale:)`
// or `transaction.displayTitle()` from this extension.

extension MoneyTransaction {

    // MARK: - Display title

    /// Returns the best human-readable title for a transaction.
    /// Call this from SwiftUI views — never from model or repository code.
    ///
    /// Priority: customItemName → item name → category name → note → localised fallback.
    func displayTitle(fallback: String = "Transaction") -> String {
        if let customItemName, !customItemName.isEmpty { return customItemName }
        if let item { return item.name }
        if let category { return category.name }
        if !note.isEmpty { return note }
        // Fallback: use the caller-supplied string (so views can pass a localised key result).
        return fallback
    }

    // MARK: - Search haystack

    /// A single string that covers all searchable fields for this transaction.
    /// Used by TransactionsViewModel.filteredTransactions — keeps search logic out of the model.
    func searchHaystack() -> String {
        [
            customItemName ?? "",
            item?.name ?? "",
            category?.name ?? "",
            person?.name ?? "",
            note
        ]
        .joined(separator: " ")
        .lowercased()
    }
}

// MARK: - Usage migration guide
//
// Before (in @Model, wrong):
//   var displayTitle: String {
//       if let customItemName … { return customItemName }
//       …
//       return AppLocalizer.string("transactions.fallbackTitle", fallback: "Transaction")
//   }
//
// After (in views, correct):
//   Text(transaction.displayTitle(fallback: AppLocalizer.string("transactions.fallbackTitle", fallback: "Transaction")))
//
// Or with a convenience that resolves the key at the call site:
//   Text(transaction.displayTitle(fallback: AppLocalizer.string("transactions.fallbackTitle")))
//
// Every existing `transaction.displayTitle` call site needs this one-line change.
// Files to update: TransactionRowView.swift, HomeView.swift, TransactionsView.swift,
//                  AddEditTransactionViewModel.swift (if it reads displayTitle),
//                  RecurringTransactionService.swift (does not use displayTitle — OK).
