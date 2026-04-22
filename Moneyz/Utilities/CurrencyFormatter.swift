import Foundation

enum CurrencyFormatter {
    static func string(from minorUnits: Int64, currencyCode: String, locale: Locale = .autoupdatingCurrent) -> String {
        let value = Double(minorUnits) / 100.0
        return value.formatted(.currency(code: currencyCode).locale(locale))
    }

    static func decimalString(from minorUnits: Int64, locale: Locale = .autoupdatingCurrent) -> String {
        let value = Double(minorUnits) / 100.0
        return value.formatted(.number.locale(locale).precision(.fractionLength(2)))
    }

    static func minorUnits(from text: String, locale: Locale = .autoupdatingCurrent) -> Int64? {
        let groupingSeparator = locale.groupingSeparator ?? ","
        let decimalSeparator = locale.decimalSeparator ?? "."

        let sanitized = text
            .replacingOccurrences(of: groupingSeparator, with: "")
            .replacingOccurrences(of: decimalSeparator, with: ".")
            .components(separatedBy: CharacterSet(charactersIn: "0123456789.-").inverted)
            .joined()

        guard let amount = Double(sanitized) else { return nil }
        return Int64((amount * 100.0).rounded())
    }
}
