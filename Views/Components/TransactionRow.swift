import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: transaction.category?.iconName ?? "tag")
                .frame(width: 28, height: 28)
                .background(Color(.secondarySystemBackground))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category?.name ?? "未分类")
                    .font(.headline)
                if let note = transaction.note, !note.isEmpty {
                    Text(note)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(amountText)
                .font(.headline)
                .foregroundStyle(transaction.type == "Expense" ? .primary : .primary)
        }
        .padding(.vertical, 4)
    }

    private var amountText: String {
        let number = NSDecimalNumber(decimal: transaction.amount)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: number) ?? "¥0"
    }
}
