import SwiftUI
import CoreData

struct GradientInputCard<Content: View>: View {
    let title: String
    let icon: String
    let gradientColors: [Color]
    let content: Content

    init(title: String, icon: String, gradientColors: [Color], @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.gradientColors = gradientColors
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.white)
                Text(title)
                    .font(.title2.weight(.semibold))
                    .foregroundColor(.white)
                Spacer()
            }
            content
        }
        .padding()
        .background(
            LinearGradient(colors: gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .overlay(
            RoundedRectangle(cornerRadius: PremiumTheme.cornerRadius, style: .continuous)
                .stroke(PremiumTheme.softBorder)
        )
        .clipShape(RoundedRectangle(cornerRadius: PremiumTheme.cornerRadius, style: .continuous))
        .shadow(color: gradientColors.last!.opacity(0.22), radius: 10, x: 0, y: 6)
    }
}

struct EditEntryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss

    let entry: Entry? // nil = yeni, dolu = edit

    // Glukoz inputs
    @State private var glucose: String = ""
    @State private var glucoseDate: Date = Date()
    @State private var category: String = "Açlık"
    @State private var glucoseNotes: String = ""
    
    // İnsülin inputs
    @State private var basal: String = "0"
    @State private var bolus: String = "0"
    @State private var insulinDate: Date = Date()
    @State private var insulinNotes: String = ""
    
    @State private var showSuccess: Bool = false

    let categories = ["Açlık", "Yemek Öncesi", "Yemek Sonrası", "Yatma Zamanı"]

    init(entry: Entry? = nil) {
        self.entry = entry
    }

    private var isGlucoseValid: Bool {
        guard let g = Double(glucose), g > 0 else { return false }
        return true
    }
    
    private var isInsulinValid: Bool {
        let basalVal = Double(basal) ?? 0
        let bolusVal = Double(bolus) ?? 0
        return basalVal > 0 || bolusVal > 0
    }
    
    private var isValid: Bool {
        return isGlucoseValid || isInsulinValid
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .top, spacing: 24) {
                // Glukoz kartı
                GradientInputCard(title: "Kan Şekeri", icon: "drop.fill", gradientColors: [PremiumPalette.calmTeal.opacity(0.8), PremiumPalette.calmBlue.opacity(0.65)]) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            PremiumTextField(title: "mg/dL", text: $glucose, width: 120, alignment: .leading, isMonospacedDigits: true)
                                .onChange(of: glucose) { _, newValue in
                                    glucose = newValue.replacingOccurrences(of: ",", with: ".")
                                }
                            Text("mg/dL")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }

                        HStack(spacing: 12) {
                            PremiumDateField(selection: $glucoseDate, components: [.date])
                            PremiumDateField(selection: $glucoseDate, components: [.hourAndMinute])
                        }

                        PremiumSegmentedPicker("Kategori", selection: $category) {
                            ForEach(categories, id: \.self) { Text($0) }
                        }

                        PremiumTextEditor(placeholder: "Notlar", text: $glucoseNotes, height: 120)
                    }
                }
                .frame(maxWidth: .infinity)

                // İnsülin kartı
                GradientInputCard(title: "İnsülin", icon: "syringe.fill", gradientColors: [PremiumPalette.accent.opacity(0.8), PremiumPalette.calmBlue.opacity(0.6)]) {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Bazal")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                PremiumTextField(title: "0", text: $basal, width: 100, alignment: .leading, isMonospacedDigits: true)
                                    .onChange(of: basal) { _, newValue in
                                        basal = newValue.replacingOccurrences(of: ",", with: ".")
                                    }
                            }
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Bolus")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(.white.opacity(0.8))
                                PremiumTextField(title: "0", text: $bolus, width: 100, alignment: .leading, isMonospacedDigits: true)
                                    .onChange(of: bolus) { _, newValue in
                                        bolus = newValue.replacingOccurrences(of: ",", with: ".")
                                    }
                            }
                        }

                        HStack(spacing: 12) {
                            PremiumDateField(selection: $insulinDate, components: [.date])
                            PremiumDateField(selection: $insulinDate, components: [.hourAndMinute])
                        }
                        .padding(.vertical, 16)

                        PremiumTextEditor(placeholder: "Notlar", text: $insulinNotes, height: 120)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal)

            Spacer()

            HStack {
                Button("İptal") {
                    dismiss()
                }
                .controlSize(.large)

                Spacer()

                if entry != nil {
                    Button("Sil", role: .destructive) {
                        if let entry {
                            viewContext.delete(entry)
                            try? viewContext.save()
                            dismiss()
                        }
                    }
                    .controlSize(.large)
                }

                Button("Kaydet") {
                    save()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!isValid)
                .controlSize(.large)
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .navigationTitle(entry == nil ? "Yeni Kayıt" : "Kaydı Düzenle")
        .onAppear { loadIfNeeded() }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("İptal") { dismiss() }
            }
        }
        .overlay(
            Group {
                if showSuccess {
                    Text("Kayıt başarılı")
                        .font(.headline)
                        .padding()
                        .background(Color.green.opacity(0.8))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeInOut, value: showSuccess)
            , alignment: .top
        )
    }

    private func loadIfNeeded() {
        guard let entry else { return }
        glucose = "\(Int(entry.glucose))"
        glucoseDate = entry.timestamp ?? Date()
        category = entry.category ?? "Açlık"
        glucoseNotes = entry.notes ?? ""
        
        basal = "\(entry.basalDose?.doubleValue ?? 0)"
        bolus = "\(entry.bolusDose?.doubleValue ?? 0)"
        insulinDate = entry.timestamp ?? Date()
        insulinNotes = entry.notes ?? ""
    }

    private func save() {
        // Eğer ikisi de geçerli değilse çık
        if !isGlucoseValid && !isInsulinValid { return }

        let e = Entry(context: viewContext)
        e.id = Date().timeIntervalSince1970 + Double.random(in: 0..<1)

        // Glukoz bilgisi varsa kaydet
        if isGlucoseValid {
            e.glucose = Double(glucose.replacingOccurrences(of: ",", with: ".")) ?? 0
            e.timestamp = glucoseDate
            e.category = category
            e.notes = glucoseNotes.isEmpty ? nil : glucoseNotes
        }

        // İnsülin bilgisi varsa kaydet
        if isInsulinValid {
            e.basalDose = NSNumber(value: Double(basal) ?? 0)
            e.bolusDose = NSNumber(value: Double(bolus) ?? 0)
            // Eğer glukoz yoksa insülin notunu ekle ve tarihi güncelle
            if !isGlucoseValid {
                e.notes = insulinNotes.isEmpty ? nil : insulinNotes
                e.timestamp = insulinDate
            }
        }

        try? viewContext.save()
        showSuccess = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            showSuccess = false
        }
        dismiss()
    }
}
