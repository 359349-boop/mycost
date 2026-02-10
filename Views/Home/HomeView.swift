import SwiftUI
import SwiftData
import UIKit

private enum TransactionTypeFilter: String, CaseIterable, Identifiable {
    case all
    case expense
    case income

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "全部"
        case .expense: return "支出"
        case .income: return "收入"
        }
    }
}

private enum DateScope: String, CaseIterable, Identifiable {
    case year
    case month

    var id: String { rawValue }

    var label: String {
        switch self {
        case .year: return "年"
        case .month: return "月"
        }
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var editingTransaction: Transaction?
    @GestureState private var dragOffset: CGFloat = 0
    @State private var previewPeriodDate: Date?
    @State private var contentWidth: CGFloat = 0

    @State private var searchText = ""
    @State private var typeFilter: TransactionTypeFilter = .all
    @State private var dateScope: DateScope = .month
    @State private var currentPeriodDate: Date = .now

    private let viewModel = TransactionListViewModel()

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            filterBar
            contentView
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always))
        .onChange(of: dateScope) { _, _ in
            currentPeriodDate = .now
            previewPeriodDate = nil
        }
        .sheet(item: $editingTransaction) { txn in
            AddTransactionView(transaction: txn)
        }
    }

    private var contentView: some View {
        GeometryReader { proxy in
            let width = proxy.size.width
            let isForward = dragOffset < 0
            ZStack {
                periodContentView(for: filteredTransactions)
                    .offset(x: dragOffset)

                if let previewDate = previewPeriodDate {
                    periodContentView(for: filteredTransactions(for: previewDate, type: typeFilter))
                        .offset(x: dragOffset + (isForward ? width : -width))
                        .allowsHitTesting(false)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onAppear { contentWidth = width }
            .onChange(of: width) { _, newValue in
                contentWidth = newValue
            }
        }
        .contentShape(Rectangle())
        .animation(.interactiveSpring(response: 0.32, dampingFraction: 0.82, blendDuration: 0.12), value: dragOffset)
        .simultaneousGesture(periodSwipeGesture)
        .overlay {
            HStack(spacing: 0) {
                LinearGradient(
                    colors: [Color(.systemBackground).opacity(0.45), .clear],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 16)
                Spacer()
                LinearGradient(
                    colors: [.clear, Color(.systemBackground).opacity(0.45)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(width: 16)
            }
            .allowsHitTesting(false)
        }
    }

    private var emptyStateView: some View {
        EmptyStateView(
            title: transactions.isEmpty ? "还没有账目" : "没有匹配结果",
            message: transactions.isEmpty ? "添加第一笔支出或收入" : "调整筛选或搜索条件"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var headerBar: some View {
        HStack(alignment: .center) {
            Text("账本")
                .font(.title)
                .fontWeight(.bold)

            Spacer()

            NavigationLink {
                SettingsView()
            } label: {
                Image(systemName: "person.crop.circle")
                    .font(.title)
                    .foregroundStyle(.tint)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color(.systemBackground))
    }

    @ViewBuilder
    private func periodContentView(for transactions: [Transaction]) -> some View {
        if transactions.isEmpty {
            emptyStateView
        } else {
            listView(for: transactions)
        }
    }

    private func listView(for transactions: [Transaction]) -> some View {
        let sections = viewModel.sections(from: transactions)
        return List {
            ForEach(sections) { section in
                Section {
                    ForEach(section.transactions, id: \.id) { txn in
                        TransactionRow(transaction: txn)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editingTransaction = txn
                            }
                    }
                } header: {
                    HStack {
                        Text(formattedSectionDate(section.date))
                        Spacer()
                        Text(netAmountText(section.netTotal))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(6)
    }

    private var filterBar: some View {
        VStack(spacing: 8) {
            typeFilterCard

            Picker("时间", selection: $dateScope) {
                ForEach(DateScope.allCases) { item in
                    Text(scopeLabel(for: item)).tag(item)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var typeFilterCard: some View {
        VStack(spacing: 6) {
            Picker("类型", selection: $typeFilter) {
                ForEach(TransactionTypeFilter.allCases) { item in
                    Text(item.label).tag(item)
                }
            }
            .pickerStyle(.segmented)

            typeAmountRow
                .allowsHitTesting(false)
        }
        .padding(6)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var typeAmountRow: some View {
        HStack(spacing: 8) {
            amountCell(amountText(for: .all))
            amountCell(amountText(for: .expense))
            amountCell(amountText(for: .income))
        }
    }

    private func amountCell(_ text: String) -> some View {
        Text(text)
            .font(.caption2)
            .foregroundStyle(.secondary)
            .monospacedDigit()
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private var filteredTransactions: [Transaction] {
        filteredTransactions(for: currentPeriodDate, type: typeFilter)
    }

    private func filteredTransactions(for periodDate: Date, type: TransactionTypeFilter?) -> [Transaction] {
        var result = transactions

        if let type {
            switch type {
            case .all:
                break
            case .expense:
                result = result.filter { $0.type == "Expense" }
            case .income:
                result = result.filter { $0.type == "Income" }
            }
        }

        switch dateScope {
        case .year:
            let calendar = Calendar.current
            let targetYear = calendar.component(.year, from: periodDate)
            result = result.filter {
                calendar.component(.year, from: $0.date) == targetYear
            }
        case .month:
            let calendar = Calendar.current
            let comps = calendar.dateComponents([.year, .month], from: periodDate)
            result = result.filter {
                let item = calendar.dateComponents([.year, .month], from: $0.date)
                return item.year == comps.year && item.month == comps.month
            }
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !query.isEmpty {
            let lower = query.lowercased()
            result = result.filter { txn in
                let noteMatch = txn.note?.lowercased().contains(lower) ?? false
                let categoryMatch = txn.category?.name.lowercased().contains(lower) ?? false
                return noteMatch || categoryMatch
            }
        }

        return result
    }

    private func shiftPeriod(forward: Bool) {
        let calendar = Calendar.current
        let value = forward ? 1 : -1
        let candidate: Date
        switch dateScope {
        case .year:
            candidate = calendar.date(byAdding: .year, value: value, to: currentPeriodDate) ?? currentPeriodDate
        case .month:
            candidate = calendar.date(byAdding: .month, value: value, to: currentPeriodDate) ?? currentPeriodDate
        }

        guard !filteredTransactions(for: candidate, type: typeFilter).isEmpty else { return }
        withAnimation(.easeInOut(duration: 0.25)) {
            currentPeriodDate = candidate
        }
    }

    private var periodSwipeGesture: some Gesture {
        DragGesture()
            .updating($dragOffset) { value, state, _ in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical) else {
                    state = 0
                    return
                }
                let forward = horizontal < 0
                let candidate = candidatePeriodDate(forward: forward)
                let canShift = candidate.map { !filteredTransactions(for: $0, type: typeFilter).isEmpty } ?? false
                let clamped: CGFloat
                if contentWidth > 0 {
                    clamped = min(max(horizontal, -contentWidth), contentWidth)
                } else {
                    clamped = horizontal
                }
                let factor: CGFloat = canShift ? 1.0 : 0.2
                state = clamped * factor

                if abs(horizontal) > 24, let candidate, canShift {
                    previewPeriodDate = candidate
                } else {
                    previewPeriodDate = nil
                }
            }
            .onEnded { value in
                defer { previewPeriodDate = nil }
                let horizontal = value.predictedEndTranslation.width
                let vertical = value.predictedEndTranslation.height
                let threshold = max(CGFloat(60), contentWidth * CGFloat(0.25))
                guard abs(horizontal) > abs(vertical), abs(horizontal) > threshold else { return }
                if horizontal < 0 {
                    shiftPeriod(forward: true)
                } else {
                    shiftPeriod(forward: false)
                }
            }
    }

    private func scopeLabel(for item: DateScope) -> String {
        guard item == dateScope else { return item.label }
        if let preview = previewPeriodDate {
            return formattedPeriodLabel(for: preview, scope: item)
        }
        guard !isCurrentPeriod else { return item.label }
        return formattedPeriodLabel(for: currentPeriodDate, scope: item)
    }

    private var isCurrentPeriod: Bool {
        let calendar = Calendar.current
        switch dateScope {
        case .year:
            return calendar.isDate(currentPeriodDate, equalTo: .now, toGranularity: .year)
        case .month:
            return calendar.isDate(currentPeriodDate, equalTo: .now, toGranularity: .month)
        }
    }

    private func formattedPeriodLabel(for date: Date, scope: DateScope) -> String {
        let formatter = DateFormatter()
        switch scope {
        case .year:
            formatter.dateFormat = "yyyy年"
        case .month:
            formatter.dateFormat = "yyyy年MM月"
        }
        return formatter.string(from: date)
    }

    private func candidatePeriodDate(forward: Bool) -> Date? {
        let calendar = Calendar.current
        let value = forward ? 1 : -1
        switch dateScope {
        case .year:
            return calendar.date(byAdding: .year, value: value, to: currentPeriodDate)
        case .month:
            return calendar.date(byAdding: .month, value: value, to: currentPeriodDate)
        }
    }

    private func formattedSectionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
    }

    private func amountText(for type: TransactionTypeFilter) -> String {
        let base = filteredTransactions(for: currentPeriodDate, type: nil)
        let value: Decimal

        switch type {
        case .all:
            value = base.reduce(Decimal.zero) { result, txn in
                let signed = txn.type == "Expense" ? -txn.amount : txn.amount
                return result + signed
            }
        case .expense:
            value = base.filter { $0.type == "Expense" }.reduce(Decimal.zero) { $0 + $1.amount }
        case .income:
            value = base.filter { $0.type == "Income" }.reduce(Decimal.zero) { $0 + $1.amount }
        }

        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.maximumFractionDigits = 2
        let formatted = formatter.string(from: NSNumber(value: abs(number.doubleValue))) ?? "¥0"
        if type == .all {
            if number == 0 {
                return formatted
            }
            return number.doubleValue < 0 ? "-\(formatted)" : "+\(formatted)"
        }
        return formatted
    }

    private func netAmountText(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.maximumFractionDigits = 2
        let formatted = formatter.string(from: NSNumber(value: abs(number.doubleValue))) ?? "¥0"
        if number == 0 {
            return formatted
        }
        return number.doubleValue < 0 ? "-\(formatted)" : "+\(formatted)"
    }
}
