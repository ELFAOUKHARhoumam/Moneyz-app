Moneyz screenshot fix notes

What was fixed:
- Localization files moved to the project root as en.lproj / ar.lproj so SwiftUI and String(localized:) can resolve keys correctly.
- Added BrandMarkView fallback so the app no longer depends on the BrandMark asset being present to render the logo.
- Fixed dynamic localized keys in the onboarding, PIN sheet, and lock screen.
- Reworked the PIN setup sheet to avoid the Form + number pad layout warnings seen in the simulator.
- Kept the CloudKit-safe Settings behavior from the prior patch.

Important Xcode cleanup:
1. Remove the old Localization group/files from the target if they still exist.
2. Remove any duplicate old source files/groups that still show stale issues in Issue Navigator.
3. Add the new en.lproj and ar.lproj folders from this package to the app target.
4. Ensure Assets.xcassets is in the app target and App Icons Source is set to AppIcon.
5. Product -> Clean Build Folder, then rebuild.

If the old build issues still remain in Issue Navigator after a successful build, delete Derived Data for the project and reopen Xcode.
