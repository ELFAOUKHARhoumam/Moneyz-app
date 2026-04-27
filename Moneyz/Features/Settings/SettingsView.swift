import SwiftUI
import SwiftData

@MainActor
struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel: SettingsViewModel
    @State private var showingPINSetup = false

    init(
        viewModel: SettingsViewModel? = nil,
        recurringService: RecurringTransactionService? = nil
    ) {
        let resolvedViewModel: SettingsViewModel
        if let viewModel {
            resolvedViewModel = viewModel
        } else {
            let resolvedRecurringService = recurringService ?? RecurringTransactionService()
            resolvedViewModel = SettingsViewModel(
                applyRecurringAction: { context in
                    try resolvedRecurringService.applyDueRules(in: context)
                }
            )
        }
        _viewModel = StateObject(wrappedValue: resolvedViewModel)
    }

    private var pinToggleBinding: Binding<Bool> {
        Binding(
            get: { settings.usePINLock && viewModel.hasStoredPIN },
            set: { newValue in
                if newValue {
                    if viewModel.hasStoredPIN {
                        settings.usePINLock = true
                    } else {
                        showingPINSetup = true
                    }
                } else {
                    viewModel.disablePINLock(settings: settings)
                }
            }
        )
    }

    private var selectedCurrencyName: String {
        CurrencyCatalog.supported.first(where: { $0.code == settings.currencyCode })?.displayName(locale: settings.locale) ?? settings.currencyCode
    }

    var body: some View {
        ZStack {
            PremiumTheme.PageBackground()
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {

                    // MARK: Profile
                    sectionCard(titleKey: "settings.profile") {
                        VStack(spacing: 14) {
                            inputField(
                                title: AppLocalizer.string("settings.name"),
                                text: $settings.displayName,
                                placeholder: AppLocalizer.string("settings.name")
                            )

                            pickerCard(title: AppLocalizer.string("settings.currency")) {
                                ForEach(CurrencyCatalog.supported) { option in
                                    Button {
                                        settings.currencyCode = option.code
                                    } label: {
                                        Text(option.displayName(locale: settings.locale))
                                    }
                                }
                            } summary: {
                                Text(selectedCurrencyName)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }

                            inputField(
                                title: AppLocalizer.string("settings.openingBalance"),
                                text: $viewModel.openingBalanceText,
                                placeholder: AppLocalizer.string("settings.openingBalance"),
                                keyboardType: .decimalPad
                            )

                            // FIX: salary cycle stepper label was duplicated.
                            // Root cause: the VStack label `Text` said "Salary cycle starts on day"
                            // AND the stepper row also prepended the same string, producing:
                            // "Salary cycle starts on day  Salary cycle starts on day 1"
                            // Fix: section label provides context, stepper row shows only the number.
                            VStack(alignment: .leading, spacing: 10) {
                                Text(AppLocalizer.string("settings.salaryCycleStart"))
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))

                                HStack {
                                    // Only show the day number, not the full label again
                                    Text(AppLocalizer.string("onboarding.paycheckValue") + " \(settings.salaryCycleStartDay)")
                                        .font(.subheadline.weight(.medium))

                                    Spacer()

                                    Stepper("", value: $settings.salaryCycleStartDay, in: 1...28)
                                        .labelsHidden()
                                }
                                .premiumSecondaryCard(cornerRadius: PremiumTheme.CornerRadius.sm, padding: 14)
                            }

                            Button(AppLocalizer.string("common.save")) {
                                viewModel.applyOpeningBalance(to: settings)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            }
                            .premiumPrimaryButton()

                            if let saveErrorMessage = viewModel.saveErrorMessage {
                                Text(saveErrorMessage)
                                    .font(.footnote)
                                    .foregroundStyle(PremiumTheme.Palette.danger)
                            }
                        }
                    }

                    // MARK: Appearance
                    sectionCard(titleKey: "settings.appearance") {
                        VStack(spacing: 14) {
                            pickerCard(title: AppLocalizer.string("settings.theme")) {
                                ForEach(SettingsStore.ThemePreference.allCases) { option in
                                    Button {
                                        settings.themePreference = option
                                    } label: {
                                        Text(AppLocalizer.string(option.localizedKey))
                                    }
                                }
                            } summary: {
                                Text(AppLocalizer.string(settings.themePreference.localizedKey))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            pickerCard(title: AppLocalizer.string("settings.language")) {
                                ForEach(SettingsStore.LanguagePreference.allCases) { option in
                                    Button {
                                        settings.languagePreference = option
                                    } label: {
                                        Text(AppLocalizer.string(option.localizedKey))
                                    }
                                }
                            } summary: {
                                Text(AppLocalizer.string(settings.languagePreference.localizedKey))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            // FIX: Dashboard style picker moved from HomeView to Settings.
                            // Root cause: the style toggle consumed permanent space on the home screen,
                            // reducing prime content area. It's a preference, not a daily interaction.
                            pickerCard(title: AppLocalizer.string("dashboard.style.label")) {
                                ForEach(SettingsStore.HomeOverviewStyle.allCases) { style in
                                    Button {
                                        settings.homeOverviewStyle = style
                                    } label: {
                                        Text(AppLocalizer.string(style.localizedKey))
                                    }
                                }
                            } summary: {
                                Text(AppLocalizer.string(settings.homeOverviewStyle.localizedKey))
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    // MARK: Security
                    sectionCard(titleKey: "settings.security") {
                        VStack(spacing: 14) {
                            toggleCard(
                                title: AppLocalizer.string("settings.pin"),
                                subtitle: settings.usePINLock && viewModel.hasStoredPIN
                                    ? AppLocalizer.string("settings.pin.enabled")
                                    : nil,
                                isOn: pinToggleBinding
                            )

                            if settings.usePINLock && viewModel.hasStoredPIN {
                                Button {
                                    showingPINSetup = true
                                } label: {
                                    Label(AppLocalizer.string("settings.pin.change"), systemImage: "key.fill")
                                        .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.plain)
                                .premiumSecondaryCard(cornerRadius: PremiumTheme.CornerRadius.sm, padding: 14)
                            }

                            // FIX: biometricsAvailable now refreshes on appear (see .onAppear below)
                            // Root cause: was computed once at SettingsViewModel.init() time
                            toggleCard(
                                title: AppLocalizer.string("settings.faceID"),
                                subtitle: viewModel.biometricsAvailable
                                    ? nil
                                    : AppLocalizer.string("settings.faceID.unavailable"),
                                isOn: $settings.useFaceIDLock
                            )
                            .disabled(!viewModel.biometricsAvailable)
                        }
                    }

                    // MARK: Sync
                    sectionCard(titleKey: "settings.sync") {
                        VStack(spacing: 14) {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Text(AppLocalizer.string("settings.sync.status"))
                                        .font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Text(AppLocalizer.string(viewModel.syncStatus.titleKey))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.trailing)
                                }

                                if let detail = viewModel.syncStatus.detail {
                                    Text(detail)
                                        .font(.caption)
                                        .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
                                }
                            }
                            .premiumSecondaryCard(cornerRadius: PremiumTheme.CornerRadius.sm, padding: 14)

                            Button {
                                viewModel.refreshSyncStatus()
                            } label: {
                                Label(AppLocalizer.string("settings.sync.refresh"), systemImage: "arrow.clockwise")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.plain)
                            .premiumSecondaryCard(cornerRadius: PremiumTheme.CornerRadius.sm, padding: 14)
                        }
                    }

                    // MARK: Data
                    sectionCard(titleKey: "settings.data") {
                        VStack(alignment: .leading, spacing: 14) {
                            Button {
                                viewModel.applyRecurring(in: modelContext)
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            } label: {
                                Label(AppLocalizer.string("settings.applyRecurring"), systemImage: "repeat.circle.fill")
                            }
                            .premiumPrimaryButton()

                            if let recurringFeedback = viewModel.recurringApplyFeedback {
                                Text(recurringFeedback.message)
                                    .font(.footnote)
                                    .foregroundStyle(
                                        recurringFeedback.isError
                                            ? PremiumTheme.Palette.danger
                                            : PremiumTheme.Palette.mutedText(for: colorScheme)
                                    )
                                    .transition(.opacity)
                            }

                            Text(AppLocalizer.string("settings.data.footer"))
                                .font(.caption)
                                .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(Text(AppLocalizer.string("settings.title")))
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingPINSetup) {
            PINSetupSheet(mode: settings.usePINLock ? .change : .create) { pin in
                viewModel.savePIN(pin, settings: settings)
            }
        }
        .onAppear {
            viewModel.syncOpeningBalance(from: settings)
            viewModel.refreshSyncStatus()
            // FIX: refresh biometrics availability on every appear
            // Root cause: LAContext.canEvaluatePolicy returns current device state —
            // calling it fresh on appear handles the "enabled Face ID while app was open" case
            viewModel.refreshBiometricsAvailability()
        }
        .onChange(of: settings.languagePreference) { _, _ in
            viewModel.syncOpeningBalance(from: settings)
        }
    }

    // MARK: - Private Helpers

    private func sectionCard<Content: View>(titleKey: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(AppLocalizer.string(titleKey))
                .font(.headline.weight(.bold))

            content()
        }
        .premiumCard(cornerRadius: PremiumTheme.CornerRadius.lg, padding: PremiumTheme.Spacing.md)
    }

    private func inputField(
        title: String,
        text: Binding<String>,
        placeholder: String,
        keyboardType: UIKeyboardType = .default
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))

            TextField(placeholder, text: text)
                .keyboardType(keyboardType)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: PremiumTheme.CornerRadius.sm, style: .continuous)
                        .fill(PremiumTheme.Palette.elevatedSurfaceFill(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: PremiumTheme.CornerRadius.sm, style: .continuous)
                        .strokeBorder(PremiumTheme.Palette.borderColor(for: colorScheme), lineWidth: 1)
                )
        }
    }

    private func pickerCard<Content: View, Summary: View>(
        title: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder summary: () -> Summary
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))

            Menu {
                content()
            } label: {
                HStack {
                    summary()
                    Spacer(minLength: 12)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: PremiumTheme.CornerRadius.sm, style: .continuous)
                        .fill(PremiumTheme.Palette.elevatedSurfaceFill(for: colorScheme))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: PremiumTheme.CornerRadius.sm, style: .continuous)
                        .strokeBorder(PremiumTheme.Palette.borderColor(for: colorScheme), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
        }
    }

    private func toggleCard(title: String, subtitle: String?, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))

                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 12)

            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .premiumSecondaryCard(cornerRadius: PremiumTheme.CornerRadius.sm, padding: 14)
    }
}
