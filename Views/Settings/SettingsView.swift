import SwiftUI

struct SettingsView: View {
    var body: some View {
        List {
            Section("外观") {
                HStack {
                    Text("主题")
                    Spacer()
                    Text("跟随系统")
                        .foregroundStyle(.secondary)
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
}
