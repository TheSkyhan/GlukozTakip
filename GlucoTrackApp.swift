import SwiftUI

@main
struct GlucoTrackApp: App {
    let persistenceController = PersistenceController.shared
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .tint(PremiumPalette.accent)
        }
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("Hakkında GlucoTrack") {
                    appDelegate.showAboutWindow()
                }
            }
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var aboutWindow: NSWindow?

    func showAboutWindow() {
        if aboutWindow == nil {
            aboutWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 320),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            aboutWindow?.title = "Hakkında"
            aboutWindow?.contentView = NSHostingView(rootView: AboutView())
        }
        aboutWindow?.makeKeyAndOrderFront(nil)
        aboutWindow?.center()
    }
}
