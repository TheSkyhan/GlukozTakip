import SwiftUI
import CoreData

struct InsulinGradientCard: View {
    let title: String
    let value: String
    let icon: String
    let gradientColors: [Color]

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.white)
            VStack(alignment: .leading) {
                Text(title)
                    .font(.title3.bold())
                    .foregroundColor(.white.opacity(0.85))
                Text(value)
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
            Spacer()
        }
        .padding()
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

struct InsulinLogView: View {
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp, order: .reverse)]) private var entries: FetchedResults<Entry>
    
    private var insulinEntries: [Entry] {
        entries.filter {
            ($0.basalDose?.doubleValue ?? 0) > 0 ||
            ($0.bolusDose?.doubleValue ?? 0) > 0
        }
    }
    
    private var dailyTotals: [(date: Date, basal: Double, bolus: Double, total: Double)] {
        let calendar = Calendar.current
        var totals: [Date: (basal: Double, bolus: Double)] = [:]
        
        for entry in insulinEntries {
            guard let ts = entry.timestamp else { continue }
            let day = calendar.startOfDay(for: ts)
            let current = totals[day] ?? (0.0, 0.0)
            totals[day] = (
                current.basal + (entry.basalDose?.doubleValue ?? 0),
                current.bolus + (entry.bolusDose?.doubleValue ?? 0)
            )
        }
        
        return totals.map { (date: $0.key, basal: $0.value.basal, bolus: $0.value.bolus, total: $0.value.basal + $0.value.bolus) }
            .sorted { $0.date > $1.date }
    }
    
    private var todayTotal: Double {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return dailyTotals.first { calendar.isDate($0.date, inSameDayAs: today) }?.total ?? 0
    }
    
    private let gradientColors = [PremiumPalette.accent.opacity(0.85), PremiumPalette.calmTeal.opacity(0.55)]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
                    InsulinGradientCard(
                        title: "Bugünkü Toplam İnsülin",
                        value: "\(String(format: "%.1f", todayTotal)) birim",
                        icon: "syringe",
                        gradientColors: gradientColors
                    )
                    InsulinGradientCard(
                        title: "Kayıtlı Gün Sayısı",
                        value: "\(dailyTotals.count) gün",
                        icon: "calendar",
                        gradientColors: gradientColors
                    )
                }
                .padding(.horizontal)
                
                if insulinEntries.isEmpty {
                    ContentUnavailableView("Henüz insülin kaydı yok", systemImage: "syringe", description: Text("Kayıt Girişi'nden ekleyin."))
                } else {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Günlük Toplamlar")
                            .font(.title3.bold())
                            .padding(.horizontal)
                        
                        ForEach(dailyTotals, id: \.date) { item in
                            VStack(alignment: .leading) {
                                Text(item.date, format: .dateTime.year().month().day())
                                    .font(.title3.bold())
                                HStack {
                                    Text("Bazal: \(String(format: "%.1f", item.basal))")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.white.opacity(0.85))
                                    Text("Bolus: \(String(format: "%.1f", item.bolus))")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.white.opacity(0.85))
                                    Spacer()
                                    Text("Toplam: \(String(format: "%.1f", item.total)) birim")
                                        .foregroundColor(.white)
                                        .font(.headline.bold())
                                }
                            }
                            .padding()
                            .background(
                                LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: PremiumTheme.innerRadius, style: .continuous)
                                    .stroke(PremiumTheme.softBorder)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: PremiumTheme.innerRadius, style: .continuous))
                            .shadow(color: gradientColors.last!.opacity(0.22), radius: 6, x: 0, y: 4)
                            .padding(.horizontal)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Detaylı Kayıtlar")
                            .font(.title3.bold())
                            .padding(.horizontal)
                        
                        ForEach(insulinEntries) { entry in
                            VStack(alignment: .leading, spacing: 8) {
                                if let ts = entry.timestamp {
                                    Text(ts, format: .dateTime.hour().minute())
                                        .font(.title3.bold())
                                } else {
                                    Text("-")
                                        .font(.title3.bold())
                                }
                                HStack {
                                    Text("Bazal: \(String(format: "%.1f", entry.basalDose?.doubleValue ?? 0))")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.white.opacity(0.85))
                                    Text("Bolus: \(String(format: "%.1f", entry.bolusDose?.doubleValue ?? 0))")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.white.opacity(0.85))
                                    Spacer()
                                    Text("Toplam: \(String(format: "%.1f", (entry.basalDose?.doubleValue ?? 0) + (entry.bolusDose?.doubleValue ?? 0)))")
                                        .font(.headline.bold())
                                }
                                if let notes = entry.notes, !notes.isEmpty {
                                    Text(notes)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(.white.opacity(0.85))
                                }
                            }
                            .padding()
                            .background(
                                LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: PremiumTheme.innerRadius, style: .continuous)
                                    .stroke(PremiumTheme.softBorder)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: PremiumTheme.innerRadius, style: .continuous))
                            .shadow(color: gradientColors.last!.opacity(0.22), radius: 6, x: 0, y: 4)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("İnsülin Kayıtları")
    }
}
