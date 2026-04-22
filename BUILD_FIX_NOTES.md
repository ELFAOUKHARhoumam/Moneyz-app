Build fix notes applied from Downloads/Moneyz_fix_summary.md

- Added or verified `import Combine` for ObservableObject-based view models and stores.
- Replaced deprecated locale direction logic in `Moneyz/Moneyz/Settings/SettingsStore.swift`.
- Marked SwiftUI app/views using `@StateObject` as `@MainActor` to avoid actor-isolated initializer warnings.
- Made `Task` closures explicitly `@MainActor` in lock/auth related flows.
- Wrapped test files in `#if canImport(XCTest)` so accidental app-target membership does not break builds.

Important Xcode note:

- Keep the app target free of direct `XCTest` dependencies.
- Keep files in `Tests/` assigned to a separate test target when available.

## Release Readiness Validation Commands

### Known-good build command
xcodebuild -project /Users/elfaoukharhoumam/personal-projects/MoneyzByGpt5.4Pro/Moneyz/Moneyz.xcodeproj -scheme Moneyz -destination 'generic/platform=iOS Simulator' build

### Known-good test command
xcodebuild -project /Users/elfaoukharhoumam/personal-projects/MoneyzByGpt5.4Pro/Moneyz/Moneyz.xcodeproj -scheme Moneyz -destination 'platform=iOS Simulator,name=iPhone 17' test

### Notes
- The `Moneyz` scheme is configured so tests run from both Xcode and CLI.
- Recent successful test runs generate `.xcresult` bundles under:
  /Users/elfaoukharhoumam/Library/Developer/Xcode/DerivedData/Moneyz-emihtwfqzxwnaeapyxxiusyqrfqj/Logs/Test/
- The visible `appintentsmetadataprocessor` warning in Xcodebuild output is Xcode-generated and not from Moneyz app logic.
