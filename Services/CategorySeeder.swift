import Foundation
import SwiftData

enum CategorySeeder {
    static func seedIfNeeded(context: ModelContext) {
        let fetch = FetchDescriptor<Category>()
        let count = (try? context.fetchCount(fetch)) ?? 0
        guard count == 0 else { return }

        let expense = [
            ("餐饮", "fork.knife", "#FF9F0A"),
            ("交通", "tram", "#0A84FF"),
            ("购物", "bag", "#FF375F"),
            ("娱乐", "gamecontroller", "#BF5AF2"),
            ("医疗", "cross", "#FF453A"),
            ("居家", "house", "#32D74B"),
            ("教育", "book", "#5E5CE6")
        ]

        let income = [
            ("工资", "banknote", "#32D74B"),
            ("奖金", "gift", "#64D2FF"),
            ("理财收入", "chart.line.uptrend.xyaxis", "#0A84FF"),
            ("其他", "sparkles", "#FF453A")
        ]

        expense.forEach {
            context.insert(Category(name: $0.0, iconName: $0.1, colorHex: $0.2, type: "Expense"))
        }
        income.forEach {
            context.insert(Category(name: $0.0, iconName: $0.1, colorHex: $0.2, type: "Income"))
        }
    }
}
