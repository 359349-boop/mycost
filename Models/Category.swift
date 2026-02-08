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

    init(
        id: UUID = UUID(),
        name: String,
        iconName: String,
        colorHex: String = "#0A84FF",
        type: String
    ) {
        self.id = id
        self.name = name
        self.iconName = iconName
        self.colorHex = colorHex
        self.type = type
    }
}

extension Category: Identifiable {}
