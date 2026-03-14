import SwiftUI
import SwiftData

private let panelBg = Color(red: 0.16, green: 0.16, blue: 0.16)

private enum SettingsScreen {
    case menu
    case categories
    case occasions
    case data
    case help
    case about
}

struct SettingsView: View {
    @State private var screen: SettingsScreen = .menu

    var body: some View {
        Group {
            switch screen {
            case .menu:
                settingsMenu
            case .categories:
                CategoriesSettingsView(onBack: { screen = .menu })
            case .occasions:
                OccasionsSettingsView(onBack: { screen = .menu })
            case .data:
                DataSettingsView(onBack: { screen = .menu })
            case .help:
                HelpSettingsView(onBack: { screen = .menu })
            case .about:
                AboutSettingsView(onBack: { screen = .menu })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(panelBg)
        .navigationTitle("")
        .navigationBarHidden(true)
    }

    private var settingsMenu: some View {
        VStack(spacing: 0) {
            Text("Settings")
                .font(.headline)
                .padding(.vertical, 8)

            Divider()

            SettingsMenuRow(icon: "folder", label: "Categories") { screen = .categories }
            Divider()
            SettingsMenuRow(icon: "star", label: "Occasions") { screen = .occasions }
            Divider()
            SettingsMenuRow(icon: "externaldrive", label: "Data") { screen = .data }
            Divider()
            SettingsMenuRow(icon: "info.circle", label: "About") { screen = .about }
            Divider()
            SettingsMenuRow(icon: "questionmark.circle", label: "Help") { screen = .help }
            Divider()

            Spacer()
        }
    }
}

private struct SettingsMenuRow: View {
    let icon: String
    let label: String
    let action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            HStack {
                Image(systemName: icon)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .frame(width: 24)
                Text(label)
                    .font(.callout)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .frame(minHeight: 44)
            .background(Color.white.opacity(0.03))
        }
        .buttonStyle(.plain)
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
                        .font(.callout)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Text(title)
                .font(.subheadline.weight(.semibold))

            Spacer()

            Text("Back")
                .font(.callout)
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
        "1ABC9C", "FF5722", "8BC34A", "673AB7",
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
                                        .font(.callout)
                                    Spacer()
                                    Button("Delete") {
                                        modelContext.delete(category)
                                        try? modelContext.save()
                                        model.updateCounts()
                                        showDeleteCategoryConfirm = false
                                        categoryToDelete = nil
                                    }
                                    .font(.callout)
                                    .foregroundStyle(.red)
                                    Button("Cancel") {
                                        showDeleteCategoryConfirm = false
                                        categoryToDelete = nil
                                    }
                                    .font(.callout)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                            } else if editingCategory?.id == category.id {
                                VStack(alignment: .leading, spacing: 6) {
                                    HStack {
                                        TextField("Name", text: $editName)
                                            .textFieldStyle(.roundedBorder)
                                            .font(.callout)
                                        Button("Save") {
                                            saveEdit(category)
                                        }
                                        .buttonStyle(.borderedProminent)
                                        .font(.callout)
                                        Button("Delete") {
                                            categoryToDelete = category
                                            showDeleteCategoryConfirm = true
                                            editingCategory = nil
                                        }
                                        .foregroundStyle(.red)
                                        .font(.callout)
                                    }
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 6) {
                                            ForEach(Self.palette, id: \.self) { hex in
                                                Circle()
                                                    .fill(Color(hex: hex))
                                                    .frame(width: 24, height: 24)
                                                    .overlay(
                                                        Circle()
                                                            .strokeBorder(Color.white, lineWidth: editColorHex == hex ? 2 : 0)
                                                    )
                                                    .onTapGesture {
                                                        editColorHex = hex
                                                        showColorPicker = false
                                                    }
                                            }
                                            Circle()
                                                .fill(AngularGradient(
                                                    gradient: Gradient(colors: [.red, .yellow, .green, .cyan, .blue, .purple, .red]),
                                                    center: .center
                                                ))
                                                .frame(width: 24, height: 24)
                                                .overlay(
                                                    Circle()
                                                        .strokeBorder(Color.white, lineWidth: showColorPicker ? 2 : 0)
                                                )
                                                .onTapGesture {
                                                    showColorPicker.toggle()
                                                }
                                        }
                                    }
                                    if showColorPicker {
                                        InlineColorPicker(
                                            hue: $pickerHue,
                                            saturation: $pickerSaturation,
                                            brightness: $pickerBrightness
                                        )
                                        .onChange(of: pickerHue) { _, _ in updateHexFromPicker() }
                                        .onChange(of: pickerSaturation) { _, _ in updateHexFromPicker() }
                                        .onChange(of: pickerBrightness) { _, _ in updateHexFromPicker() }
                                    }
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                            } else {
                                HStack {
                                    Circle()
                                        .fill(category.color)
                                        .frame(width: 10, height: 10)
                                    Text(category.name)
                                        .font(.callout)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                                .background(Color.white.opacity(0.03))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    editName = category.name
                                    editColorHex = category.colorHex
                                    editingCategory = category
                                }
                            }
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private func updateHexFromPicker() {
        let color = UIColor(hue: pickerHue, saturation: pickerSaturation, brightness: pickerBrightness, alpha: 1.0)
        var r: CGFloat = 0; var g: CGFloat = 0; var b: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: nil)
        editColorHex = String(format: "%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
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
                                    .font(.callout)
                                Spacer()
                                Button("Delete") {
                                    modelContext.delete(occasion)
                                    try? modelContext.save()
                                    showDeleteConfirm = false
                                    occasionToDelete = nil
                                }
                                .font(.callout)
                                .foregroundStyle(.red)
                                Button("Cancel") {
                                    showDeleteConfirm = false
                                    occasionToDelete = nil
                                }
                                .font(.callout)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        } else if editingOccasion?.id == occasion.id {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    TextField("Name", text: $editName)
                                        .textFieldStyle(.roundedBorder)
                                        .font(.callout)
                                    Button("Save") {
                                        saveEdit(occasion)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .font(.callout)
                                    Button("Delete") {
                                        occasionToDelete = occasion
                                        showDeleteConfirm = true
                                        editingOccasion = nil
                                    }
                                    .foregroundStyle(.red)
                                    .font(.callout)
                                }
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 6) {
                                        ForEach(Self.palette, id: \.self) { hex in
                                            Circle()
                                                .fill(Color(hex: hex))
                                                .frame(width: 24, height: 24)
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
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                        } else {
                            HStack {
                                Circle()
                                    .fill(Color(hex: occasion.colorHex))
                                    .frame(width: 10, height: 10)
                                Text(occasion.name)
                                    .font(.callout)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.03))
                            .contentShape(Rectangle())
                            .onTapGesture {
                                editName = occasion.name
                                editColorHex = occasion.colorHex
                                editingOccasion = occasion
                            }
                        }
                        Divider()
                    }

                    HStack {
                        TextField("New occasion", text: $newOccasionName)
                            .textFieldStyle(.roundedBorder)
                            .font(.callout)
                        Button("Add") {
                            addOccasion()
                        }
                        .font(.callout)
                        .disabled(newOccasionName.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
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
                        .font(.callout.bold())

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
                            .font(.callout)
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
                                .font(.callout)
                                .foregroundStyle(.red)
                                Button("Cancel") {
                                    showUnlinkConfirm = false
                                }
                                .font(.callout)
                            }
                        }
                    } else {
                        Button("Uncategorize \(unlinkMonthLabel)") {
                            showUnlinkConfirm = true
                        }
                        .font(.callout)
                        .foregroundStyle(.orange)
                    }
                }

                Divider()

                VStack(alignment: .leading, spacing: 6) {
                    Text("Delete Data")
                        .font(.callout.bold())

                    if showDeleteTransactionsConfirm {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Delete all transactions? Categories will be kept.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            HStack {
                                Button("Delete All") {
                                    deleteAllTransactions()
                                }
                                .font(.callout)
                                .foregroundStyle(.red)
                                Button("Cancel") {
                                    showDeleteTransactionsConfirm = false
                                }
                                .font(.callout)
                            }
                        }
                    } else {
                        Button("Delete All Transactions") {
                            showDeleteTransactionsConfirm = true
                        }
                        .font(.callout)
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
                Image(systemName: "sterlingsign.circle.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.blue)

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

private struct HelpSettingsView: View {
    let onBack: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            SettingsBackHeader(title: "Help", onBack: onBack)
            Divider()

            VStack(alignment: .leading, spacing: 12) {
                Text("See exactly where your money goes. Import your Halifax statement and start sorting your spending.")
                    .font(.callout)

                Text("Getting started")
                    .font(.callout.bold())
                Text("1. Download your statement from Halifax online banking\n2. Import the CSV or PDF into the app\n3. Tap a payment to sort it into a category\n4. Check the Spending tab to see the bigger picture")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text("Good to know")
                    .font(.callout.bold())
                Text("Sort one payment and every matching one is done automatically. So if you categorise one Tesco shop, they're all sorted in one go.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()

            Spacer()
        }
    }
}

// MARK: - Inline Color Picker

private struct InlineColorPicker: View {
    @Binding var hue: Double
    @Binding var saturation: Double
    @Binding var brightness: Double

    var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
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
                .clipShape(RoundedRectangle(cornerRadius: 4))
                .overlay(
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 16, height: 16)
                        .position(
                            x: CGFloat(saturation) * geo.size.width,
                            y: CGFloat(1.0 - brightness) * geo.size.height
                        )
                )
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            saturation = Double(min(max(value.location.x / geo.size.width, 0), 1))
                            brightness = Double(1.0 - min(max(value.location.y / geo.size.height, 0), 1))
                        }
                )
            }
            .frame(height: 160)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    LinearGradient(
                        gradient: Gradient(colors: (0...10).map { Color(hue: Double($0) / 10, saturation: 1, brightness: 1) }),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(height: 16)
                    .clipShape(Capsule())

                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .background(Circle().fill(Color(hue: hue, saturation: 1, brightness: 1)))
                        .frame(width: 20, height: 20)
                        .offset(x: CGFloat(hue) * (geo.size.width - 20))
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            hue = Double(min(max(value.location.x / geo.size.width, 0), 1))
                        }
                )
            }
            .frame(height: 20)
        }
    }
}
