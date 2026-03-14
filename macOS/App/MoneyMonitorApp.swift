import SwiftUI
import SwiftData

@main
struct MoneyMonitorApp: App {
    @StateObject private var model = MoneyMonitorModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("useMonochromeIcon") private var useMonochromeIcon = false

    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(for: Transaction.self, Category.self, Occasion.self, AppSettings.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(model)
                .modelContainer(container)
                .background(WindowBackgroundSetter())
                .onAppear {
                    model.configure(modelContext: container.mainContext)
                    if !hasCompletedOnboarding {
                        NSApp.activate(ignoringOtherApps: true)
                        NSApp.sendAction(Selector(("showOnboarding:")), to: nil, from: nil)
                    }
                }
        } label: {
            if useMonochromeIcon {
                Image(nsImage: monoMenuBarIcon)
            } else {
                Image(nsImage: colorMenuBarIcon)
            }
        }
        .menuBarExtraStyle(.window)

        Window("Welcome to Money Monitor", id: "onboarding") {
            OnboardingView()
                .environmentObject(model)
                .modelContainer(container)
        }
        .windowResizability(.contentSize)

        Window("About Money Monitor", id: "about") {
            AboutView()
        }
        .windowResizability(.contentSize)

    }

    private var colorMenuBarIcon: NSImage {
        guard let image = NSImage(named: "MenuBarIcon") else {
            return NSImage(systemSymbolName: "sterlingsign.circle", accessibilityDescription: nil)!
        }
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = false
        return image
    }

    private var monoMenuBarIcon: NSImage {
        guard let image = NSImage(named: "MenuBarIconMono") else {
            return NSImage(systemSymbolName: "sterlingsign.circle", accessibilityDescription: nil)!
        }
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return image
    }
}

private struct WindowBackgroundSetter: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            view.window?.backgroundColor = .windowBackgroundColor
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        nsView.window?.backgroundColor = .windowBackgroundColor
    }
}
