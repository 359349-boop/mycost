import Foundation
import SwiftData
import SwiftUI
import UIKit

@Model
final class Category {
    @Attribute(.unique) var id: UUID
    var name: String
    var iconName: String
    var colorHex: String
    var type: String
    var sortIndex: Int

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        colorHex: String = "#0A84FF",
        type: String,
        sortIndex: Int = 0
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.type = type
        self.sortIndex = sortIndex
    }
}

extension Category: Identifiable {}
