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

    @State private var selectedPeriod: StatsPeriod = .month
    @State private var selectedMonth: Date = StatsView.currentMonthStart
    @State private var selectedYear: Date = StatsView.currentYearStart
    @State private var categoryScope: CategoryScope = .expense

    private let viewModel = StatsViewModel()
    private let trendVisibleMonthCount = 6

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

                if period == .month {
                    trendChartSection
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

    private var trendChartSection: some View {
        let latestMonth = viewModel.monthStart(for: selectedMonth)
        let earliestMonth = viewModel.earliestMonthStart(from: transactions, fallback: latestMonth)
        let months = viewModel.monthSeries(from: earliestMonth, to: latestMonth)
        let buckets = viewModel.monthlyBuckets(for: months, transactions: transactions)
        return TrendChartCard(
            title: "收支分析",
            buckets: buckets,
            earliestMonth: earliestMonth,
            latestMonth: latestMonth,
            visibleMonthCount: trendVisibleMonthCount
        )
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

private struct TrendChartCard: View {
    let title: String
    let buckets: [MonthlyBucket]
    let earliestMonth: Date
    let latestMonth: Date
    let visibleMonthCount: Int

    @State private var scrollPosition: Date
    @State private var visibleRange: ClosedRange<Date>

    private let incomeColor = Color(.systemGreen)
    private let expenseColor = Color(.systemRed)

    init(
        title: String,
        buckets: [MonthlyBucket],
        earliestMonth: Date,
        latestMonth: Date,
        visibleMonthCount: Int
    ) {
        self.title = title
        self.buckets = buckets
        self.earliestMonth = earliestMonth
        self.latestMonth = latestMonth
        self.visibleMonthCount = visibleMonthCount

        let initialRange = Self.initialVisibleRange(
            earliestMonth: earliestMonth,
            latestMonth: latestMonth,
            visibleMonthCount: visibleMonthCount
        )
        _scrollPosition = State(initialValue: initialRange.lowerBound)
        _visibleRange = State(initialValue: initialRange)
    }

    private var visibleBuckets: [MonthlyBucket] {
        let start = Self.monthStart(for: visibleRange.lowerBound)
        let end = Self.monthStart(for: visibleRange.upperBound)
        return buckets.filter { $0.monthStart >= start && $0.monthStart <= end }
    }

    private var displayMax: Double {
        visibleBuckets.map { max($0.income, $0.expense) }.max() ?? 0
    }

    private var displayMid: Double {
        displayMax / 2
    }

    private var chartTop: Double {
        let base = displayMax == 0 ? 1 : displayMax
        return base * 1.1
    }

    private var visibleRangeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月"
        let start = Self.monthStart(for: visibleRange.lowerBound)
        let end = Self.monthStart(for: visibleRange.upperBound)
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }

    private var visibleDomainLength: TimeInterval {
        let calendar = Calendar.current
        let offset = max(visibleMonthCount - 1, 0)
        let desiredStart = calendar.date(byAdding: .month, value: -offset, to: Self.monthStart(for: latestMonth)) ?? latestMonth
        let start = max(earliestMonth, desiredStart)
        let end = Self.monthEnd(for: latestMonth)
        let length = end.timeIntervalSince(start)
        return max(length, 24 * 60 * 60)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(visibleRangeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                legendItem(title: "收入", color: incomeColor)
                legendItem(title: "支出", color: expenseColor)
            }

            Chart {
                ForEach(buckets) { bucket in
                    BarMark(
                        x: .value("月份", bucket.monthStart, unit: .month),
                        y: .value("收入", bucket.income)
                    )
                    .foregroundStyle(incomeColor)
                    .position(by: .value("类型", "收入"))
                    .cornerRadius(4)
                    .offset(x: -16)

                    BarMark(
                        x: .value("月份", bucket.monthStart, unit: .month),
                        y: .value("支出", bucket.expense)
                    )
                    .foregroundStyle(expenseColor)
                    .position(by: .value("类型", "支出"))
                    .cornerRadius(4)
                    .offset(x: -16)
                }

                RuleMark(y: .value("零轴", 0))
                    .foregroundStyle(Color(.separator))
                    .lineStyle(StrokeStyle(lineWidth: 1))

                if displayMax > 0 {
                    RuleMark(y: .value("中值", displayMid))
                        .foregroundStyle(Color(.systemGray3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                    RuleMark(y: .value("最大值", displayMax))
                        .foregroundStyle(Color(.systemGray3))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                }
            }
            .chartYAxis(.hidden)
            .chartXAxis {
                AxisMarks(values: buckets.map(\.monthStart)) { value in
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(monthLabel(date))
                        }
                    }
                }
            }
            .chartLegend(.hidden)
            .chartYScale(domain: 0...chartTop)
            .chartScrollableAxes(.horizontal)
            .chartXScale(domain: earliestMonth...Self.monthEnd(for: latestMonth))
            .chartXVisibleDomain(length: visibleDomainLength)
            .chartScrollPosition(x: $scrollPosition)
            .chartOverlay { proxy in
                GeometryReader { geo in
                    if proxy.plotFrame != nil {
                        let maxY = proxy.position(forY: displayMax)
                        let midY = proxy.position(forY: displayMid)

                        ZStack(alignment: .topLeading) {
                            if displayMax > 0 {
                                if let maxY {
                                    Text(formatAxisValue(displayMax))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .position(x: 8, y: maxY)
                                }
                                if let midY {
                                    Text(formatAxisValue(displayMid))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .position(x: 8, y: midY)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .onAppear {
                            updateVisibleRange(start: scrollPosition, end: nil)
                        }
                        .onChange(of: scrollPosition) { _, _ in
                            updateVisibleRange(start: scrollPosition, end: nil)
                        }
                    } else {
                        Color.clear
                    }
                }
            }
            .frame(height: 180)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(16)
    }

    private func legendItem(title: String, color: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "circle.fill")
                .font(.caption2)
                .foregroundStyle(color)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func monthLabel(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM"
        return formatter.string(from: date)
    }

    private func formatAxisValue(_ value: Double) -> String {
        guard value >= 1000 else {
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: value)) ?? "0"
        }

        let kValue = value / 1000
        let rounded = (kValue * 10).rounded() / 10
        let formatted = String(format: "%.1f", rounded)
        let trimmed = formatted.hasSuffix(".0") ? String(formatted.dropLast(2)) : formatted
        return "\(trimmed)k"
    }

    private static func monthStart(for date: Date) -> Date {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: comps) ?? date
    }

    private static func initialVisibleRange(
        earliestMonth: Date,
        latestMonth: Date,
        visibleMonthCount: Int
    ) -> ClosedRange<Date> {
        let calendar = Calendar.current
        let offset = max(visibleMonthCount - 1, 0)
        let desiredStart = calendar.date(byAdding: .month, value: -offset, to: Self.monthStart(for: latestMonth)) ?? latestMonth
        let start = max(earliestMonth, desiredStart)
        return start...latestMonth
    }

    private func updateVisibleRange(start: Date?, end _: Date?) {
        guard let start else { return }
        var lower = Self.monthStart(for: start)
        if lower < earliestMonth {
            lower = earliestMonth
        }
        let desiredUpper = Self.addMonths(lower, by: max(visibleMonthCount - 1, 0))
        let latestStart = Self.monthStart(for: latestMonth)
        let upper = min(desiredUpper, latestStart)
        if lower > upper {
            lower = upper
        }
        if lower != visibleRange.lowerBound || upper != visibleRange.upperBound {
            DispatchQueue.main.async {
                visibleRange = lower...upper
            }
        }
    }

    private static func monthEnd(for date: Date) -> Date {
        let calendar = Calendar.current
        let start = Self.monthStart(for: date)
        guard let next = calendar.date(byAdding: .month, value: 1, to: start) else { return date }
        return next.addingTimeInterval(-1)
    }

    private static func addMonths(_ date: Date, by value: Int) -> Date {
        let calendar = Calendar.current
        return calendar.date(byAdding: .month, value: value, to: date) ?? date
    }
}
