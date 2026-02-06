import SwiftUI
import SwiftData

struct RootView: View {
    @Environment(\.modelContext) private var context

    var body: some View {
        TabView {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("账本", systemImage: "list.bullet.rectangle")
            }

            NavigationStack {
                StatsView()
            }
            .tabItem {
                Label("统计", systemImage: "chart.bar.xaxis")
            }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("我的", systemImage: "person.crop.circle")
            }
        }
        .task {
            CategorySeeder.seedIfNeeded(context: context)
        }
    }
}
