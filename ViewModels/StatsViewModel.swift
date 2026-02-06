import Foundation
import Observation

struct MonthlyBucket: Identifiable {
    let id = UUID()
    let monthStart: Date
    let income: Double
    let expense: Double
}

struct CategoryBucket: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let total: Double
}

struct MonthlySummary {
    let income: Double
    let expense: Double
    let balance: Double
}

@Observable
final class StatsViewModel {
    func monthlyBuckets(from transactions: [Transaction]) -> [MonthlyBucket] {
        let grouped = Dictionary(grouping: transactions) { txn in
            let components = Calendar.current.dateComponents([.year, .month], from: txn.date)
            return Calendar.current.date(from: components) ?? txn.date
        }

        let buckets = grouped.map { key, items in
            let income = items.filter { $0.type == "Income" }
                .reduce(0.0) { $0 + (NSDecimalNumber(decimal: $1.amount).doubleValue) }
            let expense = items.filter { $0.type == "Expense" }
                .reduce(0.0) { $0 + (NSDecimalNumber(decimal: $1.amount).doubleValue) }
            return MonthlyBucket(monthStart: key, income: income, expense: expense)
        }

        return buckets.sorted { $0.monthStart < $1.monthStart }
    }

    func monthlySummary(for date: Date, transactions allTransactions: [Transaction]) -> MonthlySummary {
        let monthTransactions = transactions(inMonthContaining: date, from: allTransactions)
        let expense = monthTransactions
            .filter { $0.type == "Expense" }
            .reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.amount).doubleValue }
        let income = monthTransactions
            .filter { $0.type == "Income" }
            .reduce(0.0) { $0 + NSDecimalNumber(decimal: $1.amount).doubleValue }
        return MonthlySummary(income: income, expense: expense, balance: income - expense)
    }

    func categoryBuckets(for date: Date, from transactions: [Transaction]) -> [CategoryBucket] {
        let monthTransactions = self.transactions(inMonthContaining: date, from: transactions)
        let expenses = monthTransactions.filter { $0.type == "Expense" }
        let grouped = Dictionary(grouping: expenses) {
            $0.category?.name ?? "未分类"
        }

        let buckets = grouped.map { key, items in
            let total = items.reduce(0.0) {
                $0 + NSDecimalNumber(decimal: $1.amount).doubleValue
            }
            let icon = items.first?.category?.iconName ?? "tag"
            return CategoryBucket(name: key, iconName: icon, total: total)
        }

        return buckets.sorted { $0.total > $1.total }
    }

    func topExpenseCategories(for date: Date, from transactions: [Transaction], limit: Int) -> [CategoryBucket] {
        Array(categoryBuckets(for: date, from: transactions).prefix(limit))
    }

    func transactions(inMonthContaining date: Date, from transactions: [Transaction]) -> [Transaction] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return transactions.filter {
            let item = calendar.dateComponents([.year, .month], from: $0.date)
            return item.year == components.year && item.month == components.month
        }
    }
}
