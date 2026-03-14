import SwiftUI

extension Notification.Name {
    static let exportSpendingReport = Notification.Name("exportSpendingReport")
    static let navigateToOccasionSettings = Notification.Name("navigateToOccasionSettings")
    static let navigateToCategorySettings = Notification.Name("navigateToCategorySettings")
}

enum MenuTab: String, CaseIterable {
    case transactions = "Transactions"
    case spending = "Spending"
    case settings = "Settings"
}

struct MenuBarView: View {
    @EnvironmentObject private var model: MoneyMonitorModel
    @State private var selectedTab: MenuTab = .transactions
    @State private var hideTabs = false
    @State private var selectedMonth = Date()
    @State private var settingsTarget: String?
    @State private var previousTab: MenuTab?
    @State private var selectedTransaction: Transaction?
    @State private var hostWindow: NSWindow?
    @AppStorage("windowHeight") private var windowHeight: Double = 525

    private let minHeight: Double = 300
    private let maxHeight: Double = 900

    var body: some View {
        VStack(spacing: 0) {
            if model.totalCount == 0 {
                emptyStateView
            } else {
                connectedView
            }
        }
        .frame(width: 340, height: windowHeight, alignment: .top)
        .background(Color(nsColor: .windowBackgroundColor))
        .background(WindowFinder(window: $hostWindow))
        .animation(nil, value: windowHeight)
        .clipped()
        .onReceive(NotificationCenter.default.publisher(for: .navigateToOccasionSettings)) { _ in
            previousTab = selectedTab
            settingsTarget = "occasions"
            selectedTab = .settings
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToCategorySettings)) { _ in
            previousTab = selectedTab
            settingsTarget = "categories"
            selectedTab = .settings
        }
    }

    private func openImportPanel() {
        let window = hostWindow
        window?.hidesOnDeactivate = false

        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.commaSeparatedText, .pdf]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.level = .floating
        panel.begin { response in
            if response == .OK, let url = panel.url {
                if url.pathExtension.lowercased() == "pdf" {
                    model.importPDF(url: url)
                } else {
                    model.importCSV(url: url)
                }
            }
            DispatchQueue.main.async {
                self.selectedTab = .transactions
                self.hideTabs = false
                NSApp.activate(ignoringOtherApps: true)
                window?.makeKeyAndOrderFront(nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    window?.hidesOnDeactivate = true
                }
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Image(systemName: "doc.badge.plus")
                    .font(.system(size: 32))
                    .foregroundStyle(.secondary)

                Text("No transactions yet")
                    .font(.headline)

                Text("Export your transactions as CSV from Halifax online banking, then import the file here.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)

                Button {
                    openImportPanel()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.badge.plus")
                            .font(.caption)
                        Text("Import Bank Statement")
                            .font(.caption)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Divider()
            ResizeHandle(windowHeight: $windowHeight, minHeight: minHeight, maxHeight: maxHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var connectedView: some View {
        VStack(spacing: 0) {
            if !hideTabs {
                Picker("", selection: $selectedTab) {
                    ForEach(MenuTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .padding(8)

                Divider()
            }

            switch selectedTab {
            case .transactions:
                TransactionListView(hideTabs: $hideTabs, selectedMonth: $selectedMonth, selectedTransaction: $selectedTransaction)
            case .spending:
                SpendingChartView(selectedMonth: $selectedMonth)
            case .settings:
                SettingsView(navigateTo: $settingsTarget, returnTab: $previousTab, selectedTab: $selectedTab, hideTabs: $hideTabs)
            }

            ResizeHandle(windowHeight: $windowHeight, minHeight: minHeight, maxHeight: maxHeight)
        }
    }
}

private struct ResizeHandle: View {
    @Binding var windowHeight: Double
    let minHeight: Double
    let maxHeight: Double
    @State private var dragStartHeight: Double = 0
    @State private var dragStartScreenY: Double = 0
    @State private var isDragging = false

    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(Color.secondary.opacity(0.4))
            .frame(width: 36, height: 4)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity)
            .frame(height: 22)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 1)
                    .onChanged { _ in
                        let screenY = NSEvent.mouseLocation.y
                        if !isDragging {
                            isDragging = true
                            dragStartHeight = windowHeight
                            dragStartScreenY = screenY
                        }
                        // Screen Y is flipped (0 at bottom), so moving mouse down = smaller Y = larger window
                        let delta = dragStartScreenY - screenY
                        let newHeight = dragStartHeight + delta
                        windowHeight = min(max(newHeight, minHeight), maxHeight)
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
            .onContinuousHover { phase in
                switch phase {
                case .active:
                    NSCursor.resizeUpDown.push()
                case .ended:
                    NSCursor.pop()
                }
            }
    }
}

struct WindowFinder: NSViewRepresentable {
    @Binding var window: NSWindow?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            self.window = view.window
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            self.window = nsView.window
        }
    }
}
