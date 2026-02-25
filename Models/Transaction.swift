import Foundation
import SwiftData

@Model
final class Transaction {
    var id: UUID = UUID()
    var amount: Decimal = 0
    var type: String = "Expense"
    var date: Date = Date()
    var note: String?
    var createdAt: Date = Date()
    var updatedAt: Date = Date()

    @Relationship(inverse: \Category.transactions) var category: Category?

    init(
        id: UUID = UUID(),
        amount: Decimal,
        type: String,
        date: Date = Date(),
        note: String? = nil,
        category: Category? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
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
