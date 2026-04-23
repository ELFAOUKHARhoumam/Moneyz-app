import SwiftUI

@MainActor
struct PINSetupSheet: View {
    enum Mode {
        case create
        case change

        var titleKey: String {
            switch self {
            case .create: return "pin.title.create"
            case .change: return "pin.title.change"
            }
        }

        var buttonKey: String {
            switch self {
            case .create: return "pin.action.save"
            case .change: return "pin.action.update"
            }
        }
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let mode: Mode
    let onSave: (String) -> Bool

    @State private var pin = ""
    @State private var confirmPIN = ""
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                PremiumTheme.PageBackground()
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        PremiumTheme.SectionHeaderView(
                            title: AppLocalizer.string(mode.titleKey),
                            subtitle: AppLocalizer.string("pin.footer")
                        )

                        VStack(spacing: 14) {
                            secureField(title: AppLocalizer.string("pin.new"), text: $pin)
                                .onChange(of: pin) { _, newValue in
                                    pin = String(newValue.filter { $0.isNumber }.prefix(4))
                                    errorMessage = nil
                                }

                            secureField(title: AppLocalizer.string("pin.confirm"), text: $confirmPIN)
                                .onChange(of: confirmPIN) { _, newValue in
                                    confirmPIN = String(newValue.filter { $0.isNumber }.prefix(4))
                                    errorMessage = nil
                                }
                        }
                        .premiumCard(cornerRadius: 28, padding: 18)

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.footnote)
                                .foregroundStyle(PremiumTheme.Palette.danger)
                        }

                        Button {
                            savePIN()
                        } label: {
                            Text(AppLocalizer.string(mode.buttonKey))
                        }
                        .premiumPrimaryButton()
                    }
                    .padding(24)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle(Text(AppLocalizer.string(mode.titleKey)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(AppLocalizer.string("common.cancel")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func secureField(title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))

            SecureField(title, text: text)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
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
        }
    }

    private func savePIN() {
        if let violation = PINSecurity.validateNewPIN(pin) {
            errorMessage = AppLocalizer.string(violation.localizedKey)
            return
        }

        guard confirmPIN.count == 4 else {
            errorMessage = AppLocalizer.string(PINPolicyViolation.invalidLength.localizedKey)
            return
        }

        guard pin == confirmPIN else {
            errorMessage = AppLocalizer.string("pin.validation.match")
            return
        }

        guard onSave(pin) else {
            errorMessage = AppLocalizer.string("pin.saveFailed")
            return
        }

        dismiss()
    }
}
