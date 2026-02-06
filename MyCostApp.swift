import SwiftUI
import SwiftData

@main
struct MyCostApp: App {
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
        }
        .modelContainer(sharedModelContainer)
    }
}
