import Foundation
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var amount: Decimal
    var type: String
    var date: Date
    var note: String?
    var createdAt: Date
    var updatedAt: Date

    @Relationship var category: Category?

    init(
        id: UUID = UUID(),
        amount: Decimal,
        type: String,
        date: Date = .now,
        note: String? = nil,
        category: Category? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.amount = amount
        self.type = type
        self.date = date
        self.note = note
        self.category = category
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

extension Transaction: Identifiable {}
