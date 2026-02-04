import SwiftUI
import Charts
import CoreData

struct ReportsView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp, order: .reverse)]) private var entries: FetchedResults<Entry>
    
    @AppStorage("targetLow") private var targetLow: Double = 70
    @AppStorage("targetHigh") private var targetHigh: Double = 180
    
    @State private var selectedPeriod: Int = 7
    let periods = [7, 14, 30, 90]
    
    private var periodData: [GlucosePoint] {
        let calendar = Calendar.current
        let cutoff = calendar.date(byAdding: .day, value: -selectedPeriod, to: Date())!
        let filtered = entries.filter {
            if let ts = $0.timestamp {
                return ts >= cutoff
            }
            return false
        }
        return filtered
            .sorted {
                ($0.timestamp ?? .distantPast) < ($1.timestamp ?? .distantPast)
            }
            .compactMap {
                guard let ts = $0.timestamp else { return nil }
                return GlucosePoint(date: ts, glucose: $0.glucose)
            }
    }
    
    private var timeInRange: (low: Int, normal: Int, high: Int) {
        let low = entries.filter { $0.glucose < targetLow }.count
        let normal = entries.filter { $0.glucose >= targetLow && $0.glucose <= targetHigh }.count
        let high = entries.filter { $0.glucose > targetHigh }.count
        return (low, normal, high)
    }
    
    private var periodAverage: Double {
        guard !periodData.isEmpty else { return 0 }
        return periodData.reduce(0.0) { $0 + $1.glucose } / Double(periodData.count)
    }
    
    private func levelColor(for glucose: Double) -> Color {
        if glucose < targetLow { return PremiumPalette.danger.opacity(0.5) }
        else if glucose <= targetHigh { return PremiumPalette.success.opacity(0.5) }
        else { return PremiumPalette.warning.opacity(0.5) }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Picker("Dönem", selection: $selectedPeriod) {
                    ForEach(periods, id: \.self) { Text("\($0) Gün") }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if entries.isEmpty {
                    ContentUnavailableView("Henüz veri yok", systemImage: "chart.line.uptrend.xyaxis", description: Text("Rapor için ölçüm ekleyin."))
                } else {
                    let chartData = periodData
                    
                    HStack(alignment: .top, spacing: 16) {
                        // Line Chart with LineMark + PointMark
                        VStack {
                            Text("Glukoz Değerleri")
                                .font(.headline)
                                .foregroundColor(.primary)
                            Chart {
                                ForEach(chartData) { point in
                                    LineMark(
                                        x: .value("Tarih", point.date),
                                        y: .value("Glukoz", point.glucose)
                                    )
                                    .foregroundStyle(PremiumPalette.accent)
                                    
                                    PointMark(
                                        x: .value("Tarih", point.date),
                                        y: .value("Glukoz", point.glucose)
                                    )
                                    .foregroundStyle(PremiumPalette.accent)
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 7)) { value in
                                    AxisValueLabel {
                                        if let date = value.as(Date.self) {
                                            Text(date, format: Date.FormatStyle().day(.defaultDigits).month(.defaultDigits))
                                        }
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks()
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: 350)
                        .premiumCard(padding: 16, radius: 20)
                        
                        // Pie Chart with SectorMark
                        HStack(alignment: .center, spacing: 16) {
                            Chart {
                                SectorMark(
                                    angle: .value("Düşük", Double(timeInRange.low)),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.0
                                )
                                .foregroundStyle(PremiumPalette.danger.opacity(0.6))
                                
                                SectorMark(
                                    angle: .value("Normal", Double(timeInRange.normal)),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.0
                                )
                                .foregroundStyle(PremiumPalette.success.opacity(0.6))
                                
                                SectorMark(
                                    angle: .value("Yüksek", Double(timeInRange.high)),
                                    innerRadius: .ratio(0.5),
                                    angularInset: 1.0
                                )
                                .foregroundStyle(PremiumPalette.warning.opacity(0.6))
                            }
                            .frame(width: 200, height: 200)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Yüksek: \(timeInRange.high) kayıt")
                                    .foregroundColor(PremiumPalette.warning.opacity(0.85))
                                Text("Normal: \(timeInRange.normal) kayıt")
                                    .foregroundColor(PremiumPalette.success.opacity(0.85))
                                Text("Düşük: \(timeInRange.low) kayıt")
                                    .foregroundColor(PremiumPalette.danger.opacity(0.85))
                            }
                            .font(.subheadline)
                        }
                        .premiumCard(padding: 16, radius: 20)
                    }
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                        if let maxGlucoseEntry = entries.max(by: { $0.glucose < $1.glucose }),
                           let ts = maxGlucoseEntry.timestamp {
                            let formattedDate = {
                                let formatter = DateFormatter()
                                formatter.dateStyle = .short
                                formatter.timeStyle = .short
                                return formatter.string(from: ts)
                            }()
                            GradientSummaryCard(
                                title: "En Yüksek Glukoz",
                                value: "\(Int(maxGlucoseEntry.glucose)) mg/dL (\(formattedDate))",
                                icon: "arrow.up.circle.fill",
                                gradientColors: [PremiumPalette.danger, PremiumPalette.warning]
                            )
                        }

                        if let maxBolusEntry = entries.max(by: { ($0.bolusDose?.doubleValue ?? 0) < ($1.bolusDose?.doubleValue ?? 0) }),
                           let bolus = maxBolusEntry.bolusDose {
                            GradientSummaryCard(
                                title: "En Yüksek Bolus",
                                value: "\(String(format: "%.1f", bolus.doubleValue)) birim",
                                icon: "syringe.fill",
                                gradientColors: [PremiumPalette.indigo, PremiumPalette.calmBlue]
                            )
                        }

                        if let maxBasalEntry = entries.max(by: { ($0.basalDose?.doubleValue ?? 0) < ($1.basalDose?.doubleValue ?? 0) }),
                           let basal = maxBasalEntry.basalDose {
                            GradientSummaryCard(
                                title: "En Yüksek Bazal",
                                value: "\(String(format: "%.1f", basal.doubleValue)) birim",
                                icon: "drop.fill",
                                gradientColors: [PremiumPalette.accent, PremiumPalette.calmTeal]
                            )
                        }

                        if let minGlucoseEntry = entries.min(by: { $0.glucose < $1.glucose }),
                           let ts = minGlucoseEntry.timestamp {
                            let formattedDate = {
                                let formatter = DateFormatter()
                                formatter.dateStyle = .short
                                formatter.timeStyle = .short
                                return formatter.string(from: ts)
                            }()
                            GradientSummaryCard(
                                title: "En Düşük Glukoz",
                                value: "\(Int(minGlucoseEntry.glucose)) mg/dL (\(formattedDate))",
                                icon: "arrow.down.circle.fill",
                                gradientColors: [PremiumPalette.calmTeal, PremiumPalette.success]
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding()
        }
        .navigationTitle("Raporlar")
    }
}
