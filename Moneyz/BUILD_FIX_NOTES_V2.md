Moneyz build fix v2

What was fixed:
- added missing `import SwiftData` in `MoneyzApp.swift`
- changed SwiftUI app/view `@StateObject` creation to explicit `init()` ownership to avoid actor-isolation warnings in newer toolchains
- added explicit empty/custom initializers to `@Query`-backed views so Xcode no longer tries to use a synthesized private memberwise init
- made every `SortDescriptor` root type explicit, which fixes the "Cannot infer key path type from context" errors
- removed the test files from the app source bundle so the main app target does not try to compile `XCTest`
- kept optional tests in a separate folder/archive for a future `MoneyzTests` target
- replaced preview setup with preview host views so previews stop instantiating main-actor objects from nonisolated contexts

How to apply:
1. Replace the current app source files with the files from `MoneyzSource_buildfixed_v2.zip`
2. In Xcode, remove any old `Tests/*.swift` files from the Moneyz app target
3. Clean build folder
4. Build again

Optional tests:
- if you want tests, create a separate `MoneyzTests` target and add the files from `MoneyzTests_optional.zip` there
