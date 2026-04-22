import Foundation

enum AppLocalizer {
    private static let languagePreferenceKey = "settings.languagePreference"
    private static let tableName = "Localizable"

    static func currentLanguageCode(defaults: UserDefaults = .standard) -> String? {
        switch defaults.string(forKey: languagePreferenceKey) ?? "system" {
        case "english":
            return "en"
        case "arabic":
            return "ar"
        default:
            return nil
        }
    }

    static func localizedBundle(languageCode: String? = nil) -> Bundle {
        let resolvedCode = languageCode ?? currentLanguageCode()

        guard
            let resolvedCode,
            let path = Bundle.main.path(forResource: resolvedCode, ofType: "lproj"),
            let bundle = Bundle(path: path)
        else {
            return .main
        }

        return bundle
    }

    static func string(_ key: String, languageCode: String? = nil) -> String {
        let bundle = localizedBundle(languageCode: languageCode)
        let localized = bundle.localizedString(forKey: key, value: nil, table: tableName)

        if localized != key {
            return localized
        }

        if bundle.bundlePath != Bundle.main.bundlePath {
            return Bundle.main.localizedString(forKey: key, value: key, table: tableName)
        }

        return localized
    }

    static func string(_ key: String, fallback: String, languageCode: String? = nil) -> String {
        let localized = string(key, languageCode: languageCode)
        return localized == key ? fallback : localized
    }

    static func formattedString(
        _ key: String,
        fallback: String,
        _ arguments: CVarArg...,
        languageCode: String? = nil
    ) -> String {
        let format = string(key, fallback: fallback, languageCode: languageCode)
        let localeIdentifier = languageCode ?? currentLanguageCode() ?? Locale.autoupdatingCurrent.identifier
        let locale = Locale(identifier: localeIdentifier)
        return String(format: format, locale: locale, arguments: arguments)
    }
}
