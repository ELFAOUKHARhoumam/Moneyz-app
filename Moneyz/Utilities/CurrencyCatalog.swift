import Foundation

struct CurrencyOption: Identifiable, Hashable {
    let code: String

    var id: String { code }

    func displayName(locale: Locale = .autoupdatingCurrent) -> String {
        let localizedName = locale.localizedString(forCurrencyCode: code) ?? code
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.locale = locale
        let symbol = formatter.currencySymbol ?? code
        return "\(code) • \(symbol) • \(localizedName)"
    }
}

enum CurrencyCatalog {
    static let supported: [CurrencyOption] = [
        "USD", "EUR", "GBP", "AED", "SAR", "QAR", "KWD", "OMR", "BHD",
        "JOD", "EGP", "MAD", "DZD", "TND", "TRY", "INR", "PKR", "MYR",
        "IDR", "SGD", "CAD", "AUD", "JPY", "CNY"
    ].map(CurrencyOption.init(code:))
}
