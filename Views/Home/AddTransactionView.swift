import SwiftUI
import SwiftData
import UIKit

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \Category.name) private var categories: [Category]

    private let transaction: Transaction?

    @State private var type: String
    @State private var amountText: String
    @State private var selectedCategory: Category?
    @State private var date: Date
    @State private var note: String

    init(transaction: Transaction? = nil) {
        self.transaction = transaction

        let amountString: String
        if let txn = transaction {
            amountString = NSDecimalNumber(decimal: txn.amount).stringValue
        } else {
            amountString = ""
        }

        _type = State(initialValue: transaction?.type ?? "Expense")
        _amountText = State(initialValue: amountString)
        _selectedCategory = State(initialValue: transaction?.category)
        _date = State(initialValue: transaction?.date ?? .now)
        _note = State(initialValue: transaction?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("类型") {
                    Picker("类型", selection: $type) {
                        Text("支出").tag("Expense")
                        Text("收入").tag("Income")
                    }
                    .pickerStyle(.segmented)
                }

                Section("金额") {
                    TextField("0", text: $amountText)
                        .keyboardType(.decimalPad)
                }

                Section("分类") {
                    Picker("分类", selection: $selectedCategory) {
                        Text("未分类").tag(Category?.none)
                        ForEach(filteredCategories, id: \.id) { category in
                            Text(category.name).tag(Category?.some(category))
                        }
                    }
                }

                Section("日期") {
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }

                Section("备注") {
                    TextField("可选", text: $note)
                }
            }
            .navigationTitle(transaction == nil ? "记一笔" : "编辑账目")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") { save() }
                        .disabled(!canSave)
                }
            }
            .onChange(of: type) { _, newValue in
                if selectedCategory?.type != newValue {
                    selectedCategory = nil
                }
            }
        }
    }

    private var filteredCategories: [Category] {
        categories.filter { $0.type == type }
    }

    private var canSave: Bool {
        Decimal(string: amountText) != nil
    }

    private func save() {
        guard let amount = Decimal(string: amountText) else { return }

        if let txn = transaction {
            txn.amount = amount
            txn.type = type
            txn.date = date
            txn.note = note.isEmpty ? nil : note
            txn.category = selectedCategory
            txn.updatedAt = .now
        } else {
            let txn = Transaction(
                amount: amount,
                type: type,
                date: date,
                note: note.isEmpty ? nil : note,
                category: selectedCategory
            )
            context.insert(txn)
        }

        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }
}
