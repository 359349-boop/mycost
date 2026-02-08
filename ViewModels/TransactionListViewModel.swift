import Foundation
import Observation

struct TransactionDaySection: Identifiable {
    let id = UUID()
    let date: Date
    let transactions: [Transaction]
    let netTotal: Decimal
}

@Observable
final class TransactionListViewModel {
    func sections(from transactions: [Transaction]) -> [TransactionDaySection] {
        let grouped = Dictionary(grouping: transactions) { txn in
            Calendar.current.startOfDay(for: txn.date)
        }

        return grouped
            .map { key, value in
                let net = value.reduce(Decimal.zero) { result, txn in
                    let signed = txn.type == "Expense" ? -txn.amount : txn.amount
                    return result + signed
                }
                return TransactionDaySection(date: key, transactions: value, netTotal: net)
            }
            .sorted { $0.date > $1.date }
    }
}
