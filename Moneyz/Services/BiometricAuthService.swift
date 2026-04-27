import Foundation
import LocalAuthentication

protocol BiometricAuthServing {
    func canAuthenticate() -> Bool
    func authenticate(reason: String) async -> Bool
}

// MARK: - BiometricAuthService
// FIX 1: Removed dead do/catch around canEvaluatePolicy.
// Root cause: canEvaluatePolicy is NOT a throwing function — it uses an NSError output parameter.
// The do/catch block never caught anything and misled readers into thinking this was try-safe.
//
// FIX 2: Made canAuthenticate() recalculate on each call so SettingsViewModel can refresh it.
// Root cause: biometricsAvailable was set once at init() time — if a user enables Face ID
// while the app is open, the toggle in Settings would remain disabled until restart.

final class BiometricAuthService: BiometricAuthServing {
    func canAuthenticate() -> Bool {
        guard NSClassFromString("LAContext") != nil else { return false }

        let context = LAContext()
        var error: NSError?

        // Correct pattern: canEvaluatePolicy is not throws, error is an out-parameter
        return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
    }

    func authenticate(reason: String) async -> Bool {
        guard NSClassFromString("LAContext") != nil else { return false }

        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        return await withCheckedContinuation { continuation in
            var error: NSError?

            // Correct pattern: no do/catch, error is an out-parameter
            let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)

            guard canEvaluate else {
                continuation.resume(returning: false)
                return
            }

            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
