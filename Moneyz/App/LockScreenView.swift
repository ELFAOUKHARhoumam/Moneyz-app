import SwiftUI

@MainActor
struct LockScreenView: View {
    @EnvironmentObject private var appLock: AppLockViewModel
    @EnvironmentObject private var settings: SettingsStore

    @State private var pinInput = ""

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

            VStack(spacing: 20) {
                BrandMarkView(size: 84, cornerRadius: 20)
                    .accessibilityHidden(true)

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

                if settings.usePINLock {
                    VStack(spacing: 12) {
                        SecureField(AppLocalizer.string("pin.code"), text: $pinInput)
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .multilineTextAlignment(.center)
                            .padding()
                            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .onChange(of: pinInput) { _, newValue in
                                let digitsOnly = newValue.filter { $0.isNumber }
                                pinInput = String(digitsOnly.prefix(4))
                                appLock.clearError()
                            }
                            .accessibilityLabel(Text(AppLocalizer.string("pin.code")))
                            .accessibilityValue(Text(pinInput.isEmpty ? AppLocalizer.string("lock.pin.empty") : String(format: AppLocalizer.string("lock.pin.digitsEntered"), pinInput.count)))
                            .accessibilityHint(Text(AppLocalizer.string("lock.pin.hint")))

                        if appLock.isPINEntryTemporarilyBlocked {
                            Text(String(format: AppLocalizer.string("lock.pin.blockedCountdown"), appLock.remainingRetryDelay))
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(PremiumTheme.Palette.warning)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }

                        Button {
                            appLock.unlock(withPIN: pinInput, settings: settings)
                            if !appLock.isLocked {
                                pinInput = ""
                            }
                        } label: {
                            Label(AppLocalizer.string("lock.unlockWithPIN"), systemImage: "key.fill")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(appLock.isPINEntryTemporarilyBlocked || pinInput.count != 4)
                        .accessibilityHint(Text(AppLocalizer.string("lock.unlockWithPIN")))
                    }
                    .padding(.horizontal, 32)
                }

                if settings.useFaceIDLock {
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

                if let errorMessage = appLock.errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
            }
            .padding(24)
        }
        .accessibilityElement(children: .contain)
    }
}
