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

    @State private var searchText = ""
    @State private var typeFilter: TransactionTypeFilter = .all
    @State private var dateScope: DateScope = .month
    @State private var currentPeriodDate: Date = .now

    private let viewModel = TransactionListViewModel()

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            searchBar
            filterBar
            contentView
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: dateScope) { _, _ in
            currentPeriodDate = .now
        }
        .sheet(item: $editingTransaction) { txn in
            AddTransactionView(transaction: txn)
        }
    }

    private var contentView: some View {
        Group {
            if filteredTransactions.isEmpty {
                emptyStateView
            } else {
                listView
            }
        }
        .contentShape(Rectangle())
        .offset(x: dragOffset)
        .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.1), value: dragOffset)
        .simultaneousGesture(periodSwipeGesture)
    }

    private var emptyStateView: some View {
        EmptyStateView(
            title: transactions.isEmpty ? "还没有账目" : "没有匹配结果",
            message: transactions.isEmpty ? "添加第一笔支出或收入" : "调整筛选或搜索条件"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField("搜索", text: $searchText)
                .textInputAutocapitalization(.never)
                .disableAutocorrection(true)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal)
        .padding(.bottom, 8)
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

    private var listView: some View {
        let sections = viewModel.sections(from: filteredTransactions)
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
                    .onDelete { indexSet in
                        delete(in: section, at: indexSet)
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
            Picker("类型", selection: $typeFilter) {
                ForEach(TransactionTypeFilter.allCases) { item in
                    Text(item.label).tag(item)
                }
            }
            .pickerStyle(.segmented)

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

    private var filteredTransactions: [Transaction] {
        filteredTransactions(for: currentPeriodDate)
    }

    private func filteredTransactions(for periodDate: Date) -> [Transaction] {
        var result = transactions

        switch typeFilter {
        case .all:
            break
        case .expense:
            result = result.filter { $0.type == "Expense" }
        case .income:
            result = result.filter { $0.type == "Income" }
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

    private func delete(in section: TransactionDaySection, at indexSet: IndexSet) {
        let items = indexSet.map { section.transactions[$0] }
        items.forEach { context.delete($0) }
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
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

        guard !filteredTransactions(for: candidate).isEmpty else { return }
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
                state = horizontal * 0.25
            }
            .onEnded { value in
                let horizontal = value.translation.width
                let vertical = value.translation.height
                guard abs(horizontal) > abs(vertical), abs(horizontal) > 80 else { return }
                if horizontal < 0 {
                    shiftPeriod(forward: true)
                } else {
                    shiftPeriod(forward: false)
                }
            }
    }

    private func scopeLabel(for item: DateScope) -> String {
        guard item == dateScope else { return item.label }
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

    private func formattedSectionDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MMM dd"
        return formatter.string(from: date)
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
