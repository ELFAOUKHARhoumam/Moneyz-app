# Moneyz Audit — Implementation Guide

## Files Produced and Where to Apply Them

| Output File | Replace This App File | Priority |
|---|---|---|
| `LockScreenView.swift` | `Moneyz/App/LockScreenView.swift` | 🔴 Critical |
| `TransactionsView.swift` | `Moneyz/Features/Transactions/TransactionsView.swift` | 🔴 Critical |
| `PremiumTheme.swift` | `Moneyz/UI/PremiumTheme.swift` | 🔴 Critical |
| `DebtView.swift` | `Moneyz/Features/Debt/DebtView.swift` | 🟠 High |
| `BiometricAuthService.swift` | `Moneyz/Services/BiometricAuthService.swift` | 🟠 High |
| `SettingsView.swift` | `Moneyz/Features/Settings/SettingsView.swift` | 🟠 High |
| `SettingsViewModel.swift` | `Moneyz/Features/Settings/SettingsViewModel.swift` | 🟠 High |
| `SeedDataSeeder.swift` | `Moneyz/Persistence/SeedDataSeeder.swift` | 🟠 High |
| `HomeView.swift` | `Moneyz/Features/Home/HomeView.swift` | 🟠 High |
| `TransactionRowView.swift` | `Moneyz/UI/TransactionRowView.swift` | 🟡 Medium |
| `BudgetView.swift` | `Moneyz/Features/Budget/BudgetView.swift` | 🟡 Medium |
| `BudgetInsightsService.swift` | `Moneyz/Services/BudgetInsightsService.swift` | 🟡 Medium |
| `LocalizationAdditions.strings` | **Append** to both `en.lproj/Localizable.strings` and `ar.lproj/Localizable.strings` | 🔴 Critical |
| `SeeAllLocalization.strings` | **Append** `common.seeAll` to both `.strings` files | 🟠 High |

---

## What Each File Fixes and Why

### LockScreenView.swift
**Fixes:**
1. 4-dot PIN indicator (`PINDotIndicator`) — sighted users now see filled dots as they type.
   Previous: `SecureField` gave zero visual feedback on digit count.
2. Auto-submit on 4th digit — no need to tap "Unlock with PIN" after the 4th digit.
3. Shake animation + haptic on wrong PIN.
4. Auto-trigger Face ID on `.onAppear` when `useFaceIDLock = true`.
   Previous: users had to tap the Face ID button manually every time.

**Why this was chosen first:** The lock screen is the first thing users see when reopening the app.
A bad lock experience immediately signals low quality.

### TransactionsView.swift + DateGroupedTransactionList
**Fixes:**
1. `DateGroupedTransactionList` — reusable component for date-grouped display.
2. `TransactionsView` now groups by date, matching `HomeView`.
   Previous: flat `ForEach` list, inconsistent with Home.
3. Grocery removed from Transactions toolbar — one less cluttered icon in the nav bar.
4. Count badge in toolbar replaces the verbose "Showing all transactions" summary row.

**Why:** Date grouping is the most basic UX expectation of any transaction list. Its absence in
`TransactionsView` while `HomeView` had it was a jarring inconsistency.

### PremiumTheme.swift
**Adds:**
- `PremiumTheme.Spacing` (xs/sm/md/lg/xl)
- `PremiumTheme.CornerRadius` (sm/md/lg)
- `PremiumTheme.Palette.neutralFill` and `neutralStroke` — replaces `Color.primary.opacity(0.08)` magic numbers
- `emojiOverlay` parameter on `IconBadge` — used by `TransactionRowView`
- `actionTitle`/`action` parameters on `SectionHeaderView`

**Why:** Without a shared token system, spacing and radius values drift as the app grows.
The `Spacing` and `CornerRadius` enums are the foundation for all future UI consistency.

### DebtView.swift
**Fixes:**
1. "Mark as Settled" leading swipe action — most common debt action now requires zero taps into an editor.
2. Overdue items show a red border and overdue label badge.
3. Status badge added to the debt card amount column.
4. `common.error`/`common.ok` alert now uses keys that exist in the `.strings` files.

**Why:** The overdue/settled flows are the core value of the Debt screen. The lack of a quick settle
path meant every "I got paid back" interaction required a full edit flow.

### BiometricAuthService.swift
**Fixes:**
1. Removed `do/catch` around `canEvaluatePolicy` — it's not a `throws` function.
   Previous code had dead exception handling that never executed.
2. `canAuthenticate()` now recalculates on every call (it always did, the fix is documentation clarity).

**Why:** Dead code creates a false sense of safety and misleads engineers doing code review.

### SettingsView.swift + SettingsViewModel.swift
**Fixes:**
1. Salary cycle stepper label: was "Salary cycle starts on day Salary cycle starts on day 1".
   Now: section label says "Salary cycle starts on day", stepper row shows only "Paycheck day: X".
2. Dashboard style picker moved from HomeView to Settings > Appearance.
3. `refreshBiometricsAvailability()` called on `.onAppear` so Face ID toggle updates live.
4. Haptic feedback on save and apply recurring.

### SeedDataSeeder.swift
**Fixes:**
1. All category names, item names, group names, and preset names now use `AppLocalizer.string()` with fallbacks.
2. `previewReferences` now matches categories by emoji (stable identifier) instead of English name string.

**Why:** Arabic users previously got "Grocery", "Salary", "Rent" in English regardless of language.
The emoji-based reference lookup is robust to localization changes.

### HomeView.swift
**Fixes:**
1. Dashboard style picker removed — now in Settings.
2. Time range segmented control is inline (no card wrapper), reducing height by ~60pt.
3. Overview condensed from 6 cards to 4 (removed Spending Pulse and Net Debt).
4. 7-day spending bar chart added using Swift Charts — first real visualization in the app.
5. Burn rate bar now has animated fill and a contextual insight sentence.
6. "See All" button on recent transactions section header.
7. Grocery button downsized from hero-level to a small icon badge.

### TransactionRowView.swift
**Fixes:**
1. Category emoji overlays the icon badge when available.
   Previous: always showed a generic arrow regardless of category.

### BudgetView.swift + BudgetInsightsService.swift
**Fixes:**
1. Progress bar threshold aligned to 0.85 matching `statusKey` warning threshold.
   Previous: bar turned amber at 90% but text said "Close to limit" at 85% — 5% gap of inconsistency.
2. Animated progress bar fill.
3. Uses `PremiumTheme` token constants.

---

## Localization Additions Required

Append `LocalizationAdditions.strings` content to **both** files:
- `Moneyz/en.lproj/Localizable.strings`
- `Moneyz/ar.lproj/Localizable.strings`

Also append from `SeeAllLocalization.strings`:
- `"common.seeAll" = "See All";` to English
- `"common.seeAll" = "عرض الكل";` to Arabic

The `LocalizationConsistencyTests.swift` test will verify both files have matching keys.
Run it after applying changes to confirm parity.

---

## Items That Need Minor Manual Wiring

### 1. HomeView — Charts import
`HomeView.swift` uses `import Charts`. Ensure Charts framework is available (it's bundled with iOS 16+ SDK — no SPM addition needed). If targeting iOS 17.6+ as set in the project, this is already available.

### 2. TransactionsViewModel — remove showingGrocery
`TransactionsView.swift` no longer shows Grocery, but `TransactionsViewModel` still has
`@Published var showingGrocery = false`. Remove that property from `TransactionsViewModel.swift`
to keep the model clean.

### 3. SettingsViewModel — refreshBiometricsAvailability
The method `refreshBiometricsAvailability()` is added in `SettingsViewModel.swift`.
The `SettingsViewModelTests.swift` test file doesn't test this new method — consider adding:
```swift
func testBiometricsAvailabilityRefreshesOnDemand() {
    let stub = StubBiometricAuthService(canAuthenticateValue: false)
    let viewModel = SettingsViewModel(authService: stub)
    XCTAssertFalse(viewModel.biometricsAvailable)
    // stub changes its value — simulate device enabling biometrics
    // (StubBiometricAuthService would need a mutable property for this)
}
```

### 4. BudgetView — common.ok key
`BudgetView.swift` alert now uses `"common.ok"` which is added in `LocalizationAdditions.strings`.
Apply the localization file before building.

### 5. HomeView — common.seeAll key
Uses `AppLocalizer.string("common.seeAll")` — in `SeeAllLocalization.strings`, must be appended.

---

## Remaining Gaps (Honest Assessment)

These were identified in the audit but are **not implemented** in this batch — they require larger
architectural changes or new frameworks:

| Gap | Why Not Implemented Now | Recommended Phase |
|---|---|---|
| Shared `rangeOption` state between Home and Budget | Requires new `@EnvironmentObject` coordinator or `@SceneStorage` — touch-point across both ViewModels and RootTabView | Phase 2 |
| Category breakdown pie/bar chart on Transactions | New `Charts` view + aggregation service | Phase 2 |
| `WidgetKit` extension | Separate target, entitlements, shared App Group data | Phase 3 |
| Onboarding entrance animations | Low risk, easy — `withAnimation` + `.transition` | Phase 1 (next batch) |
| Grocery → Transaction conversion (batch expense) | New flow + model changes in GroceryRepository | Phase 3 |
| Type scale enum (`PremiumTheme.Typography`) | Each screen still uses inline `.font()` calls | Phase 2 |
| iPad `DashboardRingOverviewView` safety | Needs dynamic `ringStep` from `GeometryReader` size | Phase 2 |
| `matchedGeometryEffect` transaction row → detail | Complex, high animation polish value | Phase 4 |

---

## Quick Verification Checklist After Applying

- [ ] Build succeeds on iOS Simulator (iPhone 16)
- [ ] `MoneyzTests` target passes all existing tests
- [ ] `LocalizationConsistencyTests` passes (both .strings files have same keys)
- [ ] Lock screen: typing 4 digits auto-submits, dots animate, wrong PIN shakes
- [ ] Lock screen: Face ID triggers automatically on appear (test on physical device)
- [ ] Transactions tab: rows are grouped by date with section headers
- [ ] Debt tab: left swipe on open debt shows "Settled" green action
- [ ] Debt tab: overdue items show red border
- [ ] Settings: salary stepper shows "Paycheck day: 1" not the doubled label
- [ ] Settings: dashboard style picker is in Settings > Appearance (not on Home)
- [ ] Home: 7-day bar chart is visible in the Spending Pulse card
- [ ] Home: burn rate shows contextual insight text, not static footer
- [ ] First install (delete app, reinstall): categories seeded with localized names
- [ ] Budget: progress bar turns amber at 85%, red at 100% (matching status text)
