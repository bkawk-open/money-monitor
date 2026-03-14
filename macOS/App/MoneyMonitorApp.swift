import SwiftUI
import SwiftData

@main
struct MoneyMonitorApp: App {
    @StateObject private var model = MoneyMonitorModel()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

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
            Image(systemName: menuBarIcon)
                .symbolRenderingMode(model.missingStatementForLastMonth ? .palette : .monochrome)
                .foregroundStyle(model.missingStatementForLastMonth ? Color.red : Color.primary)
                .symbolEffect(.pulse, isActive: model.uncategorizedCount > 0 || model.missingStatementForLastMonth)
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

    private var menuBarIcon: String {
        if model.uncategorizedCount > 0 {
            return "sterlingsign.circle.fill"
        }
        return "sterlingsign.circle"
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
