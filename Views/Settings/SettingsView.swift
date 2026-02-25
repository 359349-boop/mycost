import SwiftUI

struct SettingsView: View {
    @AppStorage("app_theme") private var appThemeRaw: String = AppTheme.system.rawValue
    @EnvironmentObject private var cloudSyncMonitor: CloudSyncMonitor

    var body: some View {
        List {
            Section("外观") {
                NavigationLink {
                    ThemeSelectionView()
                } label: {
                    HStack {
                        Text("主题")
                        Spacer()
                        Text(appTheme.displayName)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("iCloud 同步") {
                ICloudSyncStatusCard(state: cloudSyncMonitor.state) {
                    cloudSyncMonitor.refresh()
                }
            }

            Section("分类管理") {
                NavigationLink("分类管理") {
                    CategoryListView()
                }
            }

            Section("关于") {
                HStack {
                    Text("应用名")
                    Spacer()
                    Text("mycost")
                        .foregroundStyle(.secondary)
                }
                HStack {
                    Text("版本")
                    Spacer()
                    Text("0.1.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("我的")
    }

    private var appTheme: AppTheme {
        AppTheme(rawValue: appThemeRaw) ?? .system
    }
}
