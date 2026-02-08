import SwiftUI

struct CategoryIcon: View {
    let iconName: String
    let colorHex: String
    let size: CGFloat
    let cornerRadius: CGFloat
    let selected: Bool

    init(
        iconName: String,
        colorHex: String,
        size: CGFloat = 36,
        cornerRadius: CGFloat = 12,
        selected: Bool = true
    ) {
        self.iconName = iconName
        self.colorHex = colorHex
        self.size = size
        self.cornerRadius = cornerRadius
        self.selected = selected
    }

    var body: some View {
        let color = Color(hex: colorHex)
        let bgColor = selected ? color : Color(.secondarySystemBackground)
        let iconColor = selected ? Color.white : Color.secondary

        Image(systemName: iconName)
            .foregroundStyle(iconColor)
            .frame(width: size, height: size)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(selected ? Color.clear : Color(.tertiarySystemFill), lineWidth: 1)
            )
    }
}
