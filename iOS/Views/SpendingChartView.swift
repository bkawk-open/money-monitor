import SwiftUI
import SwiftData
import Charts

struct SpendingChartView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var model: MoneyMonitorModel
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Occasion.name) private var occasions: [Occasion]

    @Binding var selectedMonth: Date
    @State private var selectedCategory: Category?
    @State private var tappedItem: String?
    @State private var occasionFilter: OccasionFilter = .all

    private var isCurrentMonth: Bool {
        let cal = Calendar.current
        return cal.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    var body: some View {
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

    private var spendingContent: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    Button {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    Spacer()

                    Text(monthLabel)
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Button {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.body)
                            .foregroundStyle(isCurrentMonth ? .quaternary : .secondary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .disabled(isCurrentMonth)
                }
                .padding(.horizontal)
                .padding(.vertical, 2)

                if monthHasOccasions {
                    ScrollView(.horizontal, showsIndicators: false) {
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
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.bottom, 4)
                }

                Divider()

                if chartData.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.pie")
                            .font(.system(size: 32))
                            .foregroundStyle(.secondary)
                        Text("Nothing to show yet")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    ZStack {
                        Chart(chartData, id: \.name) { item in
                            SectorMark(
                                angle: .value("Amount", item.total),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .foregroundStyle(Color(hex: item.colorHex))
                            .opacity(tappedItem == nil || tappedItem == item.name ? 1.0 : 0.4)
                        }
                        .frame(height: 220)

                        if let name = tappedItem, let item = chartData.first(where: { $0.name == name }) {
                            VStack(spacing: 2) {
                                Text("\(Int(item.percentage))%")
                                    .font(.title2.bold())
                                Text(item.name)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .onTapGesture {
                        tappedItem = nil
                    }

                    Divider()

                    ForEach(chartData, id: \.name) { item in
                        Button {
                            if tappedItem == item.name {
                                selectedCategory = categories.first { $0.name == item.name }
                            } else {
                                tappedItem = item.name
                            }
                        } label: {
                            HStack {
                                Circle()
                                    .fill(Color(hex: item.colorHex))
                                    .frame(width: 10, height: 10)
                                Text(item.name)
                                    .font(.callout)
                                    .foregroundStyle(.primary)
                                Spacer()
                                Text(formattedCurrency(item.total))
                                    .font(.callout.monospacedDigit())
                                    .foregroundStyle(.primary)
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(tappedItem == item.name ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
                        }
                        .buttonStyle(.plain)
                        Divider()
                    }

                    HStack {
                        Text("Total")
                            .font(.callout.weight(.semibold))
                        Spacer()
                        Text(formattedCurrency(totalSpending))
                            .font(.callout.weight(.semibold).monospacedDigit())
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.16, green: 0.16, blue: 0.16))
        .navigationTitle("")
        .navigationBarHidden(true)
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

    private func formattedCurrency(_ value: Double) -> String {
        CurrencyFormatter.format(value)
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

struct CategoryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var model: MoneyMonitorModel
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

                Spacer()

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
                        ForEach(monthTransactions) { txn in
                            HStack {
                                Text(txn.desc)
                                    .font(.callout)
                                    .lineLimit(1)

                                Spacer()

                                Text(txn.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)

                                Text(formattedAmount(txn.amount))
                                    .font(.callout.monospacedDigit())
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 10)
                            .background(Color.white.opacity(0.03))

                            Divider()
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.16, green: 0.16, blue: 0.16))
        .navigationTitle("")
        .navigationBarHidden(true)
    }

    private func formattedAmount(_ value: Double) -> String {
        CurrencyFormatter.formatAbsolute(value)
    }
}
