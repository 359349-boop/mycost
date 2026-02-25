import SwiftUI
import SwiftData
import UIKit

@main
struct MyCostApp: App {
    private struct ModelContainerBootstrap {
        let container: ModelContainer
        let isCloudKitStoreEnabled: Bool
        let startupErrorMessage: String?
    }

    @AppStorage("app_theme") private var appThemeRaw: String = AppTheme.system.rawValue
    @StateObject private var cloudSyncMonitor: CloudSyncMonitor
    private let sharedModelContainer: ModelContainer

    init() {
        let bootstrap = Self.makeModelContainerBootstrap()
        sharedModelContainer = bootstrap.container
        _cloudSyncMonitor = StateObject(
            wrappedValue: CloudSyncMonitor(
                isCloudKitStoreEnabled: bootstrap.isCloudKitStoreEnabled,
                startupErrorMessage: bootstrap.startupErrorMessage
            )
        )
    }

    private static func makeModelContainerBootstrap() -> ModelContainerBootstrap {
        let schema = Schema([Transaction.self, Category.self])

#if DEBUG
        if Bundle.main.bundleIdentifier != CloudSyncConfig.bundleIdentifier {
            print(
                "Bundle ID mismatch. Expected: \(CloudSyncConfig.bundleIdentifier), actual: \(Bundle.main.bundleIdentifier ?? "nil")"
            )
        }
#endif

        let cloudConfig = ModelConfiguration(
            "Cloud",
            schema: schema,
            isStoredInMemoryOnly: false,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .private(CloudSyncConfig.cloudKitContainerIdentifier)
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [cloudConfig])
            return ModelContainerBootstrap(
                container: container,
                isCloudKitStoreEnabled: true,
                startupErrorMessage: nil
            )
        } catch let cloudError {
            // Keep the app usable even when iCloud is unavailable.
            print("CloudKit ModelContainer failed, falling back to local: \(cloudError)")

            let localConfig = ModelConfiguration(
                "LocalDisk",
                schema: schema,
                isStoredInMemoryOnly: false,
                allowsSave: true,
                groupContainer: .none,
                cloudKitDatabase: .none
            )
            do {
                let localContainer = try ModelContainer(for: schema, configurations: [localConfig])
                return ModelContainerBootstrap(
                    container: localContainer,
                    isCloudKitStoreEnabled: false,
                    startupErrorMessage: cloudError.localizedDescription
                )
            } catch let localError {
                print("Local ModelContainer failed, falling back to in-memory: \(localError)")

                let inMemoryConfig = ModelConfiguration(
                    "LocalMemory",
                    schema: schema,
                    isStoredInMemoryOnly: true,
                    allowsSave: true,
                    groupContainer: .none,
                    cloudKitDatabase: .none
                )
                do {
                    let memoryContainer = try ModelContainer(for: schema, configurations: [inMemoryConfig])
                    return ModelContainerBootstrap(
                        container: memoryContainer,
                        isCloudKitStoreEnabled: false,
                        startupErrorMessage:
                            "CloudKit: \(cloudError.localizedDescription)\nLocal: \(localError.localizedDescription)"
                    )
                } catch let memoryError {
                    fatalError(
                        """
                        Failed to initialize any ModelContainer.
                        CloudKit: \(cloudError)
                        Local: \(localError)
                        InMemory: \(memoryError)
                        """
                    )
                }
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(appTheme.colorScheme)
                .onAppear { configureTabBarAppearance() }
                .environmentObject(cloudSyncMonitor)
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
