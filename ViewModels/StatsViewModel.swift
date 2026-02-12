import Foundation
import Observation

struct MonthlyBucket: Identifiable {
    let id = UUID()
    let monthStart: Date
    let income: Double
    let expense: Double
}

struct YearlyBucket: Identifiable {
    let id = UUID()
    let yearStart: Date
    let income: Double
    let expense: Double
}

struct CategoryBucket: Identifiable {
    let id = UUID()
    let name: String
    let iconName: String
    let colorHex: String
    let total: Double
    let count: Int
}

struct MonthlySummary {
    let income: Double
    let expense: Double
    let balance: Double
}

@Observable
final class StatsViewModel {
    func monthStart(for date: Date) -> Date {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? date
    }

    func recentMonths(from date: Date, count: Int) -> [Date] {
        let calendar = Calendar.current
        let start = monthStart(for: date)
        return (0..<count).compactMap { offset in
            calendar.date(byAdding: .month, value: offset - (count - 1), to: start)
        }
    }

    func monthSeries(from start: Date, to end: Date) -> [Date] {
        let calendar = Calendar.current
        let startMonth = monthStart(for: start)
        let endMonth = monthStart(for: end)
        guard startMonth <= endMonth else { return [endMonth] }
        var months: [Date] = []
        var cursor = startMonth
        while cursor <= endMonth {
            months.append(cursor)
            guard let next = calendar.date(byAdding: .month, value: 1, to: cursor) else { break }
            cursor = next
        }
        return months
    }

    func earliestMonthStart(from transactions: [Transaction], fallback: Date) -> Date {
        guard let minDate = transactions.map(\.date).min() else { return monthStart(for: fallback) }
        let earliest = monthStart(for: minDate)
        let fallbackMonth = monthStart(for: fallback)
        return earliest > fallbackMonth ? fallbackMonth : earliest
    }

    func recentYears(from date: Date, count: Int) -> [Date] {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year], from: date)
        let start = calendar.date(from: comps) ?? date
        return (0..<count).compactMap { offset in
            calendar.date(byAdding: .year, value: offset - (count - 1), to: start)
        }
    }

    func monthlyBuckets(for months: [Date], transactions allTransactions: [Transaction]) -> [MonthlyBucket] {
        months.map { month in
            let items = transactionsInPeriod(containing: month, granularity: .month, from: allTransactions)
            let income = items.filter { $0.type == "Income" }.reduce(0.0) { $0 + amount($1) }
            let expense = items.filter { $0.type == "Expense" }.reduce(0.0) { $0 + amount($1) }
            return MonthlyBucket(monthStart: month, income: income, expense: expense)
        }
    }


    func yearlyBuckets(for years: [Date], transactions allTransactions: [Transaction]) -> [YearlyBucket] {
        years.map { year in
            let items = transactionsInPeriod(containing: year, granularity: .year, from: allTransactions)
            let income = items.filter { $0.type == "Income" }.reduce(0.0) { $0 + amount($1) }
            let expense = items.filter { $0.type == "Expense" }.reduce(0.0) { $0 + amount($1) }
            return YearlyBucket(yearStart: year, income: income, expense: expense)
        }
    }

    func monthlySummary(for date: Date, transactions allTransactions: [Transaction]) -> MonthlySummary {
        let monthTransactions = transactionsInPeriod(containing: date, granularity: .month, from: allTransactions)
        let expense = monthTransactions.filter { $0.type == "Expense" }.reduce(0.0) { $0 + amount($1) }
        let income = monthTransactions.filter { $0.type == "Income" }.reduce(0.0) { $0 + amount($1) }
        return MonthlySummary(income: income, expense: expense, balance: income - expense)
    }

    func categoryBuckets(
        for date: Date,
        granularity: Calendar.Component,
        from transactions: [Transaction],
        type: String
    ) -> [CategoryBucket] {
        let periodTransactions = transactionsInPeriod(containing: date, granularity: granularity, from: transactions)
        let scoped = periodTransactions.filter { $0.type == type }
        let grouped = Dictionary(grouping: scoped) { txn in
            txn.category?.name ?? "未分类"
        }

        let buckets = grouped.map { key, items in
            let total = items.reduce(0.0) { result, txn in
                let value = amount(txn)
                let signed = type == "Expense" ? -value : value
                return result + signed
            }
            let icon = items.first?.category?.iconName ?? "tag"
            let colorHex = items.first?.category?.colorHex ?? "#0A84FF"
            return CategoryBucket(name: key, iconName: icon, colorHex: colorHex, total: total, count: items.count)
        }

        return buckets.sorted { abs($0.total) > abs($1.total) }
    }

    func transactionsInPeriod(containing date: Date, granularity: Calendar.Component, from transactions: [Transaction]) -> [Transaction] {
        let calendar = Calendar.current
        return transactions.filter { calendar.isDate($0.date, equalTo: date, toGranularity: granularity) }
    }

    private func amount(_ transaction: Transaction) -> Double {
        NSDecimalNumber(decimal: transaction.amount).doubleValue
    }
}
