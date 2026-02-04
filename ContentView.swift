import SwiftUI

struct ContentView: View {
    @State private var selection: SidebarSelection = .dashboard

    enum SidebarSelection: Hashable {
        case dashboard
        case logEntry
        case measurements
        case insulinLog
        case reports
        case settings
        case about
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .frame(minWidth: 1200, minHeight: 700)
        .background(PremiumBackground().ignoresSafeArea())
    }

    private var sidebar: some View {
        List(selection: $selection) {
            SidebarHeader()
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                .listRowBackground(Color.clear)

            SidebarRow(
                title: "Gösterge Paneli",
                systemImage: "gauge.high",
                isSelected: selection == .dashboard
            )
            .tag(SidebarSelection.dashboard)
            .listRowBackground(Color.clear)

            SidebarRow(
                title: "Kayıt Girişi",
                systemImage: "plus.circle.fill",
                isSelected: selection == .logEntry
            )
            .tag(SidebarSelection.logEntry)
            .listRowBackground(Color.clear)

            SidebarRow(
                title: "Ölçümler",
                systemImage: "list.bullet",
                isSelected: selection == .measurements
            )
            .tag(SidebarSelection.measurements)
            .listRowBackground(Color.clear)

            SidebarRow(
                title: "İnsülin Kayıtları",
                systemImage: "syringe",
                isSelected: selection == .insulinLog
            )
            .tag(SidebarSelection.insulinLog)
            .listRowBackground(Color.clear)

            SidebarRow(
                title: "Raporlar",
                systemImage: "chart.xyaxis.line",
                isSelected: selection == .reports
            )
            .tag(SidebarSelection.reports)
            .listRowBackground(Color.clear)

            SidebarRow(
                title: "Ayarlar",
                systemImage: "gearshape",
                isSelected: selection == .settings
            )
            .tag(SidebarSelection.settings)
            .listRowBackground(Color.clear)

            SidebarRow(
                title: "Hakkında",
                systemImage: "info.circle",
                isSelected: selection == .about
            )
            .tag(SidebarSelection.about)
            .listRowBackground(Color.clear)
        }
        .listStyle(.sidebar)
        .scrollContentBackground(.hidden)
        .background(.ultraThinMaterial)
        .frame(minWidth: 210, idealWidth: 230, maxWidth: 250)
        .navigationTitle("GlucoTrack")
    }

    @ViewBuilder
    private var detailView: some View {
        switch selection {
        case .dashboard:
            DashboardView()
        case .logEntry:
            EditEntryView()
        case .measurements:
            MeasurementsView()
        case .insulinLog:
            InsulinLogView()
        case .reports:
            ReportsView()
        case .settings:
            SettingsView()
        case .about:
            AboutView()
        }
    }
}

private struct SidebarRow: View {
    let title: String
    let systemImage: String
    let isSelected: Bool

    @State private var isHovering = false

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.18) : Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(isSelected ? Color.accentColor.opacity(0.25) : Color.white.opacity(0.08))
                    )
                Image(systemName: systemImage)
                    .font(.system(size: 14, weight: .bold))
                    .symbolRenderingMode(isSelected ? .palette : .hierarchical)
                    .foregroundStyle(
                        isSelected ? Color.white : Color.secondary,
                        isSelected ? Color.accentColor : Color.secondary.opacity(0.5)
                    )
            }
            .frame(width: 28, height: 28)

            Text(title)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(isSelected ? Color.primary : Color.secondary)
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.accentColor.opacity(0.16) : (isHovering ? Color.black.opacity(0.06) : .clear))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? Color.accentColor.opacity(0.28) : Color.clear)
        )
        .onHover { isHovering = $0 }
    }
}

private struct SidebarHeader: View {
    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [PremiumPalette.accent.opacity(0.22), PremiumPalette.calmTeal.opacity(0.12)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.white.opacity(0.18))
                    )
                Image(systemName: "drop.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(PremiumPalette.accent)
            }
            .frame(width: 32, height: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text("GlucoTrack")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                Text("Sağlık Takibi")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(Color.white.opacity(0.12))
                )
        )
    }
}
