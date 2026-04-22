import Foundation
import LocalAuthentication

protocol BiometricAuthServing {
    func canAuthenticate() -> Bool
    func authenticate(reason: String) async -> Bool
}

final class BiometricAuthService: BiometricAuthServing {
    func canAuthenticate() -> Bool {
        guard NSClassFromString("LAContext") != nil else { return false }

        let context = LAContext()
        var error: NSError?

        do {
            return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
        } catch {
            return false
        }
    }

    func authenticate(reason: String) async -> Bool {
        guard NSClassFromString("LAContext") != nil else { return false }

        let context = LAContext()
        context.localizedFallbackTitle = "Use Passcode"

        return await withCheckedContinuation { continuation in
            var error: NSError?

            let canEvaluate: Bool
            do {
                canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
            } catch {
                continuation.resume(returning: false)
                return
            }

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
