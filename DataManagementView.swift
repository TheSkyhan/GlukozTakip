import SwiftUI
import CoreData
import UniformTypeIdentifiers
#if os(macOS)
import AppKit
#endif

enum PDFRange: CaseIterable {
    case oneWeek
    case oneMonth
    case threeMonths
    case sixMonths
    case oneYear

    var title: String {
        switch self {
        case .oneWeek:
            return "1 Hafta"
        case .oneMonth:
            return "1 Ay"
        case .threeMonths:
            return "3 Ay"
        case .sixMonths:
            return "6 Ay"
        case .oneYear:
            return "1 Yıl"
        }
    }
}

struct DataManagementView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var csvData: Data = Data()
    @State private var showExporter = false
    @State private var showNoDataAlert = false
    @State private var exportDocument: CSVDocument? = nil
    @State private var pdfData: Data = Data()
    @State private var showPDFExporter = false
    @State private var pdfDocument: PDFDocument? = nil
    @State private var pdfRange: PDFRange = .oneWeek
    let compact: Bool

    init(compact: Bool = false) {
        self.compact = compact
    }

    var body: some View {
        Group {
            if compact {
                VStack(alignment: .leading, spacing: 24) {
                    panels
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text("Veri Yönetimi")
                            .font(.largeTitle)
                            .fontWeight(.semibold)
                        panels
                        Spacer()
                    }
                }
                .padding(32)
            }
        }
        .fileExporter(
            isPresented: $showExporter,
            document: exportDocument ?? CSVDocument(data: Data()),
            contentType: .commaSeparatedText,
            defaultFilename: "GlucoTrack_Export_\(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short).replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-").replacingOccurrences(of: " ", with: "_")).csv"
        ) { result in
            print("Exporter completed, csvData bytes:", csvData.count)
            if case .failure(let error) = result {
                print("CSV export hatası: \(error)")
            }
            showExporter = false
            exportDocument = nil
        }
        .fileExporter(
            isPresented: $showPDFExporter,
            document: pdfDocument ?? PDFDocument(data: Data()),
            contentType: .pdf,
            defaultFilename: "GlucoTrack_Report_\(DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .short).replacingOccurrences(of: "/", with: "-").replacingOccurrences(of: ":", with: "-").replacingOccurrences(of: " ", with: "_")).pdf"
        ) { result in
            print("Exporter completed, pdfData bytes:", pdfData.count)
            if case .failure(let error) = result {
                print("PDF export hatası: \(error)")
            }
            showPDFExporter = false
            pdfDocument = nil
        }
        .alert("Dışa aktarılacak veri bulunamadı", isPresented: $showNoDataAlert) {
            Button("Tamam", role: .cancel) { }
        }
    }

    private var panels: some View {
        Group {
            PremiumPanel("Dışa Aktarma", subtitle: "Tüm ölçümlerinizi CSV formatında dışa aktarın.") {
                HStack(spacing: 12) {
                    Button {
                        let data = prepareCSV()
                        if data.isEmpty {
                            showNoDataAlert = true
                        } else {
                            exportDocument = CSVDocument(data: data)
                            csvData = data
                            DispatchQueue.main.async {
                                showExporter = true
                            }
                        }
                    } label: {
                        Label("CSV Olarak Dışa Aktar", systemImage: "square.and.arrow.up")
                    }
                    .buttonStyle(.borderedProminent)

                    Button {
                        let data = preparePDF(range: pdfRange)
                        if data.isEmpty {
                            showNoDataAlert = true
                        } else {
                            pdfDocument = PDFDocument(data: data)
                            pdfData = data
                            DispatchQueue.main.async {
                                showPDFExporter = true
                            }
                        }
                    } label: {
                        Label("PDF Raporu", systemImage: "doc.richtext")
                    }
                    .buttonStyle(.bordered)
                }
                Picker("Rapor Dönemi", selection: $pdfRange) {
                    ForEach(PDFRange.allCases, id: \.self) { range in
                        Text(range.title).tag(range)
                    }
                }
                .pickerStyle(.segmented)
            }

            PremiumPanel("Tehlikeli İşlemler", subtitle: "Geri alınamaz işlemler içerir.") {
                Button(role: .destructive) {
                    deleteAllData()
                } label: {
                    Label("Tüm Verileri Sil", systemImage: "trash")
                }
            }
        }
    }

    private func prepareCSV() -> Data {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Entry.timestamp, ascending: true)
        ]

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = .current
        dateFormatter.dateFormat = "dd.MM.yyyy HH:mm"

        let header = "Tarih/Saat,Glukoz (mg/dL),Kategori,Bazal,Bolus,Notlar\n"

        guard let entries = try? viewContext.fetch(request), !entries.isEmpty else {
            return Data()
        }

        let rows = entries.map { entry in
            let date = entry.timestamp.map { dateFormatter.string(from: $0) } ?? ""
            let glucose = Int(entry.glucose)

            let categoryRaw = entry.category ?? ""
            let safeCategory = categoryRaw.replacingOccurrences(of: "\"", with: "\"\"")

            let basal = entry.basalDose?.doubleValue ?? 0
            let bolus = entry.bolusDose?.doubleValue ?? 0

            let notesRaw = entry.notes ?? ""
            let safeNotes = notesRaw.replacingOccurrences(of: "\"", with: "\"\"")

            return "\"\(date)\",\(glucose),\"\(safeCategory)\",\(basal),\(bolus),\"\(safeNotes)\""
        }.joined(separator: "\n")

        return Data((header + rows).utf8)
    }

    private func deleteAllData() {
        let request: NSFetchRequest<NSFetchRequestResult> = Entry.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

        do {
            try viewContext.execute(deleteRequest)
            viewContext.reset()
        } catch {
            print("Toplu silme hatası: \(error)")
        }
    }

    private func preparePDF(range: PDFRange) -> Data {
        let request: NSFetchRequest<Entry> = Entry.fetchRequest()
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \Entry.timestamp, ascending: true)
        ]

        guard let allEntries = try? viewContext.fetch(request), !allEntries.isEmpty else {
            return Data()
        }

        let filtered = filterEntries(allEntries, range: range)
        guard !filtered.isEmpty else { return Data() }

        let points = filtered.compactMap { entry -> PDFGlucosePoint? in
            guard let ts = entry.timestamp else { return nil }
            return PDFGlucosePoint(date: ts, glucose: entry.glucose)
        }

        let pageSize = CGSize(width: 595, height: 842) // A4 @ 72dpi
        let margin: CGFloat = 36

        let pdfData = NSMutableData()
        var mediaBox = CGRect(origin: .zero, size: pageSize)
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let ctx = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            return Data()
        }

        ctx.beginPDFPage(nil)
        ctx.translateBy(x: 0, y: pageSize.height)
        ctx.scaleBy(x: 1, y: -1)

        let contentRect = CGRect(
            x: margin,
            y: margin,
            width: pageSize.width - margin * 2,
            height: pageSize.height - margin * 2
        )

        drawPDFReport(
            in: ctx,
            rect: contentRect,
            entries: filtered,
            points: Array(points.suffix(90)),
            rangeTitle: range.title
        )

        ctx.endPDFPage()
        ctx.closePDF()
        return pdfData as Data
    }

    private func filterEntries(_ entries: [Entry], range: PDFRange) -> [Entry] {
        let calendar = Calendar.current
        let now = Date()

        let startDate: Date
        switch range {
        case .oneWeek:
            startDate = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        case .oneMonth:
            startDate = calendar.date(byAdding: .month, value: -1, to: now) ?? now
        case .threeMonths:
            startDate = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        case .sixMonths:
            startDate = calendar.date(byAdding: .month, value: -6, to: now) ?? now
        case .oneYear:
            startDate = calendar.date(byAdding: .year, value: -1, to: now) ?? now
        }

        return entries.filter {
            guard let ts = $0.timestamp else { return false }
            return ts >= startDate && ts <= now
        }
    }

    private func drawPDFReport(
        in ctx: CGContext,
        rect: CGRect,
        entries: [Entry],
        points: [PDFGlucosePoint],
        rangeTitle: String
    ) {
        let titleFont = NSFont.systemFont(ofSize: 22, weight: .bold)
        let subtitleFont = NSFont.systemFont(ofSize: 13, weight: .medium)
        let sectionFont = NSFont.systemFont(ofSize: 12, weight: .semibold)
        let bodyFont = NSFont.systemFont(ofSize: 10, weight: .regular)

        let primary = NSColor.black
        let secondary = NSColor.secondaryLabelColor

        var y = rect.minY

        drawText("GlucoTrack", font: titleFont, color: primary, at: CGPoint(x: rect.minX, y: y), in: ctx)
        drawText("Glukoz ve İnsülin Raporu", font: subtitleFont, color: secondary, at: CGPoint(x: rect.minX, y: y + 24), in: ctx)
        drawText(rangeTitle, font: subtitleFont, color: secondary, at: CGPoint(x: rect.minX, y: y + 40), in: ctx)

        let dateText = DateFormatter.localizedString(from: Date(), dateStyle: .medium, timeStyle: .none)
        let dateSize = textSize(dateText, font: subtitleFont)
        drawText(dateText, font: subtitleFont, color: secondary, at: CGPoint(x: rect.maxX - dateSize.width, y: y + 4), in: ctx)

        y += 70

        let statsHeight: CGFloat = 54
        let statWidth = (rect.width - 16 * 2) / 3
        let avg = entries.map { $0.glucose }.reduce(0, +) / Double(max(entries.count, 1))
        let minVal = entries.map { $0.glucose }.min() ?? 0
        let maxVal = entries.map { $0.glucose }.max() ?? 0

        drawStatBox(title: "Ortalama", value: "\(Int(avg)) mg/dL", color: PremiumPalette.calmBlue, frame: CGRect(x: rect.minX, y: y, width: statWidth, height: statsHeight), in: ctx)
        drawStatBox(title: "En Düşük", value: "\(Int(minVal)) mg/dL", color: PremiumPalette.danger, frame: CGRect(x: rect.minX + statWidth + 16, y: y, width: statWidth, height: statsHeight), in: ctx)
        drawStatBox(title: "En Yüksek", value: "\(Int(maxVal)) mg/dL", color: PremiumPalette.warning, frame: CGRect(x: rect.minX + (statWidth + 16) * 2, y: y, width: statWidth, height: statsHeight), in: ctx)

        y += statsHeight + 24

        drawText("Son Ölçümler (Grafik)", font: sectionFont, color: primary, at: CGPoint(x: rect.minX, y: y), in: ctx)
        y += 18

        let chartHeight: CGFloat = 180
        let chartRect = CGRect(x: rect.minX, y: y, width: rect.width, height: chartHeight)
        drawChart(in: ctx, rect: chartRect, points: points)

        y += chartHeight + 20

        drawText("Haftalık Ölçüm Tablosu", font: sectionFont, color: primary, at: CGPoint(x: rect.minX, y: y), in: ctx)
        y += 18

        let tableRect = CGRect(x: rect.minX, y: y, width: rect.width, height: rect.maxY - y)
        drawWeeklyTable(in: ctx, rect: tableRect, entries: entries, font: bodyFont, headerFont: sectionFont)
    }

    private func drawText(_ text: String, font: NSFont, color: NSColor, at point: CGPoint, in ctx: CGContext) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color
        ]
        let attr = NSAttributedString(string: text, attributes: attributes)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: true)
        attr.draw(at: point)
        NSGraphicsContext.restoreGraphicsState()
    }

    private func textSize(_ text: String, font: NSFont) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        return (text as NSString).size(withAttributes: attributes)
    }

    private func drawStatBox(title: String, value: String, color: Color, frame: CGRect, in ctx: CGContext) {
        let nsColor = NSColor(color)
        ctx.setFillColor(NSColor(calibratedWhite: 0.96, alpha: 1.0).cgColor)
        ctx.fill(frame)

        drawText(title, font: NSFont.systemFont(ofSize: 10, weight: .semibold), color: NSColor.secondaryLabelColor, at: CGPoint(x: frame.minX + 8, y: frame.minY + 6), in: ctx)
        drawText(value, font: NSFont.systemFont(ofSize: 14, weight: .bold), color: nsColor, at: CGPoint(x: frame.minX + 8, y: frame.minY + 24), in: ctx)
    }

    private func drawChart(in ctx: CGContext, rect: CGRect, points: [PDFGlucosePoint]) {
        ctx.setFillColor(NSColor(calibratedWhite: 0.96, alpha: 1).cgColor)
        ctx.fill(rect)

        guard points.count > 1 else {
            drawText("Grafik için yeterli veri yok", font: NSFont.systemFont(ofSize: 10, weight: .medium), color: NSColor.secondaryLabelColor, at: CGPoint(x: rect.minX + 8, y: rect.minY + rect.height / 2 - 6), in: ctx)
            return
        }

        let minVal = points.map { $0.glucose }.min() ?? 0
        let maxVal = points.map { $0.glucose }.max() ?? 1
        let range = maxVal == minVal ? 1 : maxVal - minVal

        let strideBy = max(points.count / 10, 1)
        let accent = NSColor(PremiumPalette.accent)

        let path = CGMutablePath()
        for (idx, point) in points.enumerated() {
            let x = rect.minX + rect.width * CGFloat(idx) / CGFloat(max(points.count - 1, 1))
            let y = rect.maxY - rect.height * CGFloat((point.glucose - minVal) / range)
            if idx == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }

            if idx % strideBy == 0 || idx == points.count - 1 {
                drawText("\(Int(point.glucose))", font: NSFont.systemFont(ofSize: 9, weight: .semibold), color: NSColor.secondaryLabelColor, at: CGPoint(x: x + 2, y: max(rect.minY + 2, y - 10)), in: ctx)
            }
        }
        ctx.addPath(path)
        ctx.setStrokeColor(accent.cgColor)
        ctx.setLineWidth(1.5)
        ctx.strokePath()
    }

    private func drawWeeklyTable(in ctx: CGContext, rect: CGRect, entries: [Entry], font: NSFont, headerFont: NSFont) {
        let rows = weeklySlots(from: entries)
        let colWidths: [CGFloat] = [90, 70, 70, 70, 70]
        let startX = rect.minX
        var y = rect.minY

        let headerTitles = ["Tarih", "Sabah", "Öğlen", "Akşam", "Yatma"]
        var x = startX
        for (idx, title) in headerTitles.enumerated() {
            drawText(title, font: headerFont, color: NSColor.secondaryLabelColor, at: CGPoint(x: x, y: y), in: ctx)
            x += colWidths[idx]
        }
        y += 16

        for row in rows {
            var colX = startX
            let values = [
                row.dateString,
                row.morningText,
                row.noonText,
                row.eveningText,
                row.bedtimeText
            ]
            for (idx, value) in values.enumerated() {
                drawText(value, font: font, color: NSColor.black, at: CGPoint(x: colX, y: y), in: ctx)
                colX += colWidths[idx]
            }
            y += 14
            if y > rect.maxY - 14 {
                break
            }
        }
    }

    private func weeklySlots(from entries: [Entry]) -> [PDFDaySlots] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
        let days = (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: start) }

        let dayEntries = entries.compactMap { entry -> (Date, Entry)? in
            guard let ts = entry.timestamp else { return nil }
            let day = calendar.startOfDay(for: ts)
            guard day >= start && day <= today else { return nil }
            return (day, entry)
        }

        var map: [Date: [String: Entry]] = [:]
        for (day, entry) in dayEntries {
            guard let category = entry.category else { continue }
            let existing = map[day]?[category]
            if existing == nil || (existing?.timestamp ?? .distantPast) < (entry.timestamp ?? .distantPast) {
                var dayMap = map[day] ?? [:]
                dayMap[category] = entry
                map[day] = dayMap
            }
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM"

        return days.map { day in
            let dayMap = map[day] ?? [:]
            return PDFDaySlots(
                date: day,
                dateString: formatter.string(from: day),
                morning: dayMap["Açlık"]?.glucose,
                noon: dayMap["Yemek Öncesi"]?.glucose,
                evening: dayMap["Yemek Sonrası"]?.glucose,
                bedtime: dayMap["Yatma Zamanı"]?.glucose
            )
        }
    }
}

struct CSVDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        .init(regularFileWithContents: data)
    }
}

struct PDFDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.pdf] }

    let data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        self.data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        .init(regularFileWithContents: data)
    }
}

private struct PDFGlucosePoint: Identifiable {
    let id = UUID()
    let date: Date
    let glucose: Double
}

private struct PDFDaySlots: Identifiable {
    let id = UUID()
    let date: Date
    let dateString: String
    let morning: Double?
    let noon: Double?
    let evening: Double?
    let bedtime: Double?

    var morningText: String { format(morning) }
    var noonText: String { format(noon) }
    var eveningText: String { format(evening) }
    var bedtimeText: String { format(bedtime) }

    private func format(_ value: Double?) -> String {
        guard let value else { return "-" }
        return "\(Int(value))"
    }
}
