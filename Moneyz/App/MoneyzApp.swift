import SwiftUI
import SwiftData

@main
@MainActor
struct MoneyzApp: App {
    @StateObject private var settings = SettingsStore()
    @StateObject private var appLock = AppLockViewModel()
    @StateObject private var bootstrapCoordinator = AppBootstrapCoordinator()

    private let container: ModelContainer

    init() {
        PremiumTheme.configureUIKitAppearance()
        container = PersistenceController.shared.container
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if settings.hasCompletedOnboarding {
                    RootTabView(bootstrapCoordinator: bootstrapCoordinator)
                } else {
                    OnboardingView()
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
            .modelContainer(container)
        }
    }
}
