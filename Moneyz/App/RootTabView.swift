import SwiftUI
import SwiftData

// MARK: - RootTabView
// Updated to wire the onShowAllTransactions callback from HomeView → Transactions tab.
// This avoids NavigationLink-in-ScrollView push issues while keeping HomeView tab-agnostic.

@MainActor
struct RootTabView: View {
    enum AppTab: String, Hashable {
        case home
        case transactions
        case budget
        case debt
        case settings
    }

    @EnvironmentObject private var settings: SettingsStore
    @EnvironmentObject private var appLock: AppLockViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext

    @SceneStorage("root.selectedTab") private var selectedTabRawValue: String = AppTab.home.rawValue
    @ObservedObject var bootstrapCoordinator: AppBootstrapCoordinator

    private var selectedTab: Binding<AppTab> {
        Binding(
            get: { AppTab(rawValue: selectedTabRawValue) ?? .home },
            set: { selectedTabRawValue = $0.rawValue }
        )
    }

    var body: some View {
        ZStack {
            PremiumTheme.PageBackground()
                .ignoresSafeArea()

            TabView(selection: selectedTab) {
                // Home tab — receives the callback to switch to Transactions
                NavigationStack {
                    HomeView(onShowAllTransactions: {
                        selectedTabRawValue = AppTab.transactions.rawValue
                    })
                }
                .tag(AppTab.home)
                .tabItem {
                    Label {
                        Text(AppLocalizer.string("tab.home"))
                    } icon: {
                        Image(systemName: "house.fill")
                    }
                }

                NavigationStack {
                    TransactionsView()
                }
                .tag(AppTab.transactions)
                .tabItem {
                    Label {
                        Text(AppLocalizer.string("tab.transactions"))
                    } icon: {
                        Image(systemName: "list.bullet.rectangle")
                    }
                }

                NavigationStack {
                    BudgetView()
                }
                .tag(AppTab.budget)
                .tabItem {
                    Label {
                        Text(AppLocalizer.string("tab.budget"))
                    } icon: {
                        Image(systemName: "chart.bar.xaxis")
                    }
                }

                NavigationStack {
                    DebtView()
                }
                .tag(AppTab.debt)
                .tabItem {
                    Label {
                        Text(AppLocalizer.string("tab.debt"))
                    } icon: {
                        Image(systemName: "creditcard.fill")
                    }
                }

                NavigationStack {
                    SettingsView()
                }
                .tag(AppTab.settings)
                .tabItem {
                    Label {
                        Text(AppLocalizer.string("tab.settings"))
                    } icon: {
                        Image(systemName: "gearshape.fill")
                    }
                }
            }
        }
        .task {
            bootstrapCoordinator.bootstrapIfNeeded(in: modelContext, settings: settings, appLock: appLock)
        }
        .onChange(of: scenePhase) { _, newPhase in
            bootstrapCoordinator.handleScenePhase(newPhase, context: modelContext, settings: settings, appLock: appLock)
        }
        .overlay {
            if appLock.isLocked {
                LockScreenView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
    }
}
