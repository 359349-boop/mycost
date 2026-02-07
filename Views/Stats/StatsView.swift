import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Query(sort: \Transaction.date) private var transactions: [Transaction]
    private let viewModel = StatsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                summaryRow
                changeRow

                if transactions.isEmpty {
                    EmptyStateView(title: "暂无统计", message: "记录几笔后查看趋势")
                } else {
                    monthlyChart
                    categoryChart
                    topCategoryList
                }
            }
            .padding()
        }
        .navigationTitle("统计")
    }

    private var summaryRow: some View {
        let current = viewModel.monthlySummary(for: .now, transactions: transactions)
        return HStack(spacing: 12) {
            StatSummaryCard(
                title: "本月支出",
                value: format(currency: current.expense),
                systemImage: "arrow.down.circle.fill",
                tint: .red
            )
            StatSummaryCard(
                title: "本月收入",
                value: format(currency: current.income),
                systemImage: "arrow.up.circle.fill",
                tint: .green
            )
            StatSummaryCard(
                title: "结余",
                value: format(currency: current.balance),
                systemImage: "equal.circle.fill",
                tint: .blue
            )
        }
    }

    private var changeRow: some View {
        let calendar = Calendar.current
        let previousMonth = calendar.date(byAdding: .month, value: -1, to: .now) ?? .now
        let lastYear = calendar.date(byAdding: .year, value: -1, to: .now) ?? .now

        let current = viewModel.monthlySummary(for: .now, transactions: transactions)
        let previous = viewModel.monthlySummary(for: previousMonth, transactions: transactions)
        let lastYearSummary = viewModel.monthlySummary(for: lastYear, transactions: transactions)

        let mom = percentChange(current: current.expense, previous: previous.expense)
        let yoy = percentChange(current: current.expense, previous: lastYearSummary.expense)

        return HStack(spacing: 12) {
            StatSummaryCard(
                title: "支出环比",
                value: mom,
                systemImage: "chart.line.uptrend.xyaxis",
                tint: .orange
            )
            StatSummaryCard(
                title: "支出同比",
                value: yoy,
                systemImage: "chart.line.uptrend.xyaxis",
                tint: .purple
            )
        }
    }

    private var monthlyChart: some View {
        let buckets = viewModel.monthlyBuckets(from: transactions)
        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("月度趋势")
                    .font(.headline)
                Spacer()
            }
            Chart {
                ForEach(buckets) { bucket in
                    BarMark(
                        x: .value("月份", bucket.monthStart, unit: .month),
                        y: .value("支出", bucket.expense)
                    )
                    .foregroundStyle(Color.accentColor)
                    .cornerRadius(6)

                    LineMark(
                        x: .value("月份", bucket.monthStart, unit: .month),
                        y: .value("收入", bucket.income)
                    )
                    .foregroundStyle(.secondary)
                    .symbol(.circle)
                }
            }
            .frame(height: 220)
            .chartXAxis(.automatic)
            .chartLegend(.hidden)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var categoryChart: some View {
        let buckets = viewModel.categoryBuckets(for: .now, from: transactions)
        return VStack(alignment: .leading, spacing: 8) {
            Text("分类分布（本月）")
                .font(.headline)
            if buckets.isEmpty {
                EmptyStateView(title: "暂无分类数据", message: "本月还没有支出")
            } else {
                Chart(buckets) { bucket in
                    SectorMark(
                        angle: .value("金额", bucket.total),
                        innerRadius: .ratio(0.55),
                        angularInset: 2
                    )
                    .foregroundStyle(Color(hex: bucket.colorHex))
                }
                .frame(height: 220)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private var topCategoryList: some View {
        let buckets = viewModel.topExpenseCategories(for: .now, from: transactions, limit: 3)
        return VStack(alignment: .leading, spacing: 8) {
            Text("本月 Top 分类")
                .font(.headline)
            if buckets.isEmpty {
                EmptyStateView(title: "暂无 Top 分类", message: "本月还没有支出")
            } else {
                VStack(spacing: 10) {
                    ForEach(buckets) { bucket in
                        HStack(spacing: 12) {
                            CategoryIcon(iconName: bucket.iconName, colorHex: bucket.colorHex, size: 28, cornerRadius: 10)
                            Text(bucket.name)
                                .font(.subheadline)
                            Spacer()
                            Text(format(currency: bucket.total))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func percentChange(current: Double, previous: Double) -> String {
        guard previous != 0 else { return "—" }
        let change = (current - previous) / previous
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        let value = formatter.string(from: NSNumber(value: change)) ?? "0%"
        return change >= 0 ? "+\(value)" : value
    }

    private func format(currency value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.maximumFractionDigits = 2
        return formatter.string(from: NSNumber(value: value)) ?? "¥0"
    }
}
