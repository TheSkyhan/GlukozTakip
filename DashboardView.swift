import SwiftUI
import Charts
import CoreData

struct GlucosePoint: Identifiable, Equatable, Hashable {
    let id = UUID()
    let date: Date
    let glucose: Double
}

struct DashboardView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp, order: .reverse)]) private var entries: FetchedResults<Entry>

    @AppStorage("targetLow") private var targetLow: Double = 70
    @AppStorage("targetHigh") private var targetHigh: Double = 180
    @State private var selectedPoint: GlucosePoint?
    @State private var isChartHovering = false

    private var last7DaysData: [GlucosePoint] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -7, to: Date())!
        let filtered = entries.compactMap { entry -> Entry? in
            guard let ts = entry.timestamp, ts >= cutoff else { return nil }
            return entry
        }
        return filtered
            .sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
            .compactMap {
                guard let ts = $0.timestamp else { return nil }
                return GlucosePoint(date: ts, glucose: $0.glucose)
            }
    }

    private var minGlucose: Double {
        last7DaysData.map { $0.glucose }.min() ?? 40
    }

    private var maxGlucose: Double {
        last7DaysData.map { $0.glucose }.max() ?? 350
    }

    private var todayEntries: [Entry] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        return entries.compactMap {
            guard let ts = $0.timestamp, ts >= today, ts < tomorrow else { return nil }
            return $0
        }
    }

    private var todayAverage: Double {
        guard !todayEntries.isEmpty else { return 0 }
        return todayEntries.reduce(0.0) { $0 + $1.glucose } / Double(todayEntries.count)
    }

    private var latestEntry: Entry? { entries.first }

    private var trendArrow: String {
        let sorted = entries.compactMap { $0.timestamp == nil ? nil : $0 }
            .sorted { ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast) }
        guard sorted.count >= 2, let last = sorted.last, let prev = sorted.dropLast().last else { return "" }
        let delta = last.glucose - prev.glucose
        if abs(delta) < 5 { return "→" }
        else if delta > 20 { return "↑↑" }
        else if delta > 5 { return "↑" }
        else if delta < -20 { return "↓↓" }
        else if delta < -5 { return "↓" }
        else { return "→" }
    }

    private var todayInsulin: Double {
        todayEntries.reduce(0.0) {
            $0 + ($1.basalDose?.doubleValue ?? 0.0) + ($1.bolusDose?.doubleValue ?? 0.0)
        }
    }

    private var timeInRangePercent: Double {
        guard !entries.isEmpty else { return 0 }
        let inRange = entries.filter { $0.glucose >= targetLow && $0.glucose <= targetHigh }.count
        return Double(inRange) / Double(entries.count) * 100
    }

    private var estimatedA1c: Double {
        guard !entries.isEmpty else { return 0 }
        let avg = entries.reduce(0.0) { $0 + $1.glucose } / Double(entries.count)
        return (avg + 46.7) / 28.7
    }

    private func levelColor(for glucose: Double) -> Color {
        if glucose < targetLow { return PremiumPalette.danger }
        else if glucose <= targetHigh { return PremiumPalette.success }
        else { return PremiumPalette.warning }
    }

    private func statusChip(for glucose: Double) -> some View {
        let label: String
        let color: Color
        if glucose < targetLow {
            label = "Düşük"
            color = PremiumPalette.danger
        } else if glucose <= targetHigh {
            label = "Hedefte"
            color = PremiumPalette.success
        } else {
            label = "Yüksek"
            color = PremiumPalette.warning
        }
        return PremiumStatusChip(title: label, color: color)
    }

    private func nearestPoint(to date: Date, in data: [GlucosePoint]) -> GlucosePoint? {
        guard !data.isEmpty else { return nil }
        return data.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
    }
    
    private var thisMonthMinValueString: String {
        let calendar = Calendar.current
        let minEntryThisMonth = entries
            .filter { entry in
                guard let ts = entry.timestamp else { return false }
                return calendar.isDate(ts, equalTo: Date(), toGranularity: .month)
            }
            .min(by: { $0.glucose < $1.glucose })

        if let minEntry = minEntryThisMonth, let ts = minEntry.timestamp {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return "\(Int(minEntry.glucose)) mg/dL (\(formatter.string(from: ts)))"
        } else {
            return "-"
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if last7DaysData.isEmpty {
                    ContentUnavailableView("Henüz veri yok", systemImage: "chart.line.uptrend.xyaxis", description: Text("Kayıt Girişi'nden ölçüm ekleyin."))
                        .padding(40)
                } else {
                    chartCard
                }

                LazyVGrid(columns: Array(repeating: .init(.flexible()), count: 2), spacing: 20) {
                    GradientSummaryCard(title: "Son Ölçüm",
                                       value: latestEntry.map { "\(String(format: "%.0f", $0.glucose)) mg/dL \(trendArrow)" } ?? "-",
                                       icon: "drop.fill",
                                       gradientColors: [PremiumPalette.danger, PremiumPalette.warning])
                    GradientSummaryCard(title: "Bugünün Ortalaması",
                                       value: "\(String(format: "%.0f", todayAverage)) mg/dL",
                                       icon: "chart.bar.fill",
                                       gradientColors: [PremiumPalette.calmTeal, PremiumPalette.success])
                    GradientSummaryCard(title: "Aralıkta Zaman",
                                       value: "\(String(format: "%.1f", timeInRangePercent))%",
                                       icon: "clock.fill",
                                       gradientColors: [PremiumPalette.accent, PremiumPalette.indigo])
                    GradientSummaryCard(title: "Tahmini HbA1c",
                                       value: "\(String(format: "%.1f", estimatedA1c))%",
                                       icon: "waveform.path.ecg",
                                       gradientColors: [PremiumPalette.indigo, PremiumPalette.calmBlue])
                    GradientSummaryCard(title: "Bugünkü İnsülin",
                                       value: "\(String(format: "%.1f", todayInsulin)) birim",
                                       icon: "syringe",
                                       gradientColors: [PremiumPalette.calmBlue, PremiumPalette.accent])
                    
                    GradientSummaryCard(
                        title: "Bu Ayın En Düşüğü",
                        value: thisMonthMinValueString,
                        icon: "arrow.down.circle.fill",
                        gradientColors: [PremiumPalette.calmTeal, PremiumPalette.accent]
                    )
                }
                .padding(.horizontal, 20)
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity)
        .navigationTitle("Gösterge Paneli")
    }

    private var chartCard: some View {
        let chartMin = max(0, minGlucose - 20)
        let chartMax = max(120, maxGlucose + 20)
        let data = last7DaysData

        return VStack(spacing: 10) {
            Chart {
                backgroundRanges(minGlucose: minGlucose, maxGlucose: maxGlucose)
                glucoseArea(data, baseline: chartMin)
                glucoseLines(data)
                chartRules(chartMin: chartMin, chartMax: chartMax)
                if let selectedPoint {
                    RuleMark(x: .value("Seçim", selectedPoint.date))
                        .foregroundStyle(PremiumPalette.accent.opacity(0.5))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4]))
                    PointMark(
                        x: .value("Tarih", selectedPoint.date),
                        y: .value("Glukoz", selectedPoint.glucose)
                    )
                    .symbolSize(80)
                    .foregroundStyle(PremiumPalette.accent)
                }
            }
            .chartYScale(domain: chartMin...chartMax)
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 7)) {
                    AxisGridLine().foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel(format: .dateTime.day().month())
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine().foregroundStyle(.secondary.opacity(0.15))
                    AxisValueLabel()
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    if let frame = proxy.plotFrame {
                                        let origin = geo[frame].origin
                                        let locationX = value.location.x - origin.x
                                        if let date: Date = proxy.value(atX: locationX) {
                                            selectedPoint = nearestPoint(to: date, in: data)
                                        }
                                    }
                                }
                                .onEnded { _ in
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                        selectedPoint = nil
                                    }
                                }
                        )
                }
            }
            .frame(height: 340)
            .overlay(alignment: .topLeading) {
                if let selectedPoint {
                    VStack(alignment: .leading, spacing: 6) {
                        statusChip(for: selectedPoint.glucose)
                        Text(selectedPoint.date, format: .dateTime.day().month().hour().minute())
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(Int(selectedPoint.glucose)) mg/dL")
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(levelColor(for: selectedPoint.glucose))
                    }
                    .padding(10)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(PremiumTheme.softBorder)
                    )
                    .padding(12)
                }
            }

            HStack(spacing: 8) {
                RangeLegendDot(title: "Düşük", color: PremiumPalette.danger)
                RangeLegendDot(title: "Hedef", color: PremiumPalette.success)
                RangeLegendDot(title: "Yüksek", color: PremiumPalette.warning)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 2)
        }
        .frame(maxWidth: 1200)
        .premiumCard(padding: 16, radius: 22)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [
                            PremiumPalette.accent.opacity(isChartHovering ? 0.35 : 0.18),
                            PremiumPalette.calmTeal.opacity(isChartHovering ? 0.25 : 0.10)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
                .blendMode(.plusLighter)
        }
        .shadow(color: PremiumPalette.accent.opacity(isChartHovering ? 0.18 : 0.08), radius: isChartHovering ? 18 : 12, x: 0, y: 10)
        .animation(.easeInOut(duration: 0.2), value: isChartHovering)
        .onHover { isChartHovering = $0 }
    }
}

// MARK: - Chart Background Ranges
@ChartContentBuilder
private func backgroundRanges(minGlucose: Double, maxGlucose: Double) -> some ChartContent {
    if minGlucose < 80 {
        RectangleMark(
            yStart: .value("Alt Kritik", 0),
            yEnd: .value("Alt Hedef", min(50, minGlucose))
        )
        .foregroundStyle(
            LinearGradient(colors: [PremiumPalette.danger.opacity(0.22), PremiumPalette.danger.opacity(0.06)], startPoint: .top, endPoint: .bottom)
        )
    }
    
    RectangleMark(
        yStart: .value("Hedef Alt", 80),
        yEnd: .value("Hedef Üst", 120)
    )
    .foregroundStyle(
        LinearGradient(colors: [PremiumPalette.success.opacity(0.18), PremiumPalette.success.opacity(0.05)], startPoint: .top, endPoint: .bottom)
    )
    
    if maxGlucose > 120 {
        RectangleMark(
            yStart: .value("Yüksek Hedef", max(120, minGlucose)),
            yEnd: .value("Üst Kritik", maxGlucose + 20)
        )
        .foregroundStyle(
            LinearGradient(colors: [PremiumPalette.warning.opacity(0.18), PremiumPalette.warning.opacity(0.05)], startPoint: .top, endPoint: .bottom)
        )
    }
}

// MARK: - Chart Data Lines
@ChartContentBuilder
private func glucoseLines(_ data: [GlucosePoint]) -> some ChartContent {
    ForEach(data) { point in
        LineMark(
            x: .value("Tarih", point.date),
            y: .value("Glukoz", point.glucose)
        )
        .interpolationMethod(.catmullRom)
        .lineStyle(StrokeStyle(lineWidth: 2.5))
        .foregroundStyle(LinearGradient(colors: [PremiumPalette.accent, PremiumPalette.calmTeal], startPoint: .top, endPoint: .bottom))
        
        PointMark(
            x: .value("Tarih", point.date),
            y: .value("Glukoz", point.glucose)
        )
        .symbol(Circle())
        .symbolSize(60)
        .foregroundStyle(LinearGradient(colors: [PremiumPalette.accent, PremiumPalette.calmTeal], startPoint: .top, endPoint: .bottom))
        .annotation(position: .top, spacing: 4) {
            Text("\(Int(point.glucose))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Chart Area
@ChartContentBuilder
private func glucoseArea(_ data: [GlucosePoint], baseline: Double) -> some ChartContent {
    ForEach(data) { point in
        AreaMark(
            x: .value("Tarih", point.date),
            yStart: .value("Başlangıç", baseline),
            yEnd: .value("Glukoz", point.glucose)
        )
        .interpolationMethod(.catmullRom)
        .foregroundStyle(
            LinearGradient(
                colors: [PremiumPalette.accent.opacity(0.25), PremiumPalette.calmTeal.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

// MARK: - Chart Rule Marks
@ChartContentBuilder
private func chartRules(chartMin: Double, chartMax: Double) -> some ChartContent {
    let altRule = max(50, chartMin)
    let üstRule = min(120, chartMax)
    
    RuleMark(y: .value("Alt Hedef", altRule))
        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6]))
        .foregroundStyle(PremiumPalette.danger.opacity(0.6))
    
    RuleMark(y: .value("Hedef Üst", üstRule))
        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6]))
        .foregroundStyle(PremiumPalette.success.opacity(0.6))
}

// MARK: - GradientSummaryCard
struct GradientSummaryCard: View {
    let title: String
    let value: String
    let icon: String
    let gradientColors: [Color]

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.white.opacity(0.95))
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white.opacity(0.9))
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding()
        .frame(height: 80)
        .background(
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PremiumTheme.innerRadius, style: .continuous)
                .stroke(PremiumTheme.softBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: PremiumTheme.innerRadius, style: .continuous))
        .shadow(color: gradientColors.last!.opacity(0.22), radius: 6, x: 0, y: 4)
    }
}

private struct RangeLegendDot: View {
    let title: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color.white.opacity(0.4))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(PremiumTheme.softBorder)
        )
    }
}
