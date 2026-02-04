import SwiftUI
import CoreData

struct MeasurementsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(sortDescriptors: [SortDescriptor(\.timestamp, order: .reverse)]) private var entries: FetchedResults<Entry>
    
    @State private var searchText = ""
    @State private var selectedEntryID: Entry.ID?
    @State private var selection = Set<Entry.ID>()
    
    @AppStorage("targetLow") private var targetLow: Double = 70
    @AppStorage("targetHigh") private var targetHigh: Double = 180
    
    private var filteredEntries: [Entry] {
        if searchText.isEmpty {
            return Array(entries)
        } else {
            return entries.filter {
                String($0.glucose).contains(searchText) ||
                ($0.category?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                ($0.notes?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
    }
    
    var body: some View {
        VStack {
            PremiumTextField(title: "Ara", text: $searchText)
                .padding()
            
            if filteredEntries.isEmpty {
                ContentUnavailableView("Henüz ölçüm yok", systemImage: "tray", description: Text("Kayıt Girişi'nden ekleyin."))
            } else {
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredEntries) { entry in
                            MeasurementCardView(entry: entry, targetLow: targetLow, targetHigh: targetHigh)
                                .contextMenu {
                                    Button("Düzenle") {
                                        selectedEntryID = entry.id
                                    }
                                    Button("Sil", role: .destructive) {
                                        viewContext.delete(entry)
                                        do {
                                            try viewContext.save()
                                        } catch {
                                            print("Error deleting entry: \(error.localizedDescription)")
                                        }
                                    }
                                }
                                .onTapGesture(count: 2) {
                                    selectedEntryID = entry.id
                                }
                                .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
        }
        .sheet(item: Binding(
            get: {
                filteredEntries.first { $0.id == selectedEntryID }
            },
            set: { _ in
                selectedEntryID = nil
            }
        )) { entry in
            EditEntryView(entry: entry)
                .environment(\.managedObjectContext, viewContext)
        }
        .navigationTitle("Tüm Ölçümler")
    }
    
    private func color(for glucose: Double) -> Color {
        if glucose < targetLow { return PremiumPalette.danger }
        else if glucose <= targetHigh { return PremiumPalette.success }
        else { return PremiumPalette.warning }
    }
}

struct MeasurementCardView: View {
    let entry: Entry
    let targetLow: Double
    let targetHigh: Double
    @State private var isHovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(entry.timestamp ?? Date(), format: .dateTime.year().month().day().hour().minute())
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Text("\(Int(entry.glucose)) mg/dL")
                    .font(.title2.bold())
                    .foregroundColor(color(for: entry.glucose))
                statusChip(for: entry.glucose)
            }
            Text("Kategori: \(entry.category ?? "-")")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.secondary)
            HStack {
                Text("Bazal: \(String(format: "%.1f", entry.basalDose?.doubleValue ?? 0))")
                Text("Bolus: \(String(format: "%.1f", entry.bolusDose?.doubleValue ?? 0))")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            if let notes = entry.notes, !notes.isEmpty {
                Text("Notlar: \(notes)")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .premiumCard(padding: 16, radius: 18)
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(isHovering ? PremiumPalette.accentSoft.opacity(0.8) : Color.clear, lineWidth: 1)
        )
        .scaleEffect(isHovering ? 1.01 : 1.0)
        .shadow(color: Color.black.opacity(isHovering ? 0.22 : 0.14), radius: isHovering ? 16 : 10, x: 0, y: isHovering ? 10 : 6)
        .animation(.easeInOut(duration: 0.18), value: isHovering)
        .onHover { isHovering = $0 }
    }

    private func color(for glucose: Double) -> Color {
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
}
