import SwiftUI
import SwiftData
import Charts

enum OccasionFilter: Equatable {
    case all
    case noOccasion
    case occasion(PersistentIdentifier)
}

struct SpendingChartView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var model: MoneyMonitorModel
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Occasion.name) private var occasions: [Occasion]

    @Binding var selectedMonth: Date
    @State private var selectedCategory: Category?
    @State private var hoveredItem: String?
    @State private var occasionFilter: OccasionFilter = .all

    private var isCurrentMonth: Bool {
        let cal = Calendar.current
        return cal.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    var body: some View {
        VStack(spacing: 0) {
            if let category = selectedCategory {
                CategoryDetailView(
                    category: category,
                    selectedMonth: selectedMonth,
                    occasionFilter: occasionFilter,
                    onBack: {
                        selectedCategory = nil
                        model.updateCounts()
                    }
                )
            } else {
                spendingContent
            }
        }


    }

    private var spendingContent: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Spacer()

                Text(monthLabel)
                    .font(.headline)

                Spacer()

                Button {
                    selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                        .foregroundStyle(isCurrentMonth ? .quaternary : .secondary)
                        .frame(width: 32, height: 32)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(isCurrentMonth)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)

            if monthHasOccasions {
                HStack(spacing: 6) {
                    FilterPill(label: "All", isSelected: occasionFilter == .all) {
                        occasionFilter = .all
                    }
                    FilterPill(label: "No Occasion", isSelected: occasionFilter == .noOccasion) {
                        occasionFilter = .noOccasion
                    }
                    ForEach(occasionsInMonth) { occasion in
                        FilterPill(
                            label: occasion.name,
                            colorHex: occasion.colorHex,
                            isSelected: occasionFilter == .occasion(occasion.persistentModelID)
                        ) {
                            occasionFilter = .occasion(occasion.persistentModelID)
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }

            if chartData.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.pie")
                        .font(.system(size: 32))
                        .foregroundStyle(.secondary)
                    Text("No categorized spending this month")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ZStack {
                    Chart(chartData, id: \.name) { item in
                        SectorMark(
                            angle: .value("Amount", item.total),
                            innerRadius: .ratio(0.5),
                            angularInset: 1.5
                        )
                        .foregroundStyle(Color(hex: item.colorHex))
                        .opacity(hoveredItem == nil || hoveredItem == item.name ? 1 : 0.4)
                    }
                    .chartOverlay { proxy in
                        GeometryReader { geo in
                            Rectangle()
                                .fill(.clear)
                                .contentShape(Rectangle())
                                .onContinuousHover { phase in
                                    switch phase {
                                    case .active(let location):
                                        let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
                                        let dx = location.x - center.x
                                        let dy = location.y - center.y
                                        let distance = sqrt(dx * dx + dy * dy)
                                        let outerRadius = min(geo.size.width, geo.size.height) / 2
                                        let innerRadius = outerRadius * 0.5

                                        if distance >= innerRadius && distance <= outerRadius {
                                            // Angle from top, clockwise (matching SwiftUI Charts)
                                            var angle = atan2(dx, -dy)
                                            if angle < 0 { angle += 2 * .pi }
                                            let totalValue = chartData.reduce(0.0) { $0 + $1.total }
                                            var cumulative = 0.0
                                            for item in chartData {
                                                cumulative += item.total
                                                if angle <= (cumulative / totalValue) * 2 * .pi {
                                                    hoveredItem = item.name
                                                    break
                                                }
                                            }
                                        } else {
                                            hoveredItem = nil
                                        }
                                    case .ended:
                                        hoveredItem = nil
                                    }
                                }
                        }
                    }

                    // Center label
                    if let name = hoveredItem, let item = chartData.first(where: { $0.name == name }) {
                        VStack(spacing: 2) {
                            Text("\(Int(item.percentage))%")
                                .font(.title2.bold())
                            Text(item.name)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                                .lineLimit(1)
                        }
                        .allowsHitTesting(false)
                    }
                }
                .frame(height: 180)
                .padding(.horizontal)

                HStack {
                    Button {
                        exportPDF()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption2)
                            Text("Export")
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.bottom, 4)

                Divider()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(chartData, id: \.name) { item in
                            SpendingRow(item: item, isHovered: hoveredItem == item.name) {
                                selectedCategory = categories.first { $0.name == item.name }
                            }
                            .onHover { hovering in
                                hoveredItem = hovering ? item.name : nil
                            }
                            Divider()
                        }
                    }
                }

                HStack {
                    Text("Total")
                        .font(.subheadline.bold())
                    Spacer()
                    Text(formattedCurrency(totalSpending))
                        .font(.subheadline.bold().monospacedDigit())
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
    }

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }



    fileprivate struct ChartItem {
        let name: String
        let colorHex: String
        let total: Double
        let percentage: Double
    }

    private var monthHasOccasions: Bool {
        !occasionsInMonth.isEmpty
    }

    private var occasionsInMonth: [Occasion] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { return [] }

        let monthTxns = categories.flatMap(\.transactions).filter { txn in
            txn.date >= startOfMonth && txn.date < endOfMonth && txn.occasion != nil
        }
        let usedIDs = Set(monthTxns.compactMap { $0.occasion?.persistentModelID })
        return occasions.filter { usedIDs.contains($0.persistentModelID) }
    }

    private func filteredTransactions(for category: Category) -> [Transaction] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { return [] }

        return category.transactions.filter { txn in
            guard txn.date >= startOfMonth && txn.date < endOfMonth && txn.amount < 0 else { return false }
            switch occasionFilter {
            case .all:
                return true
            case .noOccasion:
                return txn.occasion == nil
            case .occasion(let id):
                return txn.occasion?.persistentModelID == id
            }
        }
    }

    private var chartData: [ChartItem] {
        var items: [ChartItem] = []
        let total = totalSpending

        for category in categories {
            let categoryTotal = filteredTransactions(for: category)
                .reduce(0.0) { $0 + abs($1.amount) }
            if categoryTotal > 0 {
                let pct = total > 0 ? (categoryTotal / total) * 100 : 0
                items.append(ChartItem(name: category.name, colorHex: category.colorHex, total: categoryTotal, percentage: pct))
            }
        }

        return items.sorted { $0.total > $1.total }
    }

    private var totalSpending: Double {
        categories.flatMap { filteredTransactions(for: $0) }
            .reduce(0.0) { $0 + abs($1.amount) }
    }

    private var filterLabel: String {
        switch occasionFilter {
        case .all:
            return ""
        case .noOccasion:
            return " — No Occasion"
        case .occasion(let id):
            if let name = occasions.first(where: { $0.persistentModelID == id })?.name {
                return " — \(name)"
            }
            return ""
        }
    }

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        return formatter.string(from: NSNumber(value: value)) ?? "£\(value)"
    }

    private func exportPDF() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.pdf]
        panel.nameFieldStringValue = "\(monthLabel) Spending Report\(filterLabel).pdf"
        panel.level = .floating
        guard panel.runModal() == .OK, let url = panel.url else { return }

        let pageWidth: CGFloat = 595
        let pageHeight: CGFloat = 842
        let margin: CGFloat = 50
        let contentWidth = pageWidth - margin * 2

        var mediaBox = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        guard let context = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else { return }

        context.beginPage(mediaBox: &mediaBox)

        let titleFont = NSFont.boldSystemFont(ofSize: 22)
        let headingFont = NSFont.boldSystemFont(ofSize: 14)
        let bodyFont = NSFont.systemFont(ofSize: 11)
        let bodyBoldFont = NSFont.boldSystemFont(ofSize: 11)

        var y = pageHeight - margin

        let title = NSAttributedString(string: "\(monthLabel) — Spending Report\(filterLabel)", attributes: [
            .font: titleFont, .foregroundColor: NSColor.black
        ])
        let titleLine = CTLineCreateWithAttributedString(title)
        context.textPosition = CGPoint(x: margin, y: y - 22)
        CTLineDraw(titleLine, context)
        y -= 50

        let subtitle = NSAttributedString(string: "Generated \(Date().formatted(date: .long, time: .shortened))", attributes: [
            .font: bodyFont, .foregroundColor: NSColor.gray
        ])
        let subtitleLine = CTLineCreateWithAttributedString(subtitle)
        context.textPosition = CGPoint(x: margin, y: y)
        CTLineDraw(subtitleLine, context)
        y -= 40

        let headerBg = CGRect(x: margin, y: y - 4, width: contentWidth, height: 20)
        context.setFillColor(NSColor(white: 0.9, alpha: 1).cgColor)
        context.fill(headerBg)

        drawText(context: context, text: "Category", font: headingFont, x: margin + 8, y: y)
        drawText(context: context, text: "Amount", font: headingFont, x: pageWidth - margin - 80, y: y)
        drawText(context: context, text: "%", font: headingFont, x: pageWidth - margin - 20, y: y)
        y -= 24

        for (index, item) in chartData.enumerated() {
            if index % 2 == 0 {
                let rowBg = CGRect(x: margin, y: y - 4, width: contentWidth, height: 20)
                context.setFillColor(NSColor(white: 0.96, alpha: 1).cgColor)
                context.fill(rowBg)
            }

            let dotRect = CGRect(x: margin + 8, y: y + 1, width: 8, height: 8)
            context.setFillColor(NSColor(hex: item.colorHex).cgColor)
            context.fillEllipse(in: dotRect)

            drawText(context: context, text: item.name, font: bodyFont, x: margin + 22, y: y)
            drawText(context: context, text: formattedCurrency(item.total), font: bodyFont, x: pageWidth - margin - 80, y: y)
            drawText(context: context, text: "\(Int(item.percentage))%", font: bodyFont, x: pageWidth - margin - 20, y: y)
            y -= 20
        }

        y -= 4
        context.setStrokeColor(NSColor.black.cgColor)
        context.setLineWidth(1)
        context.move(to: CGPoint(x: margin, y: y + 16))
        context.addLine(to: CGPoint(x: pageWidth - margin, y: y + 16))
        context.strokePath()

        drawText(context: context, text: "Total", font: bodyBoldFont, x: margin + 8, y: y)
        drawText(context: context, text: formattedCurrency(totalSpending), font: bodyBoldFont, x: pageWidth - margin - 80, y: y)
        y -= 40

        for item in chartData {
            guard let category = categories.first(where: { $0.name == item.name }) else { continue }

            let txns = filteredTransactions(for: category).sorted { $0.date > $1.date }

            if y < 100 {
                context.endPage()
                context.beginPage(mediaBox: &mediaBox)
                y = pageHeight - margin
            }

            let catHeader = NSAttributedString(string: "\(item.name) — \(formattedCurrency(item.total))", attributes: [
                .font: headingFont, .foregroundColor: NSColor.black
            ])
            let catLine = CTLineCreateWithAttributedString(catHeader)
            context.textPosition = CGPoint(x: margin, y: y)
            CTLineDraw(catLine, context)
            y -= 22

            for txn in txns {
                if y < 60 {
                    context.endPage()
                    context.beginPage(mediaBox: &mediaBox)
                    y = pageHeight - margin
                }

                drawText(context: context, text: txn.date.formatted(date: .abbreviated, time: .omitted), font: bodyFont, x: margin + 8, y: y)
                drawText(context: context, text: txn.desc, font: bodyFont, x: margin + 90, y: y)
                drawText(context: context, text: formattedCurrency(abs(txn.amount)), font: bodyFont, x: pageWidth - margin - 80, y: y)
                y -= 18
            }

            y -= 14
        }

        context.endPage()
        context.closePDF()
        NSWorkspace.shared.open(url)
    }

    private func drawText(context: CGContext, text: String, font: NSFont, x: CGFloat, y: CGFloat) {
        let attr = NSAttributedString(string: text, attributes: [
            .font: font, .foregroundColor: NSColor.black
        ])
        let line = CTLineCreateWithAttributedString(attr)
        context.textPosition = CGPoint(x: x, y: y)
        CTLineDraw(line, context)
    }
}

private struct FilterPill: View {
    let label: String
    var colorHex: String? = nil
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let hex = colorHex {
                    Circle()
                        .fill(Color(hex: hex))
                        .frame(width: 6, height: 6)
                }
                Text(label)
                    .font(.caption)
                    .lineLimit(1)
                    .fixedSize()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(isSelected ? Color.white.opacity(0.15) : Color.secondary.opacity(0.15))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(isSelected ? Color.white.opacity(0.4) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

private struct SpendingRow: View {
    let item: SpendingChartView.ChartItem
    var isHovered: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Circle()
                    .fill(Color(hex: item.colorHex))
                    .frame(width: 10, height: 10)
                Text(item.name)
                    .font(.body)
                Spacer()
                Text(formattedCurrency(item.total))
                    .font(.body.monospacedDigit())
                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func formattedCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        return formatter.string(from: NSNumber(value: value)) ?? "£\(value)"
    }
}

extension NSColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255.0
        let g = Double((int >> 8) & 0xFF) / 255.0
        let b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

struct CategoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    let category: Category
    let selectedMonth: Date
    var occasionFilter: OccasionFilter = .all
    var onBack: () -> Void

    private var monthTransactions: [Transaction] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedMonth)
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else { return [] }

        return category.transactions
            .filter { txn in
                guard txn.date >= startOfMonth && txn.date < endOfMonth else { return false }
                switch occasionFilter {
                case .all:
                    return true
                case .noOccasion:
                    return txn.occasion == nil
                case .occasion(let id):
                    return txn.occasion?.persistentModelID == id
                }
            }
            .sorted { $0.date > $1.date }
    }

    @State private var showUncategorizeAllConfirm = false

    private struct DateGroup {
        let date: Date
        let transactions: [Transaction]
    }

    private var groupedByDate: [DateGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: monthTransactions) { txn in
            calendar.startOfDay(for: txn.date)
        }
        return grouped.keys.sorted(by: >).map { DateGroup(date: $0, transactions: grouped[$0]!) }
    }

    var body: some View {
        VStack(spacing: 0) {
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
                Circle()
                    .fill(category.color)
                    .frame(width: 10, height: 10)
                Text(category.name)
                    .font(.headline)
                Spacer()
                // Balance the back button width
                Text("Back")
                    .font(.body)
                    .hidden()
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            if monthTransactions.isEmpty {
                Text("No transactions this month")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack {
                    Text("\(monthTransactions.count) transaction\(monthTransactions.count == 1 ? "" : "s")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(formattedAmount(monthTransactions.reduce(0) { $0 + $1.amount }))
                        .font(.caption.weight(.semibold).monospacedDigit())
                }
                .padding(.horizontal)
                .padding(.vertical, 6)

                Divider()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(groupedByDate, id: \.date) { group in
                            Text(group.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)
                                .padding(.top, 8)
                                .padding(.bottom, 4)

                            ForEach(group.transactions) { txn in
                                CategoryTransactionRow(transaction: txn) {
                                    uncategorize(txn)
                                }
                                Divider()
                            }
                        }
                    }
                }

                Divider()

                if showUncategorizeAllConfirm {
                    HStack(spacing: 12) {
                        Text("Remove all from \(category.name)?")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Button("Cancel") {
                            showUncategorizeAllConfirm = false
                        }
                        .font(.caption)
                        .buttonStyle(.plain)
                        Button("Confirm") {
                            uncategorizeAll()
                        }
                        .font(.caption)
                        .foregroundStyle(.red)
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                } else {
                    Button {
                        showUncategorizeAllConfirm = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "xmark.circle")
                                .font(.caption)
                            Text("Uncategorize All")
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
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func uncategorize(_ transaction: Transaction) {
        transaction.category = nil
        try? modelContext.save()
    }

    private func uncategorizeAll() {
        for txn in monthTransactions {
            txn.category = nil
        }
        try? modelContext.save()
        showUncategorizeAllConfirm = false
        onBack()
    }

    private func formattedAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        return formatter.string(from: NSNumber(value: abs(value))) ?? "£\(abs(value))"
    }
}

private struct CategoryTransactionRow: View {
    let transaction: Transaction
    let onUncategorize: () -> Void
    @State private var isHovered = false

    var body: some View {
        HStack {
            Text(transaction.desc)
                .font(.body)
                .lineLimit(1)

            Spacer()

            Text(formattedAmount)
                .font(.body.monospacedDigit())

            Button {
                onUncategorize()
            } label: {
                Image(systemName: "xmark.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .help("Remove from category")
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
        .contentShape(Rectangle())
        .onHover { hovering in isHovered = hovering }
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        return formatter.string(from: NSNumber(value: abs(transaction.amount))) ?? "£\(abs(transaction.amount))"
    }
}
