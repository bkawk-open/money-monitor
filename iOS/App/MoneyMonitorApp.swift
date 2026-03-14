import SwiftUI
import SwiftData

@main
struct MoneyMonitorApp: App {
    @StateObject private var model = MoneyMonitorModel()

    let container: ModelContainer

    init() {
        let schema = Schema([Transaction.self, Category.self, Occasion.self, AppSettings.self])
        let config = ModelConfiguration("MoneyMonitor", groupContainer: .identifier("group.com.bkawk.MoneyMonitor"))
        do {
            container = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(model)
                .modelContainer(container)
                .onAppear {
                    model.configure(modelContext: container.mainContext)
                }
        }
    }
}
