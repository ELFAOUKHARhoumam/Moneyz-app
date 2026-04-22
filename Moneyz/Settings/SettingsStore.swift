import Foundation
import SwiftUI
import Combine

@MainActor
final class SettingsStore: ObservableObject {
    enum ThemePreference: String, CaseIterable, Identifiable {
        case system
        case light
        case dark

        var id: String { rawValue }

        var localizedKey: String {
            switch self {
            case .system: return "theme.system"
            case .light: return "theme.light"
            case .dark: return "theme.dark"
            }
        }
    }

    enum LanguagePreference: String, CaseIterable, Identifiable {
        case system
        case english
        case arabic

        var id: String { rawValue }

        var localizedKey: String {
            switch self {
            case .system: return "language.system"
            case .english: return "language.english"
            case .arabic: return "language.arabic"
            }
        }
    }

    enum HomeOverviewStyle: String, CaseIterable, Identifiable {
        case cards
        case ring

        var id: String { rawValue }

        var localizedKey: String {
            switch self {
            case .cards: return "dashboard.style.cards"
            case .ring: return "dashboard.style.ring"
            }
        }
    }

    private enum Keys {
        static let displayName = "settings.displayName"
        static let currencyCode = "settings.currencyCode"
        static let themePreference = "settings.themePreference"
        static let languagePreference = "settings.languagePreference"
        static let homeOverviewStyle = "settings.homeOverviewStyle"
        static let useFaceIDLock = "settings.useFaceIDLock"
        static let usePINLock = "settings.usePINLock"
        static let openingBalanceMinor = "settings.openingBalanceMinor"
        static let salaryCycleStartDay = "settings.salaryCycleStartDay"
        static let hasCompletedOnboarding = "settings.hasCompletedOnboarding"
    }

    private let defaults: UserDefaults

    @Published var displayName: String {
        didSet { defaults.set(displayName, forKey: Keys.displayName) }
    }

    @Published var currencyCode: String {
        didSet { defaults.set(currencyCode.uppercased(), forKey: Keys.currencyCode) }
    }

    @Published var themePreference: ThemePreference {
        didSet { defaults.set(themePreference.rawValue, forKey: Keys.themePreference) }
    }

    @Published var languagePreference: LanguagePreference {
        didSet { defaults.set(languagePreference.rawValue, forKey: Keys.languagePreference) }
    }

    @Published var homeOverviewStyle: HomeOverviewStyle {
        didSet { defaults.set(homeOverviewStyle.rawValue, forKey: Keys.homeOverviewStyle) }
    }

    @Published var useFaceIDLock: Bool {
        didSet { defaults.set(useFaceIDLock, forKey: Keys.useFaceIDLock) }
    }

    @Published var usePINLock: Bool {
        didSet { defaults.set(usePINLock, forKey: Keys.usePINLock) }
    }

    @Published var openingBalanceMinor: Int64 {
        didSet { defaults.set(openingBalanceMinor, forKey: Keys.openingBalanceMinor) }
    }

    @Published var salaryCycleStartDay: Int {
        didSet { defaults.set(salaryCycleStartDay, forKey: Keys.salaryCycleStartDay) }
    }

    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let storedDisplayName = defaults.string(forKey: Keys.displayName)
        let storedOnboarding = defaults.object(forKey: Keys.hasCompletedOnboarding) as? Bool

        self.displayName = storedDisplayName ?? "Friend"
        self.currencyCode = defaults.string(forKey: Keys.currencyCode) ?? "USD"
        self.themePreference = ThemePreference(rawValue: defaults.string(forKey: Keys.themePreference) ?? "system") ?? .system
        self.languagePreference = LanguagePreference(rawValue: defaults.string(forKey: Keys.languagePreference) ?? "system") ?? .system
        self.homeOverviewStyle = HomeOverviewStyle(rawValue: defaults.string(forKey: Keys.homeOverviewStyle) ?? "cards") ?? .cards
        self.useFaceIDLock = defaults.bool(forKey: Keys.useFaceIDLock)
        self.usePINLock = defaults.bool(forKey: Keys.usePINLock)
        self.openingBalanceMinor = (defaults.object(forKey: Keys.openingBalanceMinor) as? NSNumber)?.int64Value ?? 0
        self.salaryCycleStartDay = (defaults.object(forKey: Keys.salaryCycleStartDay) as? NSNumber)?.intValue ?? 1
        self.hasCompletedOnboarding = storedOnboarding ?? (storedDisplayName != nil)
    }

    func completeOnboarding(
        displayName: String,
        currencyCode: String,
        salaryCycleStartDay: Int,
        usePINLock: Bool
    ) {
        self.displayName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        self.currencyCode = currencyCode.uppercased()
        self.salaryCycleStartDay = min(max(salaryCycleStartDay, 1), 28)
        self.usePINLock = usePINLock
        hasCompletedOnboarding = true
    }

    var locale: Locale {
        switch languagePreference {
        case .system:
            return .autoupdatingCurrent
        case .english:
            return Locale(identifier: "en")
        case .arabic:
            return Locale(identifier: "ar")
        }
    }

    var layoutDirection: LayoutDirection {
        switch languagePreference {
        case .arabic:
            return .rightToLeft
        case .system:
            let direction = Locale.Language(identifier: Locale.autoupdatingCurrent.identifier).characterDirection
            return direction == .rightToLeft ? .rightToLeft : .leftToRight
        case .english:
            return .leftToRight
        }
    }

    var interfaceRefreshID: String {
        let direction = layoutDirection == .rightToLeft ? "rtl" : "ltr"
        return "lang-\(languagePreference.rawValue)-\(direction)-\(locale.identifier)"
    }

    var preferredColorScheme: ColorScheme? {
        switch themePreference {
        case .system:
            return nil
        case .light:
            return .light
        case .dark:
            return .dark
        }
    }
}
