import SwiftUI

struct SettingsView: View {
    @AppStorage("targetLow") private var targetLow: Double = 70
    @AppStorage("targetHigh") private var targetHigh: Double = 180

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                PremiumSectionHeader("Ayarlar", subtitle: "Glukoz hedefleri ve veri yönetimi.")
                glucoseSettings
                dataSection
            }
            .padding(24)
        }
        .frame(minWidth: 720, minHeight: 520, alignment: .topLeading)
        .background(PremiumBackground().ignoresSafeArea())
    }

    private var glucoseSettings: some View {
        PremiumPanel(
            "Hedef Glukoz Aralığı",
            subtitle: "Düşük ve yüksek hedefleri belirleyin."
        ) {
            VStack(spacing: 20) {
                targetRow(
                    title: "Düşük Hedef",
                    value: Int(targetLow),
                    range: 50...min(targetHigh - 5, 120),
                    sliderRange: 50...120,
                    step: 5,
                    binding: $targetLow
                )

                targetRow(
                    title: "Yüksek Hedef",
                    value: Int(targetHigh),
                    range: max(targetLow + 5, 130)...250,
                    sliderRange: 130...250,
                    step: 5,
                    binding: $targetHigh
                )
            }

            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .foregroundStyle(.secondary)
                Text("Önerilen aralık 70–180 mg/dL’dir. Klinik ihtiyaçlarınıza göre güncelleyebilirsiniz.")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            }
            .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var dataSection: some View {
        DataManagementView(compact: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func targetRow(
        title: String,
        value: Int,
        range: ClosedRange<Double>,
        sliderRange: ClosedRange<Double>,
        step: Double,
        binding: Binding<Double>
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(.headline).bold()
                    .foregroundStyle(.primary)
                Spacer()
                Text("\(value) mg/dL")
                    .monospacedDigit()
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(Color.accentColor.opacity(0.12))
                    )
            }
            HStack(spacing: 16) {
                Stepper(value: binding, in: range, step: step) {
                    Text("\(value)")
                        .monospacedDigit()
                        .font(.body)
                        .foregroundStyle(.primary)
                }
                .labelsHidden()
                Slider(value: binding, in: sliderRange, step: step)
                    .frame(maxWidth: 260)
            }
        }
    }
}
