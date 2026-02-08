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
    @State private var showingDatePicker = false
    @State private var dateDismissTask: Task<Void, Never>?
    @State private var isEditingNote = false
    @FocusState private var noteFocused: Bool

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
            .navigationTitle("")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("取消") { dismiss() }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if !showingDatePicker && !isEditingNote {
                    CalculatorPad(
                        expression: $amountExpression,
                        isCompleteEnabled: amountValue != nil,
                        onComplete: save
                    )
                }
            }
            .onChange(of: type) { _, newValue in
                if selectedCategory?.type != newValue {
                    selectedCategory = nil
                }
            }
            .onChange(of: showingDatePicker) { _, newValue in
                if !newValue {
                    dateDismissTask?.cancel()
                    dateDismissTask = nil
                }
            }
            .onChange(of: date) { _, _ in
                guard showingDatePicker else { return }
                scheduleDatePickerDismiss()
            }
            .onChange(of: noteFocused) { _, focused in
                if !focused && isEditingNote {
                    isEditingNote = false
                }
            }
            .sheet(isPresented: $showingCategoryManager) {
                NavigationStack {
                    CategoryListView()
                }
            }
            .sheet(isPresented: $showingDatePicker) {
                VStack {
                    DatePicker(
                        "",
                        selection: $date,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .labelsHidden()
                    .padding()
                }
                .presentationDetents([.height(360)])
            }
        }
    }

    private var formContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                GroupBox {
                    HStack(spacing: 12) {
                        Button {
                            showingDatePicker = true
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                Text(formattedMonthDay)
                            }
                            .font(.subheadline)
                            .padding(.vertical, 6)
                            .padding(.horizontal, 10)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)

                        Spacer(minLength: 8)

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
                    EmptyView()
                }

                GroupBox {
                    amountDisplay
                } label: {
                    EmptyView()
                }
            }
            .padding()
            .padding(.bottom, 120)
        }
    }

    private var amountDisplay: some View {
        VStack(alignment: .leading, spacing: 4) {
            VStack(alignment: .leading, spacing: 4) {
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
            .padding(.top, 4)
            .padding(.bottom, 0)

            Divider()
                .padding(.top, 1)

            noteRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var noteRow: some View {
        Group {
            if isEditingNote {
                TextField("备注", text: $note)
                    .font(.footnote)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 8)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .focused($noteFocused)
                    .submitLabel(.done)
                    .onSubmit { finishNoteEditing() }
                    .onAppear { noteFocused = true }
            } else {
                Button {
                    beginNoteEditing()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "note.text")
                            .font(.caption2)
                            .padding(4)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Capsule())
                            .foregroundStyle(.secondary)

                        if !note.isEmpty {
                            Text(note)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 2)
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

    private var formattedMonthDay: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter.string(from: date)
    }

    private func scheduleDatePickerDismiss() {
        dateDismissTask?.cancel()
        dateDismissTask = Task { [showingDatePicker] in
            guard showingDatePicker else { return }
            try? await Task.sleep(nanoseconds: 500_000_000)
            if !Task.isCancelled {
                await MainActor.run {
                    self.showingDatePicker = false
                }
            }
        }
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

    private func beginNoteEditing() {
        isEditingNote = true
        noteFocused = true
    }

    private func finishNoteEditing() {
        noteFocused = false
        isEditingNote = false
    }
}
