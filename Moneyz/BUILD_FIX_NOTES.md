# Moneyz build fixes

This bundle includes source-only fixes for the Xcode errors shown in the screenshots:

- added missing `import Combine` to all `ObservableObject` / `@Published` files
- replaced deprecated `Locale.characterDirection(forLanguage:)` with `Locale.Language(identifier:).characterDirection`
- marked SwiftUI app/views as `@MainActor` to avoid actor-isolated initializer warnings with `@StateObject`
- made `Task` hops explicit with `@MainActor`
- wrapped `Tests/*.swift` in `#if canImport(XCTest)` so the app target still builds if those files are accidentally added to the main target
- updated CloudKit status callback to hop back via `Task { @MainActor in ... }`

## Important Xcode target membership note

If you want the tests to actually run, create a separate **MoneyzTests** target and move the files in `Tests/` into that test target.
If they stay in the main app target, they are intentionally skipped by `#if canImport(XCTest)`.
