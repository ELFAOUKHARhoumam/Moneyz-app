import SwiftUI
import Foundation
import SwiftData

@MainActor
struct OnboardingView: View {
    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var appLock: AppLockViewModel
    @Environment(\.colorScheme) private var colorScheme

    @State private var displayName = ""
    @State private var currencyCode = "USD"
    @State private var salaryCycleStartDay = 1
    @State private var wantsPIN = false
    @State private var hasConfiguredPIN = false
    @State private var showingPINSetup = false
    @State private var validationMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumTheme.PageBackground()
                    .ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(alignment: .leading, spacing: 16) {
                            BrandMarkView(size: 92, cornerRadius: 26)
                                .accessibilityHidden(true)

                            Text(AppLocalizer.string("onboarding.title"))
                                .font(.system(size: 34, weight: .bold, design: .rounded))
                                .dynamicTypeSize(...DynamicTypeSize.accessibility3)

                            Text(AppLocalizer.string("onboarding.subtitle"))
                                .font(.body)
                                .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
                                .dynamicTypeSize(...DynamicTypeSize.accessibility4)
                        }

                        VStack(spacing: 18) {
                            VStack(alignment: .leading, spacing: 10) {
                                Text(AppLocalizer.string("onboarding.name"))
                                    .font(.headline)

                                TextField(AppLocalizer.string("settings.name"), text: $displayName)
                                    .textInputAutocapitalization(.words)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .fill(PremiumTheme.Palette.elevatedSurfaceFill(for: colorScheme))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .strokeBorder(PremiumTheme.Palette.borderColor(for: colorScheme), lineWidth: 1)
                                    )
                                    .accessibilityLabel(Text(AppLocalizer.string("onboarding.name")))
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text(AppLocalizer.string("onboarding.currency"))
                                    .font(.headline)

                                Picker(AppLocalizer.string("settings.currency"), selection: $currencyCode) {
                                    ForEach(CurrencyCatalog.supported) { option in
                                        Text(option.displayName(locale: settings.locale)).tag(option.code)
                                    }
                                }
                                .pickerStyle(.menu)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(PremiumTheme.Palette.elevatedSurfaceFill(for: colorScheme))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(PremiumTheme.Palette.borderColor(for: colorScheme), lineWidth: 1)
                                )
                                .accessibilityLabel(Text(AppLocalizer.string("onboarding.currency")))
                                .accessibilityValue(Text(CurrencyCatalog.supported.first(where: { $0.code == currencyCode })?.displayName(locale: settings.locale) ?? currencyCode))
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text(AppLocalizer.string("onboarding.paycheckDay"))
                                    .font(.headline)

                                HStack {
                                    Text("\(AppLocalizer.string("onboarding.paycheckValue")) \(salaryCycleStartDay)")
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Stepper("", value: $salaryCycleStartDay, in: 1...28)
                                        .labelsHidden()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 14)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(PremiumTheme.Palette.elevatedSurfaceFill(for: colorScheme))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .strokeBorder(PremiumTheme.Palette.borderColor(for: colorScheme), lineWidth: 1)
                                )
                                .accessibilityElement(children: .combine)
                                .accessibilityLabel(Text(AppLocalizer.string("onboarding.paycheckDay")))
                                .accessibilityValue(Text("\(salaryCycleStartDay)"))
                                .accessibilityHint(Text(AppLocalizer.string("onboarding.paycheckStepper.hint")))
                            }

                            VStack(alignment: .leading, spacing: 12) {
                                Toggle(isOn: $wantsPIN) {
                                    Text(AppLocalizer.string("onboarding.enablePIN"))
                                        .font(.subheadline.weight(.semibold))
                                }
                                .onChange(of: wantsPIN) { _, newValue in
                                    validationMessage = nil

                                    if newValue {
                                        showingPINSetup = true
                                    } else {
                                        PINSecurity.removePIN()
                                        hasConfiguredPIN = false
                                    }
                                }
                                .accessibilityHint(Text(AppLocalizer.string("onboarding.pinToggle.hint")))

                                if wantsPIN {
                                    Button {
                                        showingPINSetup = true
                                    } label: {
                                        Label(AppLocalizer.string(hasConfiguredPIN ? "settings.pin.change" : "pin.setupNow"), systemImage: "key.fill")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.plain)
                                    .premiumSecondaryCard(cornerRadius: 18, padding: 14)

                                    Text(hasConfiguredPIN ? AppLocalizer.string("settings.pin.enabled") : AppLocalizer.string("onboarding.pinRequired"))
                                        .font(.caption)
                                        .foregroundStyle(hasConfiguredPIN ? .secondary : PremiumTheme.Palette.warning)
                                }
                            }
                            .premiumSecondaryCard(cornerRadius: 20, padding: 16)
                        }
                        .premiumCard(cornerRadius: 30, padding: 20)

                        if let validationMessage {
                            Text(validationMessage)
                                .font(.footnote)
                                .foregroundStyle(PremiumTheme.Palette.danger)
                        }

                        Button {
                            completeOnboarding()
                        } label: {
                            Text(AppLocalizer.string("onboarding.continue"))
                        }
                        .premiumPrimaryButton()
                        .accessibilityHint(Text(AppLocalizer.string("onboarding.continue.hint")))
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingPINSetup) {
                PINSetupSheet(mode: .create) { pin in
                    let success = PINSecurity.save(pin: pin)
                    if success {
                        hasConfiguredPIN = true
                    }
                    return success
                }
            }
        }
    }

    private func completeOnboarding() {
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            validationMessage = AppLocalizer.string("validation.name")
            return
        }

        if wantsPIN && !hasConfiguredPIN {
            validationMessage = AppLocalizer.string("onboarding.pinRequired")
            return
        }

        if wantsPIN && hasConfiguredPIN {
            appLock.skipNextPrepareLock()
        }

        settings.completeOnboarding(
            displayName: trimmedName,
            currencyCode: currencyCode,
            salaryCycleStartDay: salaryCycleStartDay,
            usePINLock: wantsPIN && hasConfiguredPIN
        )

        validationMessage = nil
    }
}

@MainActor
private struct OnboardingViewPreviewHost: View {
    @StateObject private var settings = SettingsStore(defaults: UserDefaults(suiteName: "OnboardingPreview") ?? .standard)

    var body: some View {
        OnboardingView()
            .environmentObject(settings)
            .environmentObject(AppLockViewModel())
            .modelContainer(PreviewContainer.modelContainer)
    }
}

#Preview {
    OnboardingViewPreviewHost()
}
