import SwiftUI
import SwiftData
import Charts

private enum StatsPeriod: String, CaseIterable, Identifiable {
    case month
    case year

    var id: String { rawValue }

    var title: String {
        switch self {
        case .month: return "月"
        case .year: return "年"
        }
    }

    var calendarComponent: Calendar.Component {
        switch self {
        case .month: return .month
        case .year: return .year
        }
    }
}

private enum TrendType: String, Identifiable {
    case income
    case expense

    var id: String { rawValue }

    var label: String {
        switch self {
        case .income: return "收入"
        case .expense: return "支出"
        }
    }
}

private enum CategoryScope: String, CaseIterable, Identifiable {
    case expense
    case income

    var id: String { rawValue }

    var label: String {
        switch self {
        case .expense: return "支出"
        case .income: return "收入"
        }
    }

    var typeValue: String {
        switch self {
        case .expense: return "Expense"
        case .income: return "Income"
        }
    }
}

private struct TrendBar: Identifiable {
    let id = UUID()
    let date: Date
    let type: TrendType
    let value: Double
}

private struct DonutSlice: Identifiable {
    let id = UUID()
    let bucket: CategoryBucket
    let startAngle: Angle
    let endAngle: Angle
    let percentage: Double

    var midAngle: Angle {
        Angle.degrees((startAngle.degrees + endAngle.degrees) / 2)
    }
}

struct StatsView: View {
    @Query(sort: \Transaction.date) private var transactions: [Transaction]
    @Environment(\.colorScheme) private var colorScheme

    @State private var selectedPeriod: StatsPeriod = .month
    @State private var selectedMonth: Date = StatsView.currentMonthStart
    @State private var selectedYear: Date = StatsView.currentYearStart
    @State private var categoryScope: CategoryScope = .expense

    private let viewModel = StatsViewModel()

    private static var currentMonthStart: Date {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: .now)
        return calendar.date(from: comps) ?? .now
    }

    private static var currentYearStart: Date {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year], from: .now)
        return calendar.date(from: comps) ?? .now
    }

    var body: some View {
        VStack(spacing: 0) {
            headerBar
            TabView(selection: $selectedPeriod) {
                periodPage(period: .month)
                    .tag(StatsPeriod.month)

                periodPage(period: .year)
                    .tag(StatsPeriod.year)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var headerBar: some View {
        HStack(alignment: .center) {
            Text("统计")
                .font(.title)
                .fontWeight(.bold)

            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Color(.systemBackground))
    }

    private func periodPage(period: StatsPeriod) -> some View {
        let selectedDate = period == .month ? selectedMonth : selectedYear
        let periodLabel = formattedPeriodLabel(for: selectedDate, period: period)
        let periodTransactions = viewModel.transactionsInPeriod(containing: selectedDate, granularity: period.calendarComponent, from: transactions)
        let hasData = !periodTransactions.isEmpty

        let bars = trendBars(for: period)
        let candidateDates = bars.map { $0.date }.uniqueSorted()

        let categoryBuckets = viewModel.categoryBuckets(
            for: selectedDate,
            granularity: period.calendarComponent,
            from: transactions,
            type: categoryScope.typeValue
        )
        let donutSlices = makeDonutSlices(from: categoryBuckets).filter { $0.percentage >= 0.01 }

        return ScrollView {
            VStack(spacing: 16) {
                HStack {
                    Text(periodLabel)
                        .font(.headline)
                    Spacer()
                }

                trendChart(
                    bars: bars,
                    candidateDates: candidateDates,
                    selectedDate: selectedDate,
                    granularity: period.calendarComponent
                ) { newDate in
                    withAnimation(.spring(response: 0.36, dampingFraction: 0.86)) {
                        if period == .month {
                            selectedMonth = newDate
                        } else {
                            selectedYear = newDate
                        }
                    }
                }

                if hasData {
                    Picker("收支类型", selection: $categoryScope) {
                        ForEach(CategoryScope.allCases) { scope in
                            Text(scope.label).tag(scope)
                        }
                    }
                    .pickerStyle(.segmented)

                    if categoryBuckets.isEmpty {
                        EmptyStateView(
                            title: emptyTitle(for: period),
                            message: "本期暂无\(categoryScope.label)记录"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                    } else {
                        donutSection(slices: donutSlices)
                        categoryList(buckets: categoryBuckets)
                    }
                } else {
                    EmptyStateView(title: emptyTitle(for: period), message: "本期还没有收支记录")
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                }
            }
            .padding()
        }
    }

    private func trendBars(for period: StatsPeriod) -> [TrendBar] {
        switch period {
        case .month:
            let months = viewModel.recentMonths(from: .now, count: 6)
            let buckets = viewModel.monthlyBuckets(for: months, transactions: transactions)
            return buckets.flatMap { bucket in
                [
                    TrendBar(date: bucket.monthStart, type: .income, value: bucket.income),
                    TrendBar(date: bucket.monthStart, type: .expense, value: bucket.expense)
                ]
            }
        case .year:
            let years = viewModel.recentYears(from: .now, count: 6)
            let buckets = viewModel.yearlyBuckets(for: years, transactions: transactions)
            return buckets.flatMap { bucket in
                [
                    TrendBar(date: bucket.yearStart, type: .income, value: bucket.income),
                    TrendBar(date: bucket.yearStart, type: .expense, value: bucket.expense)
                ]
            }
        }
    }

    private func trendChart(
        bars: [TrendBar],
        candidateDates: [Date],
        selectedDate: Date,
        granularity: Calendar.Component,
        onSelect: @escaping (Date) -> Void
    ) -> some View {
        let gridOpacity: Double = colorScheme == .dark ? 0.1 : 0.2
        let incomeBase = Color(.systemGreen)
        let expenseBase = Color(.systemRed)

        return VStack(alignment: .leading, spacing: 8) {
            Text("收支趋势")
                .font(.headline)

            Chart {
                ForEach(bars) { bar in
                    let isSelected = Calendar.current.isDate(bar.date, equalTo: selectedDate, toGranularity: granularity)
                    let base = bar.type == .income ? incomeBase : expenseBase
                    let gradient = LinearGradient(
                        stops: [
                            .init(color: base.opacity(0.85), location: 0),
                            .init(color: base.opacity(0.45), location: 0.1),
                            .init(color: base.opacity(0.2), location: 1)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )

                    BarMark(
                        x: .value("周期", bar.date, unit: granularity),
                        y: .value("金额", bar.value)
                    )
                    .position(by: .value("类型", bar.type.label))
                    .foregroundStyle(gradient)
                    .cornerRadius(4)
                    .opacity(isSelected ? 1 : 0.7)
                }
            }
            .frame(height: 220)
            .chartLegend(.hidden)
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine().foregroundStyle(Color.primary.opacity(gridOpacity))
                    AxisTick().foregroundStyle(Color.primary.opacity(gridOpacity))
                    AxisValueLabel(format: axisLabelFormat(for: granularity))
                        .foregroundStyle(.secondary)
                }
            }
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine().foregroundStyle(Color.primary.opacity(gridOpacity))
                    AxisTick().foregroundStyle(Color.primary.opacity(gridOpacity))
                    AxisValueLabel()
                        .foregroundStyle(.secondary)
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            SpatialTapGesture()
                                .onEnded { value in
                                    guard let plotFrame = proxy.plotFrame else { return }
                                    let origin = geo[plotFrame].origin
                                    let locationX = value.location.x - origin.x
                                    if let date: Date = proxy.value(atX: locationX) {
                                        if let nearest = nearestDate(to: date, in: candidateDates, granularity: granularity) {
                                            onSelect(nearest)
                                        }
                                    }
                                }
                        )
                }
            }
            .animation(.spring(response: 0.36, dampingFraction: 0.86), value: selectedDate)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func donutSection(slices: [DonutSlice]) -> some View {
        let ringSize: CGFloat = 120
        let containerHeight: CGFloat = 180
        let iconGap: CGFloat = 10
        let innerRatio: CGFloat = 0.55
        let innerBandRatio: CGFloat = innerRatio + (1 - innerRatio) * 0.25
        return VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Chart(slices) { slice in
                    let baseColor = Color(hex: slice.bucket.colorHex)
                    let innerColor = darkerColor(hex: slice.bucket.colorHex, factor: 0.8)
                    let outerRadius = ringSize / 2
                    let innerRadius = outerRadius * innerRatio
                    let bandRadius = outerRadius * innerBandRatio
                    let stop = min(max((bandRadius - innerRadius) / max(outerRadius - innerRadius, 1), 0), 1)
                    let gradient = RadialGradient(
                        gradient: Gradient(stops: [
                            .init(color: innerColor, location: 0),
                            .init(color: innerColor, location: stop),
                            .init(color: baseColor, location: min(stop + 0.01, 1)),
                            .init(color: baseColor, location: 1)
                        ]),
                        center: .center,
                        startRadius: innerRadius,
                        endRadius: outerRadius
                    )
                    SectorMark(
                        angle: .value("占比", abs(slice.bucket.total)),
                        innerRadius: .ratio(innerRatio),
                        outerRadius: .ratio(1.0),
                        angularInset: 2
                    )
                    .foregroundStyle(gradient)
                }
                .frame(height: ringSize)
                .animation(.spring(response: 0.36, dampingFraction: 0.86), value: slices.map { $0.percentage })

                GeometryReader { geo in
                    let size = ringSize
                    let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                    let outerRadius = size / 2
                    let iconRadius: CGFloat = 14
                    let labelRadius = outerRadius + iconRadius + iconGap

                    ForEach(slices) { slice in
                        let angle = slice.midAngle
                        let lineStart = point(on: center, radius: outerRadius * 0.95, angle: angle)
                        let labelPoint = point(on: center, radius: labelRadius, angle: angle)
                        let lineEnd = labelPoint
                        let percentText = percentString(slice.percentage)
                        let dx = labelPoint.x - center.x
                        let dy = labelPoint.y - center.y
                        let percentOffsetX: CGFloat = dx >= 0 ? 24 : -24
                        let percentOffsetY: CGFloat = dy >= 0 ? 18 : -18
                        let percentPoint = CGPoint(x: labelPoint.x + percentOffsetX, y: labelPoint.y + percentOffsetY)

                        Path { path in
                            path.move(to: lineStart)
                            path.addLine(to: lineEnd)
                        }
                        .stroke(Color(hex: slice.bucket.colorHex).opacity(0.7), lineWidth: 2)

                        ZStack {
                            Circle()
                                .fill(Color(hex: slice.bucket.colorHex))
                            Image(systemName: slice.bucket.iconName)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        .frame(width: 28, height: 28)
                        .position(labelPoint)

                        Text(percentText)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .position(percentPoint)
                    }
                }
                .allowsHitTesting(false)
            }
            .frame(height: containerHeight)
        }
        .padding()
        .frame(maxWidth: 260)
    }

    private func categoryList(buckets: [CategoryBucket]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("分类详情")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(buckets) { bucket in
                    HStack(spacing: 12) {
                        CategoryIcon(iconName: bucket.iconName, colorHex: bucket.colorHex, size: 28, cornerRadius: 10)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(bucket.name)
                                .font(.subheadline)
                            Text("\(bucket.count) 笔")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(formatSignedCurrency(bucket.total))
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                }
            }
        }
        .padding()
    }

    private func formattedPeriodLabel(for date: Date, period: StatsPeriod) -> String {
        let formatter = DateFormatter()
        switch period {
        case .month:
            formatter.dateFormat = "yyyy年MM月"
        case .year:
            formatter.dateFormat = "yyyy年"
        }
        return formatter.string(from: date)
    }

    private func axisLabelFormat(for granularity: Calendar.Component) -> Date.FormatStyle {
        switch granularity {
        case .year:
            return Date.FormatStyle().year(.defaultDigits)
        default:
            return Date.FormatStyle().month(.defaultDigits).year(.defaultDigits)
        }
    }

    private func nearestDate(to date: Date, in candidates: [Date], granularity: Calendar.Component) -> Date? {
        guard !candidates.isEmpty else { return nil }
        let calendar = Calendar.current
        let normalized: Date
        switch granularity {
        case .year:
            let comps = calendar.dateComponents([.year], from: date)
            normalized = calendar.date(from: comps) ?? date
        default:
            let comps = calendar.dateComponents([.year, .month], from: date)
            normalized = calendar.date(from: comps) ?? date
        }
        return candidates.min(by: { abs($0.timeIntervalSince(normalized)) < abs($1.timeIntervalSince(normalized)) })
    }

    private func makeDonutSlices(from buckets: [CategoryBucket]) -> [DonutSlice] {
        let total = buckets.reduce(0.0) { $0 + abs($1.total) }
        guard total > 0 else { return [] }
        var current = 0.0
        return buckets.map { bucket in
            let value = abs(bucket.total)
            let start = current / total * 360
            current += value
            let end = current / total * 360
            let percentage = value / total
            return DonutSlice(
                bucket: bucket,
                startAngle: .degrees(start),
                endAngle: .degrees(end),
                percentage: percentage
            )
        }
    }

    private func percentString(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "0%"
    }

    private func darkerColor(hex: String, factor: Double) -> Color {
        let sanitized = hex
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: sanitized).scanHexInt64(&rgb)

        let r = min(max(Double((rgb & 0xFF0000) >> 16) / 255.0 * factor, 0), 1)
        let g = min(max(Double((rgb & 0x00FF00) >> 8) / 255.0 * factor, 0), 1)
        let b = min(max(Double(rgb & 0x0000FF) / 255.0 * factor, 0), 1)

        return Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    private func point(on center: CGPoint, radius: CGFloat, angle: Angle) -> CGPoint {
        let radians = angle.radians - (.pi / 2)
        return CGPoint(
            x: center.x + radius * cos(radians),
            y: center.y + radius * sin(radians)
        )
    }

    private func emptyTitle(for period: StatsPeriod) -> String {
        switch period {
        case .month: return "本月暂无收支记录"
        case .year: return "本年暂无收支记录"
        }
    }

    private func formatSignedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "CNY"
        formatter.maximumFractionDigits = 2
        let formatted = formatter.string(from: NSNumber(value: abs(value))) ?? "¥0"
        if value == 0 {
            return formatted
        }
        return value < 0 ? "-\(formatted)" : "+\(formatted)"
    }
}

private extension Array where Element == Date {
    func uniqueSorted() -> [Date] {
        Array(Set(self)).sorted()
    }
}
