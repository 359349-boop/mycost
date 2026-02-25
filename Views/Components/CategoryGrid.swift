import SwiftUI
import SwiftData

struct CategoryGrid: View {
    let categories: [Category]
    @Binding var selected: Category?
    let onAdd: () -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(minimum: 44), spacing: 12),
        count: 5
    )

    var body: some View {
        let settingsColorHex = categories.first?.colorHex ?? "#8E8E93"
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(categories, id: \.persistentModelID) { category in
                CategoryGridItem(
                    iconName: category.iconName,
                    title: category.name,
                    colorHex: category.colorHex,
                    isSelected: selected?.persistentModelID == category.persistentModelID
                )
                .onTapGesture {
                    selected = category
                }
            }

            CategoryGridItem(
                iconName: "gearshape",
                title: "设置",
                colorHex: settingsColorHex,
                isSelected: false
            )
            .onTapGesture {
                onAdd()
            }
        }
    }
}

struct CategoryGridItem: View {
    let iconName: String
    let title: String
    let colorHex: String
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            CategoryIcon(
                iconName: iconName,
                colorHex: colorHex,
                size: 36,
                cornerRadius: 12,
                selected: isSelected
            )
            Text(title)
                .font(.caption)
                .lineLimit(1)
                .foregroundStyle(.primary)
        }
        .frame(maxWidth: .infinity)
    }
}
