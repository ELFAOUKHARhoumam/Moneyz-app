import CryptoKit
import Foundation
import Security

struct PINVerificationResult: Equatable {
    let isValid: Bool
    let wasMigrated: Bool
}

enum PINSecurity {
    private static let service = "Moneyz.LocalPIN"
    private static let account = "primary"
    private static let hashPrefix = "v2:"

    static var hasStoredPIN: Bool {
        loadStoredValue() != nil
    }

    @discardableResult
    static func save(pin: String) -> Bool {
        guard let normalizedPIN = normalize(pin: pin), let data = hashedStorageValue(for: normalizedPIN).data(using: .utf8) else {
            return false
        }

        let query: [String: Any] = baseQuery()
        let attributes: [String: Any] = [
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecValueData as String: data
        ]

        let existingStatus = SecItemCopyMatching(query as CFDictionary, nil)

        if existingStatus == errSecSuccess {
            return SecItemUpdate(query as CFDictionary, attributes as CFDictionary) == errSecSuccess
        }

        var addQuery = query
        addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        addQuery[kSecValueData as String] = data
        return SecItemAdd(addQuery as CFDictionary, nil) == errSecSuccess
    }

    static func verify(pin: String) -> Bool {
        verifyDetailed(pin: pin).isValid
    }

    static func verifyDetailed(pin: String) -> PINVerificationResult {
        guard let normalizedPIN = normalize(pin: pin), let storedValue = loadStoredValue() else {
            return PINVerificationResult(isValid: false, wasMigrated: false)
        }

        if storedValue.hasPrefix(hashPrefix) {
            let expectedValue = hashedStorageValue(for: normalizedPIN)
            return PINVerificationResult(isValid: storedValue == expectedValue, wasMigrated: false)
        }

        guard storedValue == normalizedPIN else {
            return PINVerificationResult(isValid: false, wasMigrated: false)
        }

        let migrated = save(pin: normalizedPIN)
        return PINVerificationResult(isValid: true, wasMigrated: migrated)
    }

    static func removePIN() {
        let query = baseQuery()
        SecItemDelete(query as CFDictionary)
    }

    private static func loadStoredValue() -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        guard status == errSecSuccess, let data = item as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    private static func normalize(pin: String) -> String? {
        let normalizedPIN = pin.filter { $0.isNumber }
        guard normalizedPIN.count == 4 else { return nil }
        return normalizedPIN
    }

    private static func hashedStorageValue(for pin: String) -> String {
        let digest = SHA256.hash(data: Data(pin.utf8))
        return hashPrefix + digest.map { String(format: "%02x", $0) }.joined()
    }

    private static func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
