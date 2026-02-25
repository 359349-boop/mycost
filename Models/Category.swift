import Foundation
import SwiftData
import SwiftUI
import UIKit

@Model
final class Category {
    var id: UUID = UUID()
    var name: String = ""
    var iconName: String = "tag"
    var colorHex: String = "#0A84FF"
    var type: String = "Expense"
    var sortIndex: Int = 0
    var transactions: [Transaction]?

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
