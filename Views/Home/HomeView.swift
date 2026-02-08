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
    case all
    case month

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "全部"
        case .month: return "本月"
        }
    }
}

struct HomeView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var editingTransaction: Transaction?

    @State private var searchText = ""
    @State private var typeFilter: TransactionTypeFilter = .all
    @State private var dateScope: DateScope = .all

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
                        Text(section.date, format: .dateTime.month().day())
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
        VStack(spacing: 12) {
            Picker("类型", selection: $typeFilter) {
                ForEach(TransactionTypeFilter.allCases) { item in
                    Text(item.label).tag(item)
                }
            }
            .pickerStyle(.segmented)

            Picker("时间", selection: $dateScope) {
                ForEach(DateScope.allCases) { item in
                    Text(item.label).tag(item)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding()
        .background(Color(.systemBackground))
    }

    private var filteredTransactions: [Transaction] {
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
        case .all:
            break
        case .month:
            let calendar = Calendar.current
            let comps = calendar.dateComponents([.year, .month], from: .now)
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
