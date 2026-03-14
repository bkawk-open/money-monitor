import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject private var model: MoneyMonitorModel

    @State private var selectedTab: Tab = .transactions
    @State private var selectedMonth = Date()

    enum Tab {
        case transactions, spending, settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                TransactionListView(selectedMonth: $selectedMonth)
            }
            .tabItem {
                Label("Transactions", systemImage: "list.bullet")
            }
            .tag(Tab.transactions)

            NavigationStack {
                SpendingChartView(selectedMonth: $selectedMonth)
            }
            .tabItem {
                Label("Spending", systemImage: "chart.pie")
            }
            .tag(Tab.spending)

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            .tag(Tab.settings)
        }
        .preferredColorScheme(.dark)
    }
}
