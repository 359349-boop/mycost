import SwiftUI
import SwiftData

@main
struct MyCostApp: App {
    @AppStorage("app_theme") private var appThemeRaw: String = AppTheme.system.rawValue

    private var sharedModelContainer: ModelContainer = {
        let schema = Schema([Transaction.self, Category.self])

        let cloudConfig = ModelConfiguration(
            cloudKitDatabase: .private("iCloud.com.yourname.ledger")
        )

        do {
            return try ModelContainer(for: schema, configurations: [cloudConfig])
        } catch {
            // If CloudKit isn't configured correctly, fall back to local storage
            print("CloudKit ModelContainer failed, falling back to local: \(error)")
            let localConfig = ModelConfiguration()
            return try! ModelContainer(for: schema, configurations: [localConfig])
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(appTheme.colorScheme)
                .onAppear { configureTabBarAppearance() }
        }
        .modelContainer(sharedModelContainer)
    }

    private var appTheme: AppTheme {
        AppTheme(rawValue: appThemeRaw) ?? .system
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.systemBackground
        appearance.stackedLayoutAppearance.normal.iconColor = .secondaryLabel
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.secondaryLabel
        ]
        appearance.stackedLayoutAppearance.selected.iconColor = .label
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.label
        ]
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
