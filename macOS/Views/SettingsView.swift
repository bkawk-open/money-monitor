import SwiftUI
import SwiftData

private enum SettingsScreen {
    case menu
    case categories
    case occasions
    case general
    case data
    case help
    case about
}

struct SettingsView: View {
    @Binding var navigateTo: String?
    @Binding var returnTab: MenuTab?
    @Binding var selectedTab: MenuTab
    @Binding var hideTabs: Bool
    @State private var screen: SettingsScreen = .menu
    @State private var cameFromExternal = false

    private func goBack() {
        if cameFromExternal, let tab = returnTab {
            selectedTab = tab
            returnTab = nil
            cameFromExternal = false
            screen = .menu
        } else {
            goBackToMenu()
        }
    }

    var body: some View {
        Group {
            switch screen {
            case .menu:
                settingsMenu
            case .categories:
                CategoriesSettingsView(onBack: { goBack() })
            case .occasions:
                OccasionsSettingsView(onBack: { goBack() })
            case .general:
                GeneralSettingsView(onBack: { goBackToMenu() })
            case .data:
                DataSettingsView(onBack: { goBackToMenu() })
            case .help:
                HelpSettingsView(onBack: { goBackToMenu() })
            case .about:
                AboutSettingsView(onBack: { goBackToMenu() })
            }
        }
        .onAppear {
            applyNavigationTarget()
        }
        .onChange(of: navigateTo) { _, _ in
            applyNavigationTarget()
        }
    }

    private func goBackToMenu() {
        hideTabs = false
        screen = .menu
    }

    private func applyNavigationTarget() {
        if let target = navigateTo {
            switch target {
            case "occasions": screen = .occasions
            case "categories": screen = .categories
            default: break
            }
            cameFromExternal = true
            navigateTo = nil
        }
    }

    private var settingsMenu: some View {
        VStack(spacing: 0) {
            Text("Settings")
                .font(.headline)
                .padding(.vertical, 8)

            Divider()

            SettingsMenuRow(icon: "folder", label: "Categories") { hideTabs = true; screen = .categories }
            Divider()
            SettingsMenuRow(icon: "star", label: "Occasions") { hideTabs = true; screen = .occasions }
            Divider()
            SettingsMenuRow(icon: "gearshape", label: "General") { hideTabs = true; screen = .general }
            Divider()
            SettingsMenuRow(icon: "externaldrive", label: "Data") { hideTabs = true; screen = .data }
            Divider()
            Spacer()

            Divider()
            SettingsMenuRow(icon: "info.circle", label: "About") { hideTabs = true; screen = .about }
            Divider()
            SettingsMenuRow(icon: "questionmark.circle", label: "Help") { hideTabs = true; screen = .help }
            Divider()
            SettingsActionRow(icon: "power", label: "Quit") {
                NSApplication.shared.terminate(nil)
            }
            Divider()
        }
    }
}

private struct SettingsMenuRow: View {
    let icon: String
    let label: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(label)
                .font(.body)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
        .contentShape(Rectangle())
        .onTapGesture { action() }
        .onHover { hovering in isHovered = hovering }
    }
}

private struct SettingsActionRow: View {
    let icon: String
    let label: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.body)
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(label)
                .font(.body)
            Spacer()
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
        .contentShape(Rectangle())
        .onTapGesture { action() }
        .onHover { hovering in isHovered = hovering }
    }
}

private struct SettingsBackHeader: View {
    let title: String
    let onBack: () -> Void

    var body: some View {
        HStack {
            Button {
                onBack()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("Back")
                        .font(.body)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.headline)

            Spacer()

            // Balance the back button width
            Text("Back")
                .font(.body)
                .hidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - Categories

private struct CategoriesSettingsView: View {
    @EnvironmentObject private var model: MoneyMonitorModel
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Category.name) private var categories: [Category]

    let onBack: () -> Void

    @State private var showDeleteCategoryConfirm = false
    @State private var categoryToDelete: Category?
    @State private var editingCategory: Category?
    @State private var editName = ""
    @State private var editColorHex = "3498DB"
    @State private var showColorPicker = false
    @State private var pickerHue: Double = 0
    @State private var pickerSaturation: Double = 1
    @State private var pickerBrightness: Double = 1

    private static let palette: [String] = [
        "E74C3C", "FF9800", "F1C40F", "2ECC71", "00BCD4",
        "3498DB", "9B59B6", "E91E63", "795548", "607D8B",
        "1ABC9C", "FF5722", "8BC34A", "673AB7", "4CAF50",
    ]

    var body: some View {
        VStack(spacing: 0) {
            SettingsBackHeader(title: "Categories", onBack: onBack)
            Divider()

            if categories.isEmpty {
                VStack(spacing: 8) {
                    Text("No categories yet.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView {
                    VStack(spacing: 0) {
                        ForEach(categories) { category in
                            if showDeleteCategoryConfirm && categoryToDelete?.id == category.id {
                                HStack {
                                    Text("Delete \(category.name)?")
                                        .font(.body)
                                    Spacer()
                                    Button("Delete") {
                                        modelContext.delete(category)
                                        try? modelContext.save()
                                        model.updateCounts()
                                        showDeleteCategoryConfirm = false
                                        categoryToDelete = nil
                                    }
                                    .font(.body)
                                    .foregroundStyle(.red)
                                    Button("Cancel") {
                                        showDeleteCategoryConfirm = false
                                        categoryToDelete = nil
                                    }
                                    .font(.body)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                            } else if editingCategory?.id == category.id {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack(spacing: 12) {
                                        TextField("Name", text: $editName)
                                            .textFieldStyle(.plain)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 6)
                                            .background(Color.white.opacity(0.06))
                                            .cornerRadius(8)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                                            )
                                        Button {
                                            saveEdit(category)
                                        } label: {
                                            Text("Save")
                                                .font(.caption)
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
                                        Button {
                                            categoryToDelete = category
                                            showDeleteCategoryConfirm = true
                                            editingCategory = nil
                                        } label: {
                                            Image(systemName: "trash")
                                                .font(.caption2)
                                                .foregroundStyle(.tertiary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    HStack(spacing: 4) {
                                        ForEach(Self.palette, id: \.self) { hex in
                                            Circle()
                                                .fill(Color(hex: hex))
                                                .frame(width: 16, height: 16)
                                                .overlay(
                                                    Circle()
                                                        .strokeBorder(Color.white, lineWidth: editColorHex == hex ? 2 : 0)
                                                )
                                                .onTapGesture {
                                                    editColorHex = hex
                                                }
                                        }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 14)
                            } else {
                                SettingsCategoryRow(
                                    category: category,
                                    onEdit: {
                                        editName = category.name
                                        editColorHex = category.colorHex
                                        editingCategory = category
                                    }
                                )
                            }
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func updateHexFromPicker() {
        let color = NSColor(hue: pickerHue, saturation: pickerSaturation, brightness: pickerBrightness, alpha: 1.0)
        let r = Int(color.redComponent * 255)
        let g = Int(color.greenComponent * 255)
        let b = Int(color.blueComponent * 255)
        editColorHex = String(format: "%02X%02X%02X", r, g, b)
    }

    private func saveEdit(_ category: Category) {
        let name = editName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        category.name = name
        category.colorHex = editColorHex
        try? modelContext.save()
        editingCategory = nil
    }
}

// MARK: - Occasions

private struct OccasionsSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Occasion.name) private var occasions: [Occasion]

    let onBack: () -> Void

    @State private var showDeleteConfirm = false
    @State private var occasionToDelete: Occasion?
    @State private var editingOccasion: Occasion?
    @State private var editName = ""
    @State private var editColorHex = "FF6B6B"
    @State private var newOccasionName = ""

    private static let palette: [String] = [
        "FF6B6B", "FFD93D", "6BCB77", "4D96FF", "FF8E53",
        "C780E8", "45B7D1", "F97B22", "20C997", "845EC2",
        "FF6F91", "67E6DC", "FFC75F", "D65DB1", "2C73D2",
    ]

    private var nextColor: String {
        let usedColors = Set(occasions.map(\.colorHex))
        return Self.palette.first { !usedColors.contains($0) } ?? Self.palette[occasions.count % Self.palette.count]
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsBackHeader(title: "Occasions", onBack: onBack)
            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(occasions) { occasion in
                        if showDeleteConfirm && occasionToDelete?.id == occasion.id {
                            HStack {
                                Text("Delete \(occasion.name)?")
                                    .font(.body)
                                Spacer()
                                Button("Delete") {
                                    modelContext.delete(occasion)
                                    try? modelContext.save()
                                    showDeleteConfirm = false
                                    occasionToDelete = nil
                                }
                                .font(.body)
                                .foregroundStyle(.red)
                                Button("Cancel") {
                                    showDeleteConfirm = false
                                    occasionToDelete = nil
                                }
                                .font(.body)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 6)
                        } else if editingOccasion?.id == occasion.id {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    TextField("Name", text: $editName)
                                        .textFieldStyle(.plain)
                                        .font(.caption)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 6)
                                        .background(Color.white.opacity(0.06))
                                        .cornerRadius(8)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 8)
                                                .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                                        )
                                    Button {
                                        saveEdit(occasion)
                                    } label: {
                                        Text("Save")
                                            .font(.caption)
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
                                    Button {
                                        occasionToDelete = occasion
                                        showDeleteConfirm = true
                                        editingOccasion = nil
                                    } label: {
                                        Image(systemName: "trash")
                                            .font(.caption2)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .buttonStyle(.plain)
                                }
                                HStack(spacing: 4) {
                                    ForEach(Self.palette, id: \.self) { hex in
                                        Circle()
                                            .fill(Color(hex: hex))
                                            .frame(width: 16, height: 16)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(Color.white, lineWidth: editColorHex == hex ? 2 : 0)
                                            )
                                            .onTapGesture {
                                                editColorHex = hex
                                            }
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 14)
                        } else {
                            SettingsOccasionRow(
                                occasion: occasion,
                                onEdit: {
                                    editName = occasion.name
                                    editColorHex = occasion.colorHex
                                    editingOccasion = occasion
                                }
                            )
                        }
                        Divider()
                    }

                    HStack {
                        TextField("New occasion", text: $newOccasionName)
                            .textFieldStyle(.roundedBorder)
                            .controlSize(.small)
                        Button("Add") {
                            addOccasion()
                        }
                        .controlSize(.small)
                        .disabled(newOccasionName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func saveEdit(_ occasion: Occasion) {
        let name = editName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        occasion.name = name
        occasion.colorHex = editColorHex
        try? modelContext.save()
        editingOccasion = nil
    }

    private func addOccasion() {
        let name = newOccasionName.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return }
        let occasion = Occasion(name: name, colorHex: nextColor)
        modelContext.insert(occasion)
        try? modelContext.save()
        newOccasionName = ""
    }
}

private struct SettingsOccasionRow: View {
    let occasion: Occasion
    let onEdit: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack {
            Circle()
                .fill(Color(hex: occasion.colorHex))
                .frame(width: 10, height: 10)
            Text(occasion.name)
                .font(.body)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
        .onHover { hovering in isHovered = hovering }
    }
}

// MARK: - General

private struct GeneralSettingsView: View {
    let onBack: () -> Void
    @State private var launchAtLogin = LaunchAtLoginHelper.isEnabled
    @AppStorage("useMonochromeIcon") private var useMonochromeIcon = false

    var body: some View {
        VStack(spacing: 0) {
            SettingsBackHeader(title: "General", onBack: onBack)
            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .font(.body)
                    .onChange(of: launchAtLogin) { _, _ in
                        LaunchAtLoginHelper.toggle()
                    }

                Toggle("Monochrome Menu Bar Icon", isOn: $useMonochromeIcon)
                    .font(.body)
            }
            .padding()

            Spacer()
        }
    }
}

// MARK: - Data

private struct DataSettingsView: View {
    @EnvironmentObject private var model: MoneyMonitorModel
    @Environment(\.modelContext) private var modelContext
    let onBack: () -> Void

    @State private var showDeleteTransactionsConfirm = false
    @State private var unlinkMonth = Date()
    @State private var showUnlinkConfirm = false

    private var unlinkMonthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: unlinkMonth)
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsBackHeader(title: "Data", onBack: onBack)
            Divider()

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Uncategorize Month")
                        .font(.body.bold())

                    HStack {
                        Button {
                            unlinkMonth = Calendar.current.date(byAdding: .month, value: -1, to: unlinkMonth) ?? unlinkMonth
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)

                        Text(unlinkMonthLabel)
                            .font(.body)
                            .frame(minWidth: 120)

                        Button {
                            unlinkMonth = Calendar.current.date(byAdding: .month, value: 1, to: unlinkMonth) ?? unlinkMonth
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                    }

                    if showUnlinkConfirm {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Remove all category assignments for \(unlinkMonthLabel)?")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                Button("Uncategorize") {
                                    unlinkTransactions()
                                }
                                .font(.body)
                                .foregroundStyle(.red)
                                Button("Cancel") {
                                    showUnlinkConfirm = false
                                }
                                .font(.body)
                            }
                        }
                    } else {
                        Button("Uncategorize \(unlinkMonthLabel)") {
                            showUnlinkConfirm = true
                        }
                        .font(.body)
                        .foregroundStyle(.orange)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Delete Data")
                        .font(.body.bold())

                    if showDeleteTransactionsConfirm {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Delete all transactions? Categories will be kept.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                Button("Delete All") {
                                    deleteAllTransactions()
                                }
                                .font(.body)
                                .foregroundStyle(.red)
                                Button("Cancel") {
                                    showDeleteTransactionsConfirm = false
                                }
                                .font(.body)
                            }
                        }
                    } else {
                        Button("Delete All Transactions") {
                            showDeleteTransactionsConfirm = true
                        }
                        .font(.body)
                        .foregroundStyle(.red)
                    }
                }
            }
            .padding()

            Spacer()
        }
    }

    private func unlinkTransactions() {
        let calendar = Calendar.current
        let comps = calendar.dateComponents([.year, .month], from: unlinkMonth)
        guard let start = calendar.date(from: comps),
              let end = calendar.date(byAdding: .month, value: 1, to: start) else { return }

        let descriptor = FetchDescriptor<Transaction>()
        if let transactions = try? modelContext.fetch(descriptor) {
            for txn in transactions where txn.date >= start && txn.date < end && txn.category != nil {
                txn.category = nil
            }
            try? modelContext.save()
            model.updateCounts()
        }
        showUnlinkConfirm = false
    }

    private func deleteAllTransactions() {
        let descriptor = FetchDescriptor<Transaction>()
        if let transactions = try? modelContext.fetch(descriptor) {
            for txn in transactions {
                modelContext.delete(txn)
            }
            try? modelContext.save()
            model.updateCounts()
        }
        showDeleteTransactionsConfirm = false
    }
}

// MARK: - About

private struct AboutSettingsView: View {
    let onBack: () -> Void

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    private var copyright: String {
        Bundle.main.infoDictionary?["NSHumanReadableCopyright"] as? String ?? ""
    }

    var body: some View {
        VStack(spacing: 0) {
            SettingsBackHeader(title: "About", onBack: onBack)
            Divider()

            VStack(spacing: 12) {
                Image("MenuBarIcon")
                    .resizable()
                    .interpolation(.high)
                    .frame(width: 64, height: 64)

                Text("Money Monitor")
                    .font(.headline)

                Text("Version \(appVersion) (\(buildNumber))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Your spending, sorted.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                if !copyright.isEmpty {
                    Text(copyright)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.top, 24)

            Spacer()
        }
    }
}

// MARK: - Help

private struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

private let faqItems: [FAQItem] = [
    FAQItem(
        question: "How do I get my statements into the app?",
        answer: "Log into Halifax online banking, download your statement as a CSV or PDF, and hit 'Import Statement' in the app. That's it."
    ),
    FAQItem(
        question: "What file types work?",
        answer: "CSV and PDF exports from Halifax online banking. Just download whichever you prefer."
    ),
    FAQItem(
        question: "How does auto-categorising work?",
        answer: "Sort one payment and every matching one is done automatically. So if you categorise one Tesco shop, they're all sorted in one go."
    ),
    FAQItem(
        question: "Can I change my categories?",
        answer: "Of course. Head to Settings then Categories. Tap any one to rename it, pick a new colour, or remove it."
    ),
    FAQItem(
        question: "What are occasions for?",
        answer: "They let you tag spending for things like holidays, birthdays, or Christmas — separate from your everyday categories. Handy for seeing what a trip actually cost you."
    ),
    FAQItem(
        question: "How do I get a spending report?",
        answer: "On the Spending tab, hit the Export button below the chart. You'll get a PDF breakdown of that month's spending."
    ),
    FAQItem(
        question: "Is my data safe?",
        answer: "Everything stays on your device. Nothing is sent anywhere — your financial information never leaves your Mac."
    ),
    FAQItem(
        question: "Does it work with other banks?",
        answer: "Right now it's just Halifax. We're looking at adding more UK banks in future."
    ),
]

private struct HelpSettingsView: View {
    let onBack: () -> Void

    @State private var expandedFAQ: UUID?
    @State private var subject = ""
    @State private var messageBody = ""
    @State private var showSentConfirmation = false

    var body: some View {
        VStack(spacing: 0) {
            SettingsBackHeader(title: "Help", onBack: onBack)
            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // FAQ Section
                    Text("Frequently Asked Questions")
                        .font(.body.bold())
                        .padding(.horizontal)
                        .padding(.top, 14)
                        .padding(.bottom, 8)

                    ForEach(faqItems) { item in
                        FAQRowView(item: item, expandedID: $expandedFAQ)
                        Divider()
                    }

                    // Contact Section
                    Text("Get in Touch")
                        .font(.body.bold())
                        .padding(.horizontal)
                        .padding(.top, 18)
                        .padding(.bottom, 4)

                    Text("Got a question or an idea? We'd love to hear from you.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.bottom, 12)

                    VStack(alignment: .leading, spacing: 10) {
                        TextField("Subject", text: $subject)
                            .textFieldStyle(.plain)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 6)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                            )

                        TextEditor(text: $messageBody)
                            .font(.caption)
                            .scrollContentBackground(.hidden)
                            .padding(4)
                            .frame(minHeight: 70, maxHeight: 100)
                            .background(Color.white.opacity(0.06))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                            )

                        HStack {
                            if showSentConfirmation {
                                HStack(spacing: 4) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundStyle(.green)
                                    Text("Opened in your email app")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Button {
                                sendFeedback()
                            } label: {
                                Text("Send")
                                    .font(.caption)
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
                            .disabled(subject.trimmingCharacters(in: .whitespaces).isEmpty && messageBody.trimmingCharacters(in: .whitespaces).isEmpty)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 14)
                }
            }
        }
    }

    private func sendFeedback() {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
        let body = "\(messageBody)\n\n---\nMoneyMonitor v\(version) (\(build))"

        if let service = NSSharingService(named: .composeEmail) {
            service.recipients = ["support@moneymonitor.app"]
            service.subject = subject.isEmpty ? "MoneyMonitor Feedback" : subject
            service.perform(withItems: [body])
        } else {
            let subjectEncoded = (subject.isEmpty ? "MoneyMonitor Feedback" : subject)
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            let bodyEncoded = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
            if let url = URL(string: "mailto:support@moneymonitor.app?subject=\(subjectEncoded)&body=\(bodyEncoded)") {
                NSWorkspace.shared.open(url)
            }
        }

        showSentConfirmation = true
        subject = ""
        messageBody = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            showSentConfirmation = false
        }
    }
}

private struct FAQRowView: View {
    let item: FAQItem
    @Binding var expandedID: UUID?
    @State private var isHovered = false

    private var isExpanded: Bool { expandedID == item.id }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(item.question)
                    .font(.caption)
                    .lineLimit(isExpanded ? nil : 2)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .rotationEffect(.degrees(isExpanded ? 90 : 0))
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.2)) {
                    expandedID = isExpanded ? nil : item.id
                }
            }
            .onHover { hovering in isHovered = hovering }

            if isExpanded {
                Text(item.answer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    .transition(.opacity)
            }
        }
    }
}

// MARK: - Shared Components

private struct SettingsCategoryRow: View {
    let category: Category
    let onEdit: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack {
            Circle()
                .fill(category.color)
                .frame(width: 10, height: 10)
            Text(category.name)
                .font(.body)
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
        .contentShape(Rectangle())
        .onTapGesture { onEdit() }
        .onHover { hovering in isHovered = hovering }
    }
}

private struct InlineColorPicker: View {
    @Binding var hue: Double
    @Binding var saturation: Double
    @Binding var brightness: Double

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Color(hue: hue, saturation: 1, brightness: 1)
                LinearGradient(
                    gradient: Gradient(colors: [.white, .clear]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                LinearGradient(
                    gradient: Gradient(colors: [.black, .clear]),
                    startPoint: .bottom,
                    endPoint: .top
                )
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(
                Circle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .frame(width: 12, height: 12)
                    .position(x: CGFloat(saturation) * 296, y: CGFloat(1.0 - brightness) * 120)
            )
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        saturation = Double(min(max(value.location.x / 296, 0), 1))
                        brightness = Double(1.0 - min(max(value.location.y / 120, 0), 1))
                    }
            )

            ZStack(alignment: .leading) {
                LinearGradient(
                    gradient: Gradient(colors: (0...10).map { Color(hue: Double($0) / 10, saturation: 1, brightness: 1) }),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .frame(height: 12)
                .clipShape(Capsule())

                Circle()
                    .strokeBorder(Color.white, lineWidth: 2)
                    .background(Circle().fill(Color(hue: hue, saturation: 1, brightness: 1)))
                    .frame(width: 14, height: 14)
                    .offset(x: hue * 282)
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        hue = min(max(value.location.x / 296, 0), 1)
                    }
            )
        }
    }
}
