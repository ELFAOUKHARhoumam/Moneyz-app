import SwiftUI
import SwiftData

@main
@MainActor
struct MoneyzApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var appLock = AppLockViewModel()
    @StateObject private var bootstrapCoordinator = AppBootstrapCoordinator()
    @StateObject private var persistenceController = PersistenceController.shared

    init() {
        PremiumTheme.configureUIKitAppearance()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = persistenceController.container {
                    Group {
                        if settings.hasCompletedOnboarding {
                            RootTabView(bootstrapCoordinator: bootstrapCoordinator)
                        } else {
                            OnboardingView()
                        }
                    }
                    .modelContainer(container)
                } else {
                    PersistenceErrorView(
                        status: persistenceController.bootstrapStatus,
                        retryAction: persistenceController.retryBootstrap
                    )
                }
            }
            .environmentObject(settings)
            .environmentObject(appLock)
            .preferredColorScheme(settings.preferredColorScheme)
            .environment(\.locale, settings.locale)
            .environment(\.layoutDirection, settings.layoutDirection)
            .id(settings.interfaceRefreshID)
            .tint(PremiumTheme.Palette.accent)
            .premiumPageBackground()
            .overlay(alignment: .top) {
                if persistenceController.container != nil,
                   case .degraded = persistenceController.bootstrapStatus {
                    PersistenceStatusBannerView(status: persistenceController.bootstrapStatus)
                        .padding(.top, 10)
                        .padding(.horizontal, 16)
                }
            }
        }
    }
}
