import SwiftUI

struct ThemeSelectionView: View {
    @AppStorage("app_theme") private var appThemeRaw: String = AppTheme.system.rawValue

    private var selected: AppTheme {
        AppTheme(rawValue: appThemeRaw) ?? .system
    }

    var body: some View {
        List {
            Section {
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        appThemeRaw = theme.rawValue
                    } label: {
                        HStack {
                            Text(theme.displayName)
                            Spacer()
                            if theme == selected {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .navigationTitle("主题")
    }
}

