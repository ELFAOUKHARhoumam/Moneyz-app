# Moneyz

Moneyz is a SwiftUI personal finance app for iPhone and iPad focused on budgeting, transactions, debt tracking, grocery planning, recurring entries, onboarding, app lock, and bilingual support (English and Arabic).

## Features

- Budget planning and overview
- Transaction history and editing
- Debt tracking and summaries
- Grocery list mode
- Recurring transaction rules
- Onboarding flow for name, currency, paycheck cycle, and PIN setup
- Security options with PIN and biometric authentication
- English and Arabic localization with RTL layout support
- Optional CloudKit-aware sync status handling
- Unit tests for core view models and services

## Tech Stack

- Swift 5
- SwiftUI
- SwiftData
- Xcode project-based app
- XCTest
- LocalAuthentication
- CloudKit capability checks

## Requirements

- macOS with Xcode 16.4 or newer
- iOS / iPadOS deployment target: 17.6
- Swift 5.0

## Project Structure

```text
Moneyz/
├── Moneyz/                  # Application source
│   ├── App/
│   ├── Features/
│   ├── Models/
│   ├── Persistence/
│   ├── Repositories/
│   ├── Services/
│   ├── Settings/
│   ├── UI/
│   └── Utilities/
├── Tests/                   # XCTest unit tests
└── Moneyz.xcodeproj/        # Xcode project
```

## Getting Started

1. Open `Moneyz.xcodeproj` in Xcode.
2. Select the `Moneyz` scheme.
3. Choose an iPhone or iPad simulator running iOS 17.6+ (or a compatible device).
4. Build and run the app.

## Running Tests

From Xcode, run the **MoneyzTests** test target, or use the command line:

```bash
xcodebuild test \
  -project Moneyz.xcodeproj \
  -scheme Moneyz \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

If that simulator name is unavailable on your machine, replace it with any installed iPhone simulator.

## GitHub Setup

### 1. Initialize Git locally

```bash
git init
git add .
git commit -m "Initial commit"
```

### 2. Create a GitHub repository

Create a new empty repository on GitHub, for example `moneyz`.

### 3. Connect and push

```bash
git remote add origin https://github.com/YOUR_USERNAME/moneyz.git
git branch -M main
git push -u origin main
```

## Continuous Integration

This repository includes a GitHub Actions workflow that builds and tests the app on every push and pull request to `main`.

## Notes About Signing and Cloud Features

- The project currently contains a personal development team identifier in Xcode build settings. You should replace it with your own Apple Developer team in Xcode before archiving or distributing the app.
- The app includes CloudKit capability checks in code, but repository-level iCloud entitlements are not included here. Configure your own signing and capabilities in Xcode for your Apple Developer account if you want CloudKit enabled.
- Biometrics require a real device or a simulator configured for biometric testing.

## Recommended Repository Settings

- Add a repository description and topics like `swift`, `swiftui`, `ios`, `ipad`, `personal-finance`, `budgeting`.
- Protect the `main` branch.
- Require pull request reviews if collaborating.
- Enable GitHub Actions.

## Suggested Next Improvements

- Add screenshots to the README
- Add a LICENSE file matching your intended open-source usage
- Add issue and pull request templates
- Add badges for build status

## License

No license file is included yet. Add one before publishing if you want others to be allowed to use, modify, or distribute the code.
