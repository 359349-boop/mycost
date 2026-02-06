import Foundation
import SwiftData

enum CategorySeeder {
    static func seedIfNeeded(context: ModelContext) {
        let fetch = FetchDescriptor<Category>()
        let count = (try? context.fetchCount(fetch)) ?? 0
        guard count == 0 else { return }

        let expense = [
            ("餐饮", "fork.knife"),
            ("交通", "tram"),
            ("购物", "bag"),
            ("娱乐", "gamecontroller"),
            ("医疗", "cross"),
            ("居家", "house"),
            ("教育", "book")
        ]

        let income = [
            ("工资", "banknote"),
            ("奖金", "gift"),
            ("理财收入", "chart.line.uptrend.xyaxis"),
            ("其他", "sparkles")
        ]

        expense.forEach {
            context.insert(Category(name: $0.0, iconName: $0.1, type: "Expense"))
        }
        income.forEach {
            context.insert(Category(name: $0.0, iconName: $0.1, type: "Income"))
        }
    }
}
