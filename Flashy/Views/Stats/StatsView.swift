import Charts
import SwiftData
import SwiftUI
import FlashyCore

enum StatsRange: String, CaseIterable, Identifiable {
    case week = "7D"
    case month = "30D"
    case year = "1Y"
    case all = "ALL"

    var id: Self { self }

    var days: Int? {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        case .all: return nil
        }
    }
}

/// Progress dashboard. Only daily-set reviews count; practice isn't logged.
struct StatsView: View {
    @Environment(AppModel.self) private var model
    @Query private var reviews: [ReviewRecord]
    @Query(filter: #Predicate<CardRecord> { $0.isActive }) private var cards: [CardRecord]
    @Query private var dayRecords: [DayRecord]
    @State private var range: StatsRange = .month

    var body: some View {
        let events = reviews.map(\.event)
        let today = model.today
        let start = startDay(events: events, today: today)
        let inRange = events.filter { $0.day >= start && $0.day <= today }
        let streak = Stats.streak(
            outcomes: Dictionary(dayRecords.map { (StudyDay($0.dayIndex), $0.outcome) }, uniquingKeysWith: { _, last in last }),
            today: today
        )
        let categories = Dictionary(cards.map { ($0.id, $0.categoryPath) }, uniquingKeysWith: { first, _ in first })

        ScrollView {
            VStack(spacing: 20) {
                Text("STATS")
                    .font(Theme.mono(30, .heavy))
                    .tracking(6)
                    .foregroundStyle(Theme.sunGradient)
                    .glow(Theme.magenta, radius: 8)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Picker("Range", selection: $range) {
                    ForEach(StatsRange.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                HStack(spacing: 12) {
                    StatTile(label: "Streak", value: streak.current, unit: streak.current == 1 ? "day" : "days", color: Theme.sun)
                    StatTile(label: "Best", value: streak.longest, unit: streak.longest == 1 ? "day" : "days", color: Theme.magenta)
                    StatTile(label: "Reviews", value: inRange.count, unit: range.rawValue.lowercased(), color: Theme.blue)
                }

                MaturityChart(counts: Stats.maturityCounts(cards.map(\.schedule)))
                HeatmapView(
                    counts: Dictionary(grouping: events, by: \.day).mapValues(\.count),
                    start: min(start, today.adding(-83)),
                    end: today,
                    calendar: model.studyCalendar
                )
                ReviewsChart(days: Stats.ratingsByDay(events, in: start...today), calendar: model.studyCalendar)
                RetentionChart(
                    series: Stats.retentionSeries(events, in: start...today, bucketDays: bucketDays(start: start, today: today)),
                    overall: Stats.retention(inRange),
                    calendar: model.studyCalendar
                )
                ForecastChart(
                    counts: DailySet.arrivals(cards.map(\.schedule), from: today, days: 30),
                    today: today,
                    calendar: model.studyCalendar
                )
                CategoryAccuracyChart(rows: Stats.categoryAccuracy(inRange) { categories[$0] })
            }
            .padding(16)
        }
        .screenBackground()
    }

    private func startDay(events: [ReviewEvent], today: StudyDay) -> StudyDay {
        if let days = range.days { return today.adding(-(days - 1)) }
        return min(events.map(\.day).min() ?? today, today.adding(-6))
    }

    private func bucketDays(start: StudyDay, today: StudyDay) -> Int {
        let span = start.days(until: today) + 1
        return span <= 31 ? 1 : span <= 120 ? 7 : 30
    }
}

// MARK: Tiles

private struct StatTile: View {
    let label: String
    let value: Int
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Text(label.uppercased())
                .font(Theme.mono(11, .semibold))
                .tracking(1.5)
                .foregroundStyle(Theme.textDim)
            Text("\(value)")
                .font(Theme.mono(30, .bold))
                .foregroundStyle(color)
                .glow(color, radius: 8)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
            Text(unit)
                .font(Theme.mono(11))
                .foregroundStyle(Theme.textDim)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(color.opacity(0.4), lineWidth: 1))
    }
}

private struct ChartPanel<Content: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                SectionTitle(title)
                if let subtitle {
                    Text(subtitle)
                        .font(Theme.mono(12, .bold))
                        .foregroundStyle(Theme.text)
                        .fixedSize()
                }
            }
            content
        }
        .panel()
    }
}

private struct EmptyChartNote: View {
    var body: some View {
        Text("No reviews yet")
            .font(Theme.mono(12))
            .foregroundStyle(Theme.textDim)
            .frame(maxWidth: .infinity, minHeight: 80)
    }
}

// MARK: Maturity

private struct MaturityChart: View {
    let counts: [Maturity: Int]

    var body: some View {
        let total = counts.values.reduce(0, +)
        ChartPanel(title: "Card Maturity") {
            if total == 0 {
                EmptyChartNote()
            } else {
                HStack(spacing: 20) {
                    Chart(Maturity.allCases, id: \.self) { stage in
                        SectorMark(
                            angle: .value("Cards", counts[stage, default: 0]),
                            innerRadius: .ratio(0.62),
                            angularInset: 2
                        )
                        .cornerRadius(4)
                        .foregroundStyle(Theme.color(for: stage))
                    }
                    .chartBackground { _ in
                        VStack(spacing: 0) {
                            Text("\(total)")
                                .font(Theme.mono(22, .bold))
                                .foregroundStyle(Theme.text)
                            Text("CARDS")
                                .font(Theme.mono(9))
                                .foregroundStyle(Theme.textDim)
                        }
                    }
                    .frame(width: 140, height: 140)

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Maturity.allCases, id: \.self) { stage in
                            HStack(spacing: 8) {
                                Circle().fill(Theme.color(for: stage)).frame(width: 10, height: 10)
                                Text(stage.rawValue.uppercased())
                                    .font(Theme.mono(12))
                                    .foregroundStyle(Theme.textDim)
                                Spacer()
                                Text("\(counts[stage, default: 0])")
                                    .font(Theme.mono(14, .bold))
                                    .foregroundStyle(Theme.text)
                            }
                        }
                        Text("Mature = interval ≥ \(Maturity.matureThreshold)d")
                            .font(Theme.mono(10))
                            .foregroundStyle(Theme.textDim.opacity(0.7))
                    }
                }
            }
        }
    }
}

// MARK: Heatmap

/// GitHub-style calendar: one column per week, one row per weekday.
private struct HeatmapView: View {
    let counts: [StudyDay: Int]
    let start: StudyDay
    let end: StudyDay
    let calendar: StudyCalendar

    private let cell: CGFloat = 13
    private let gap: CGFloat = 3

    var body: some View {
        let leading = weekdayIndex(start)
        let total = leading + start.days(until: end) + 1
        let columns = (total + 6) / 7
        let peak = max(counts.values.max() ?? 1, 1)

        ChartPanel(title: "Activity") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: gap) {
                    ForEach(0..<columns, id: \.self) { column in
                        VStack(spacing: gap) {
                            ForEach(0..<7, id: \.self) { row in
                                square(offset: column * 7 + row - leading, peak: peak)
                            }
                        }
                    }
                }
            }
            .defaultScrollAnchor(.trailing)
            HStack(spacing: 4) {
                Text("LESS")
                ForEach([0.0, 0.3, 0.55, 0.8, 1.0], id: \.self) { level in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(level == 0 ? Theme.surfaceHigh : Theme.magenta.opacity(level))
                        .frame(width: 10, height: 10)
                }
                Text("MORE")
            }
            .font(Theme.mono(9))
            .foregroundStyle(Theme.textDim)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
    }

    @ViewBuilder
    private func square(offset: Int, peak: Int) -> some View {
        let day = start.adding(offset)
        if offset < 0 || day > end {
            Color.clear.frame(width: cell, height: cell)
        } else {
            let count = counts[day, default: 0]
            RoundedRectangle(cornerRadius: 3)
                .fill(count == 0 ? Theme.surfaceHigh : Theme.magenta.opacity(0.3 + 0.7 * Double(count) / Double(peak)))
                .frame(width: cell, height: cell)
                .overlay {
                    if day == end {
                        RoundedRectangle(cornerRadius: 3).stroke(Theme.sun, lineWidth: 1.5)
                    }
                }
        }
    }

    private func weekdayIndex(_ day: StudyDay) -> Int {
        let weekday = calendar.calendar.component(.weekday, from: calendar.start(of: day))
        return (weekday - calendar.calendar.firstWeekday + 7) % 7
    }
}

// MARK: Reviews per day

private struct ReviewsChart: View {
    let days: [DailyRatings]
    let calendar: StudyCalendar

    var body: some View {
        ChartPanel(title: "Reviews per Day") {
            if days.allSatisfy({ $0.total == 0 }) {
                EmptyChartNote()
            } else {
                Chart {
                    ForEach(days, id: \.day) { day in
                        ForEach([Rating.bad, .okay, .good], id: \.self) { rating in
                            BarMark(
                                x: .value("Day", calendar.start(of: day.day), unit: .day),
                                y: .value("Reviews", day[rating])
                            )
                            .foregroundStyle(by: .value("Rating", rating.rawValue.capitalized))
                        }
                    }
                }
                .chartForegroundStyleScale([
                    "Bad": Theme.color(for: .bad),
                    "Okay": Theme.color(for: .okay),
                    "Good": Theme.color(for: .good),
                ])
                .chartLegend(position: .bottom, alignment: .leading)
                .synthwaveAxes()
                .frame(height: 180)
            }
        }
    }
}

// MARK: Retention

private struct RetentionChart: View {
    let series: [(start: StudyDay, retention: Double)]
    let overall: Double?
    let calendar: StudyCalendar

    var body: some View {
        ChartPanel(title: "Retention", subtitle: overall.map { "\(Int(($0 * 100).rounded()))%" }) {
            if series.isEmpty {
                EmptyChartNote()
            } else {
                Chart {
                    ForEach(series, id: \.start) { point in
                        AreaMark(
                            x: .value("Day", calendar.start(of: point.start), unit: .day),
                            y: .value("Retention", point.retention * 100)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(LinearGradient(
                            colors: [Theme.magenta.opacity(0.45), Theme.magenta.opacity(0)],
                            startPoint: .top, endPoint: .bottom
                        ))
                        LineMark(
                            x: .value("Day", calendar.start(of: point.start), unit: .day),
                            y: .value("Retention", point.retention * 100)
                        )
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(Theme.magenta)
                        .lineStyle(StrokeStyle(lineWidth: 2.5))
                        PointMark(
                            x: .value("Day", calendar.start(of: point.start), unit: .day),
                            y: .value("Retention", point.retention * 100)
                        )
                        .foregroundStyle(Theme.peach)
                        .symbolSize(24)
                    }
                }
                .chartYScale(domain: 0...100)
                .synthwaveAxes()
                .frame(height: 160)
            }
        }
    }
}

// MARK: Forecast

private struct ForecastChart: View {
    let counts: [Int]
    let today: StudyDay
    let calendar: StudyCalendar

    var body: some View {
        ChartPanel(title: "Next 30 Days", subtitle: "\(counts.reduce(0, +)) due") {
            Chart {
                ForEach(Array(counts.enumerated()), id: \.offset) { offset, count in
                    BarMark(
                        x: .value("Day", calendar.start(of: today.adding(offset)), unit: .day),
                        y: .value("Cards", count)
                    )
                    .foregroundStyle(LinearGradient(colors: [Theme.blue, Theme.violet], startPoint: .top, endPoint: .bottom))
                    .cornerRadius(3)
                }
            }
            .synthwaveAxes()
            .frame(height: 150)
        }
    }
}

// MARK: Category accuracy

private struct CategoryAccuracyChart: View {
    let rows: [CategoryAccuracy]

    var body: some View {
        let shown = Array(rows.prefix(8))
        ChartPanel(title: "Weakest Categories") {
            if shown.isEmpty {
                EmptyChartNote()
            } else {
                Chart(shown, id: \.categoryPath) { row in
                    BarMark(
                        x: .value("Accuracy", row.accuracy * 100),
                        y: .value("Category", Naming.breadcrumb(row.categoryPath))
                    )
                    .foregroundStyle(LinearGradient(colors: [Theme.sun, Theme.magenta], startPoint: .leading, endPoint: .trailing))
                    .cornerRadius(4)
                    .annotation(position: .trailing) {
                        Text("\(Int((row.accuracy * 100).rounded()))%")
                            .font(Theme.mono(10, .bold))
                            .foregroundStyle(Theme.text)
                    }
                }
                .chartXScale(domain: 0...110)
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks { _ in
                        AxisValueLabel().font(Theme.mono(10)).foregroundStyle(Theme.textDim)
                    }
                }
                .frame(height: CGFloat(shown.count) * 34 + 10)
            }
        }
    }
}

private extension View {
    func synthwaveAxes() -> some View {
        chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisGridLine().foregroundStyle(Theme.violet.opacity(0.2))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.textDim)
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { _ in
                AxisGridLine().foregroundStyle(Theme.violet.opacity(0.2))
                AxisValueLabel()
                    .font(Theme.mono(9))
                    .foregroundStyle(Theme.textDim)
            }
        }
    }
}
