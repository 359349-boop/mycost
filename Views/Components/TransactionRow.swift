import SwiftUI

struct TransactionRow: View {
    let transaction: Transaction

    var body: some View {
        let iconName = transaction.category?.iconName ?? "tag"
        let colorHex = transaction.category?.colorHex ?? "#0A84FF"

        return HStack(spacing: 12) {
            CategoryIcon(iconName: iconName, colorHex: colorHex, size: 32, cornerRadius: 10)

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
