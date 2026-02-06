import Foundation
import Observation

struct TransactionDaySection: Identifiable {
    let id = UUID()
    let date: Date
    let transactions: [Transaction]
}

@Observable
final class TransactionListViewModel {
    func sections(from transactions: [Transaction]) -> [TransactionDaySection] {
        let grouped = Dictionary(grouping: transactions) { txn in
            Calendar.current.startOfDay(for: txn.date)
        }

        return grouped
            .map { TransactionDaySection(date: $0.key, transactions: $0.value) }
            .sorted { $0.date > $1.date }
    }
}
