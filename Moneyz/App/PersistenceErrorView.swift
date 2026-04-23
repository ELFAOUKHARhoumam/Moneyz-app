import SwiftUI

@MainActor
struct PersistenceErrorView: View {
    let status: PersistenceController.BootstrapStatus
    let retryAction: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var failureReason: PersistenceController.FailureReason? {
        if case .failed(let reason, _) = status {
            return reason
        }
        return nil
    }

    private var details: String? {
        if case .failed(_, let details) = status {
            return details
        }
        return nil
    }

    private var messageKey: String {
        switch failureReason {
        case .cloudKitConfiguration:
            return "persistence.failed.cloudKitConfiguration"
        case .cloudKitRuntime:
            return "persistence.failed.cloudKitRuntime"
        case .localStoreCorrupted:
            return "persistence.failed.localStoreCorrupted"
        case .migrationFailure:
            return "persistence.failed.migrationFailure"
        case .localStoreUnavailable:
            return "persistence.failed.localStoreUnavailable"
        case .unknown, .none:
            return "persistence.failed.unknown"
        }
    }

    var body: some View {
        ZStack {
            PremiumTheme.PageBackground()
                .ignoresSafeArea()

            VStack(spacing: 18) {
                PremiumTheme.IconBadge(
                    systemImage: "externaldrive.badge.exclamationmark",
                    colors: [PremiumTheme.Palette.danger, PremiumTheme.Palette.warning],
                    size: 64,
                    symbolSize: 24
                )

                Text(AppLocalizer.string("persistence.failed.title"))
                    .font(.system(size: 30, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text(AppLocalizer.string(messageKey))
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(PremiumTheme.Palette.mutedText(for: colorScheme))

                if let details, !details.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(AppLocalizer.string("persistence.details.title"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Text(details)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .premiumSecondaryCard(cornerRadius: 18, padding: 14)
                }

                Button(AppLocalizer.string("persistence.failed.retry")) {
                    retryAction()
                }
                .premiumPrimaryButton()
                .accessibilityIdentifier("persistence.retry.button")
            }
            .padding(24)
            .premiumCard(cornerRadius: 30, padding: 22)
            .padding(.horizontal, 20)
            .accessibilityIdentifier("persistence.error.view")
        }
    }
}

@MainActor
struct PersistenceStatusBannerView: View {
    let status: PersistenceController.BootstrapStatus

    private var bannerText: String? {
        guard case .degraded(let fallback, _, _) = status else {
            return nil
        }

        switch fallback {
        case .localOnly:
            return AppLocalizer.string("persistence.banner.localOnly")
        case .inMemory:
            return AppLocalizer.string("persistence.banner.inMemory")
        }
    }

    var body: some View {
        if let bannerText {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(PremiumTheme.Palette.warning)

                Text(bannerText)
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .accessibilityIdentifier("persistence.status.banner")
            .accessibilityElement(children: .combine)
        }
    }
}