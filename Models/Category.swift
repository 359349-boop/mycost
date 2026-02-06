import Foundation
import SwiftData

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var colorName: String
    var type: String

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        colorName: String = "AccentColor",
        type: String
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorName = colorName
        self.type = type
    }
}

extension Category: Identifiable {}
