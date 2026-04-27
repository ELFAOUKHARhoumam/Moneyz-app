import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - PIN Dot Indicator
// Visual 4-dot feedback replacing the invisible SecureField.
// Sighted users see filled/empty dots as they type — matches every major banking app.
@MainActor
private struct PINDotIndicator: View {
    let enteredCount: Int
    let isBlocked: Bool
    private let totalDots = 4

    var body: some View {
        HStack(spacing: 20) {
            ForEach(0..<totalDots, id: \.self) { index in
                Circle()
                    .fill(dotFill(for: index))
                    .frame(width: 16, height: 16)
                    .overlay(
                        Circle()
                            .strokeBorder(dotStroke(for: index), lineWidth: 1.5)
                    )
                    .scaleEffect(index < enteredCount ? 1.1 : 1.0)
                    .animation(.spring(response: 0.25, dampingFraction: 0.6), value: enteredCount)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            enteredCount == 0
                ? Text(AppLocalizer.string("lock.pin.empty"))
                : Text(String(format: AppLocalizer.string("lock.pin.digitsEntered"), enteredCount))
        )
    }

    private func dotFill(for index: Int) -> Color {
        if isBlocked { return PremiumTheme.Palette.warning.opacity(0.3) }
        return index < enteredCount ? PremiumTheme.Palette.accent : Color.clear
    }

    private func dotStroke(for index: Int) -> Color {
        if isBlocked { return PremiumTheme.Palette.warning }
        return index < enteredCount ? PremiumTheme.Palette.accent : Color.primary.opacity(0.3)
    }
}

// MARK: - Focus Helper
// UIViewRepresentable wrapper that gives us programmatic focus for a UITextField.
// We need this because SwiftUI's @FocusState on a hidden SecureField doesn't reliably
// trigger the number pad on tap — this bridge guarantees keyboard presentation.
private struct FirstResponderTextField: UIViewRepresentable {
    @Binding var text: String
    let shouldBecomeFirstResponder: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> UITextField {
        let tf = UITextField()
        tf.isSecureTextEntry = true
        tf.keyboardType = .numberPad
        tf.textContentType = .oneTimeCode
        tf.delegate = context.coordinator
        tf.tintColor = .clear          // hide cursor
        tf.textColor = .clear          // hide typed text
        tf.backgroundColor = .clear
        return tf
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        // Keep text in sync
        if uiView.text != text {
            uiView.text = text
        }
        // Bring up keyboard when requested
        if shouldBecomeFirstResponder && !uiView.isFirstResponder {
            DispatchQueue.main.async { uiView.becomeFirstResponder() }
        }
    }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: FirstResponderTextField
        init(_ parent: FirstResponderTextField) { self.parent = parent }

        func textField(_ textField: UITextField,
                       shouldChangeCharactersIn range: NSRange,
                       replacementString string: String) -> Bool {
            let current = textField.text ?? ""
            let updated: String
            if string.isEmpty {
                // Backspace
                updated = current.isEmpty ? "" : String(current.dropLast())
            } else {
                let digits = string.filter { $0.isNumber }
                updated = String((current + digits).prefix(4))
            }
            parent.text = updated
            return false  // we manage the text ourselves
        }
    }
}

// MARK: - Lock Screen View
@MainActor
struct LockScreenView: View {
    @EnvironmentObject private var appLock: AppLockViewModel
    @EnvironmentObject private var settings: SettingsStore

    @State private var pinInput = ""
    @State private var shakeOffset: CGFloat = 0
    // Controls whether the hidden text field is first responder
    @State private var isKeyboardActive = false

    private var lockSubtitle: String {
        if settings.usePINLock {
            return AppLocalizer.string("lock.subtitle.pin")
        }
        if settings.useFaceIDLock {
            return AppLocalizer.string("settings.faceID.subtitle")
        }
        return AppLocalizer.string("lock.title")
    }

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                BrandMarkView(size: 84, cornerRadius: 20)
                    .accessibilityHidden(true)

                VStack(spacing: 8) {
                    Text(AppLocalizer.string("lock.title"))
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility3)

                    Text(lockSubtitle)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                        .dynamicTypeSize(...DynamicTypeSize.accessibility4)
                }

                if settings.usePINLock {
                    pinSection
                }

                if settings.useFaceIDLock {
                    faceIDSection
                }

                if let errorMessage = appLock.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .transition(.opacity)
                }
            }
            .padding(24)
        }
        .accessibilityElement(children: .contain)
        .onAppear {
            if settings.usePINLock {
                // Show keyboard immediately on appear
                isKeyboardActive = true
            } else if settings.useFaceIDLock {
                // Auto-trigger Face ID when PIN is not in use
                // Previously required a manual tap — now triggers automatically
                Task { @MainActor in
                    await appLock.unlockIfPossible(settings: settings)
                }
            }
        }
    }

    // MARK: - PIN Section

    private var pinSection: some View {
        VStack(spacing: 20) {
            // Dot indicator — tapping it activates the keyboard
            PINDotIndicator(
                enteredCount: pinInput.count,
                isBlocked: appLock.isPINEntryTemporarilyBlocked
            )
            .offset(x: shakeOffset)
            .onTapGesture {
                isKeyboardActive = true
            }
            .accessibilityAddTraits(.isButton)
            .accessibilityHint(Text(AppLocalizer.string("lock.pin.hint")))

            // Invisible UITextField that drives keyboard + secure input
            // Using UIViewRepresentable guarantees keyboard appears reliably on tap
            // and on appear, solving the SwiftUI FocusState + numberPad unreliability.
            FirstResponderTextField(text: $pinInput, shouldBecomeFirstResponder: isKeyboardActive)
                .frame(width: 1, height: 1)
                .opacity(0.01)
                .onChange(of: pinInput) { _, newValue in
                    // Enforce digits-only and 4-char max
                    let digitsOnly = String(newValue.filter { $0.isNumber }.prefix(4))
                    if pinInput != digitsOnly {
                        pinInput = digitsOnly
                    }
                    appLock.clearError()
                    // Auto-submit on 4th digit — no button tap required
                    if digitsOnly.count == 4 {
                        attemptPINUnlock()
                    }
                }

            Button {
                isKeyboardActive = true
                if pinInput.count == 4 {
                    attemptPINUnlock()
                }
            } label: {
                Label(AppLocalizer.string("lock.unlockWithPIN"), systemImage: "key.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(appLock.isPINEntryTemporarilyBlocked || pinInput.count != 4)
            .padding(.horizontal, 32)

            if appLock.isPINEntryTemporarilyBlocked {
                Text(String(format: AppLocalizer.string("lock.pin.blockedCountdown"),
                            appLock.remainingRetryDelay))
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(PremiumTheme.Palette.warning)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }
        }
    }

    // MARK: - Face ID Section

    private var faceIDSection: some View {
        Button {
            Task { @MainActor in
                await appLock.unlockIfPossible(settings: settings)
            }
        } label: {
            if appLock.isAuthenticating {
                ProgressView()
                    .frame(maxWidth: .infinity)
            } else {
                Label(AppLocalizer.string("settings.faceID.unlock"), systemImage: "faceid")
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.bordered)
        .padding(.horizontal, 32)
        .accessibilityHint(Text(AppLocalizer.string("settings.faceID.subtitle")))
    }

    // MARK: - PIN Unlock Logic

    private func attemptPINUnlock() {
        appLock.unlock(withPIN: pinInput, settings: settings)

        if appLock.isLocked {
            // Wrong PIN: clear input, shake dots, error haptic
            pinInput = ""
            withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
                shakeOffset = 12
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.3)) {
                    shakeOffset = 0
                }
            }
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        } else {
            // Correct: success haptic, clear input
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            pinInput = ""
            isKeyboardActive = false
        }
    }
}
