import SwiftUI
import SwiftData
import UIKit

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    @Query(sort: \Category.sortIndex) private var categories: [Category]

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
    @State private var showingDeleteConfirm = false
    @FocusState private var noteFocused: Bool
    @State private var amountContainerWidth: CGFloat = 0
    @State private var digitWidth: CGFloat = 0

    private let amountScrollId = "amountScrollId"
    private let amountResultMaxWidth: CGFloat = 140

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
                ToolbarItem(placement: .topBarTrailing) {
                    if transaction != nil {
                        Button {
                            showingDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.body)
                                .imageScale(.medium)
                        }
                        .foregroundStyle(.red)
                    }
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
                ensureDefaultSelection()
            }
            .onChange(of: categories.count) { _, _ in
                ensureDefaultSelection()
            }
            .onAppear {
                ensureDefaultSelection()
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
            .alert("删除这笔记录？", isPresented: $showingDeleteConfirm) {
                Button("删除", role: .destructive) { deleteTransaction() }
                Button("取消", role: .cancel) {}
            } message: {
                Text("此操作无法撤销。")
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
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 10) {
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
                .groupBoxStyle(
                    TightGroupBoxStyle(
                        insets: EdgeInsets(top: 5, leading: 16, bottom: 6, trailing: 16)
                    )
                )
            }
            .padding()
            .padding(.bottom, 120)
        }
        .scrollIndicators(.hidden)
    }

    private var amountDisplay: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Spacer(minLength: 8)
                amountExpressionLine
            }

            Divider()
                .padding(.top, 1)

            HStack(alignment: .center, spacing: 12) {
                noteInlineView
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text(format(currency: amountValue ?? 0))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.head)
                    .frame(maxWidth: amountResultMaxWidth, alignment: .trailing)
                    .multilineTextAlignment(.trailing)
                    .opacity(amountValue == nil ? 0 : 1)
                    .accessibilityHidden(amountValue == nil)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var amountExpressionLine: some View {
        ViewThatFits(in: .horizontal) {
            Text(displayExpression)
                .font(.largeTitle)
                .fontWeight(.semibold)
                .monospacedDigit()
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
                .frame(maxWidth: .infinity, alignment: .trailing)

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    Text(displayExpression)
                        .font(.largeTitle)
                        .fontWeight(.semibold)
                        .monospacedDigit()
                        .lineLimit(1)
                        .fixedSize(horizontal: true, vertical: false)
                        .padding(.leading, amountTrailingPadding)
                        .id(amountScrollId)
                }
                .onAppear { scrollAmountToTrailing(proxy) }
                .onChange(of: displayExpression) { _, _ in
                    scrollAmountToTrailing(proxy)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
        .background(
            GeometryReader { proxy in
                Color.clear
                    .onAppear { amountContainerWidth = proxy.size.width }
                    .onChange(of: proxy.size.width) { _, newValue in
                        amountContainerWidth = newValue
                    }
            }
        )
        .overlay(alignment: .topLeading) {
            Text("0")
                .font(.largeTitle)
                .fontWeight(.semibold)
                .monospacedDigit()
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .onAppear { digitWidth = proxy.size.width }
                            .onChange(of: proxy.size.width) { _, newValue in
                                digitWidth = newValue
                            }
                    }
                )
                .hidden()
        }
        .overlay(alignment: .leading) {
            Color(.secondarySystemBackground)
                .frame(width: 8)
                .allowsHitTesting(false)
        }
    }

    private var noteInlineView: some View {
        HStack(spacing: 6) {
            noteIconButton

            if isEditingNote {
                noteInlineEditor
            } else if !notePreview.isEmpty {
                Text(notePreview)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(height: 28, alignment: .leading)
    }

    private var noteIconButton: some View {
        Button {
            beginNoteEditing()
        } label: {
            Image(systemName: "note.text")
                .font(.caption2)
                .padding(6)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .disabled(isEditingNote)
    }

    private var noteInlineEditor: some View {
        TextField("备注", text: $note)
            .font(.footnote)
            .padding(.horizontal, 8)
            .frame(height: 28)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .focused($noteFocused)
            .submitLabel(.done)
            .onSubmit { finishNoteEditing() }
            .onAppear { noteFocused = true }
            .frame(width: 120)
    }

    private var categorySection: some View {
        ScrollView(.vertical, showsIndicators: false) {
            CategoryGrid(
                categories: filteredCategories,
                selected: $selectedCategory,
                onAdd: { showingCategoryManager = true }
            )
        }
    }

    private var filteredCategories: [Category] {
        var seen = Set<UUID>()
        return categories.filter { category in
            guard category.type == type else { return false }
            return seen.insert(category.id).inserted
        }
    }

    private var displayExpression: String {
        amountExpression.isEmpty ? "0" : amountExpression
    }

    private var amountValue: Double? {
        CalculatorEngine.evaluate(amountExpression)
    }

    private var amountTrailingPadding: CGFloat {
        guard digitWidth > 0, amountContainerWidth > 0 else { return 0 }
        let remainder = amountContainerWidth.truncatingRemainder(dividingBy: digitWidth)
        return remainder == 0 ? 0 : remainder
    }

    private var notePreview: String {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        if trimmed.count <= 10 {
            return trimmed
        }
        return String(trimmed.prefix(10)) + "…"
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

    private func deleteTransaction() {
        guard let txn = transaction else { return }
        context.delete(txn)
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

    private func ensureDefaultSelection() {
        if let selectedCategory,
           filteredCategories.contains(where: { $0.persistentModelID == selectedCategory.persistentModelID }) {
            return
        }
        selectedCategory = filteredCategories.first
    }

    private func beginNoteEditing() {
        isEditingNote = true
        noteFocused = true
    }

    private func finishNoteEditing() {
        noteFocused = false
        isEditingNote = false
    }

    private func scrollAmountToTrailing(_ proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            proxy.scrollTo(amountScrollId, anchor: .trailing)
        }
    }
}

private struct TightGroupBoxStyle: GroupBoxStyle {
    let insets: EdgeInsets
    var cornerRadius: CGFloat = 16

    func makeBody(configuration: Configuration) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            configuration.content
        }
        .padding(insets)
        .background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color(.separator).opacity(0.15), lineWidth: 1)
        )
    }
}
