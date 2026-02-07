import SwiftUI
import SwiftData
import UIKit

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \Category.name) private var categories: [Category]

    private let transaction: Transaction?

    @State private var type: String
    @State private var amountExpression: String
    @State private var selectedCategory: Category?
    @State private var date: Date
    @State private var note: String

    @State private var showingCategoryManager = false

    init(transaction: Transaction? = nil) {
        self.transaction = transaction

        let amountString: String
        if let txn = transaction {
            amountString = NSDecimalNumber(decimal: txn.amount).stringValue
        } else {
            amountString = ""
        }

        _type = State(initialValue: transaction?.type ?? "Expense")
        _amountExpression = State(initialValue: amountString)
        _selectedCategory = State(initialValue: transaction?.category)
        _date = State(initialValue: transaction?.date ?? .now)
        _note = State(initialValue: transaction?.note ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                formContent
            }
            .navigationTitle(transaction == nil ? "记一笔" : "编辑账目")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                CalculatorPad(
                    expression: $amountExpression,
                    isCompleteEnabled: amountValue != nil,
                    onComplete: save
                )
            }
            .onChange(of: type) { _, newValue in
                if selectedCategory?.type != newValue {
                    selectedCategory = nil
                }
            }
            .sheet(isPresented: $showingCategoryManager) {
                NavigationStack {
                    CategoryListView()
                }
            }
        }
    }

    private var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                amountDisplay

                GroupBox {
                    HStack(spacing: 12) {
                        Text("类型")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Picker("类型", selection: $type) {
                            Text("支出").tag("Expense")
                            Text("收入").tag("Income")
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 140)
                    }

                    Divider()

                    categorySection
                        .frame(maxHeight: 240)
                } label: {
                    Text("分类")
                }

                GroupBox {
                    DatePicker("日期", selection: $date, displayedComponents: .date)
                }

                GroupBox {
                    TextField("备注（可选）", text: $note)
                }
            }
            .padding()
            .padding(.bottom, 120)
        }
    }

    private var amountDisplay: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(displayExpression)
                .font(.largeTitle)
                .fontWeight(.semibold)
                .monospacedDigit()
            if let value = amountValue {
                Text(format(currency: value))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var categorySection: some View {
        ScrollView {
            CategoryGrid(
                categories: filteredCategories,
                selected: $selectedCategory,
                onAdd: { showingCategoryManager = true }
            )
        }
    }

    private var filteredCategories: [Category] {
        categories.filter { $0.type == type }
    }

    private var displayExpression: String {
        amountExpression.isEmpty ? "0" : amountExpression
    }

    private var amountValue: Double? {
        CalculatorEngine.evaluate(amountExpression)
    }

    private func save() {
        guard let value = amountValue else { return }
        let amount = Decimal(value)

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

    private func format(currency value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "¥0"
    }
}
