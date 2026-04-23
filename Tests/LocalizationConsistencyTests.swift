import Foundation
import XCTest

final class LocalizationConsistencyTests: XCTestCase {
    func testEnglishAndArabicLocalizationsShareTheSameKeys() throws {
        let repositoryRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()

        let englishKeys = try localizationKeys(
            at: repositoryRoot.appendingPathComponent("Moneyz/en.lproj/Localizable.strings")
        )
        let arabicKeys = try localizationKeys(
            at: repositoryRoot.appendingPathComponent("Moneyz/ar.lproj/Localizable.strings")
        )

        let missingInArabic = englishKeys.subtracting(arabicKeys).sorted()
        let missingInEnglish = arabicKeys.subtracting(englishKeys).sorted()

        XCTAssertEqual(
            englishKeys,
            arabicKeys,
            "Localization key mismatch. Missing in Arabic: \(missingInArabic). Missing in English: \(missingInEnglish)."
        )
    }

    private func localizationKeys(at url: URL) throws -> Set<String> {
        let contents = try String(contentsOf: url, encoding: .utf8)
        let regex = try NSRegularExpression(
            pattern: #"^\s*\"((?:\\.|[^\"\\])*)\"\s*="#,
            options: [.anchorsMatchLines]
        )
        let range = NSRange(contents.startIndex..<contents.endIndex, in: contents)

        return Set(
            regex.matches(in: contents, options: [], range: range).compactMap { match in
                guard let keyRange = Range(match.range(at: 1), in: contents) else {
                    return nil
                }
                return String(contents[keyRange])
            }
        )
    }
}