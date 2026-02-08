import SwiftUI

struct CategoryGrid: View {
    let categories: [Category]
    @Binding var selected: Category?
    let onAdd: () -> Void

    private let columns = [
        GridItem(.adaptive(minimum: 72), spacing: 12)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(categories, id: \.id) { category in
                CategoryGridItem(
                    iconName: category.iconName,
                    title: category.name,
                    colorHex: category.colorHex,
                    isSelected: selected?.id == category.id
                )
                .onTapGesture {
                    selected = category
                }
            }

            CategoryGridItem(
                iconName: "plus",
                title: "添加",
                colorHex: "#0A84FF",
                isSelected: true
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
