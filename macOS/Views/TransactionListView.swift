import SwiftUI
import SwiftData

struct TransactionListView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var model: MoneyMonitorModel
    @Query(
        filter: #Predicate<Transaction> { $0.category == nil },
        sort: \Transaction.date,
        order: .reverse
    ) private var allUncategorized: [Transaction]

    @Binding var hideTabs: Bool
    @Binding var selectedMonth: Date
    @Binding var selectedTransaction: Transaction?
    @State private var hostWindow: NSWindow?

    private var isCurrentMonth: Bool {
        let cal = Calendar.current
        return cal.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    private var monthStart: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: selectedMonth))!
    }

    private var monthEnd: Date {
        Calendar.current.date(byAdding: .month, value: 1, to: monthStart)!
    }

    private var uncategorized: [Transaction] {
        allUncategorized.filter { $0.date >= monthStart && $0.date < monthEnd }
    }

    private var monthLabel: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: monthStart)
    }

    var body: some View {
        ZStack {
            transactionListContent
                .opacity(selectedTransaction == nil ? 1 : 0)

            if let txn = selectedTransaction {
                CategoryPickerView(transaction: txn) {
                    model.updateCounts()
                    selectedTransaction = nil
                    hideTabs = false
                }
            }
        }
        .background(WindowFinder(window: $hostWindow))
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
                self.hideTabs = false
                NSApp.activate(ignoringOtherApps: true)
                window?.makeKeyAndOrderFront(nil)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    window?.hidesOnDeactivate = true
                }
            }
        }
    }

    private var uncategorizedTotal: String {
        let total = uncategorized.reduce(0.0) { $0 + abs($1.amount) }
        return CurrencyFormatter.format(total)
    }

    private struct DateGroup {
        let date: Date
        let transactions: [Transaction]
    }

    private var groupedByDate: [DateGroup] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: uncategorized) { txn in
            calendar.startOfDay(for: txn.date)
        }
        return grouped.keys.sorted(by: >).map { DateGroup(date: $0, transactions: grouped[$0]!) }
    }

    private var transactionListContent: some View {
        VStack(spacing: 0) {
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
                .disabled(isCurrentMonth)
                .buttonStyle(.plain)
            }
            .padding(.horizontal)
            .padding(.vertical, 4)

            Divider()

            HStack {
                Text("Uncategorized")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(uncategorizedTotal)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(uncategorized.count)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.secondary.opacity(0.2))
                    .clipShape(Capsule())
            }
            .padding(.horizontal)
            .padding(.vertical, 6)

            Divider()

            if uncategorized.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 32))
                        .foregroundStyle(.green)
                    Text("You're all sorted")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let lastDate = model.lastTransactionDate {
                        Text("Latest transaction: \(lastDate.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
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
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
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
                                TransactionRow(transaction: txn)
                                    .onTapGesture {
                                        selectedTransaction = txn
                                        hideTabs = true
                                    }
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }
}

struct TransactionRow: View {
    let transaction: Transaction
    @State private var isHovered = false

    var body: some View {
        HStack {
            Text(transaction.desc)
                .font(.body)
                .lineLimit(1)

            Spacer()

            Text(formattedAmount)
                .font(.body.monospacedDigit())

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .background(isHovered ? Color.white.opacity(0.08) : Color.white.opacity(0.03))
        .contentShape(Rectangle())
        .onHover { hovering in
            isHovered = hovering
        }
    }

    private var formattedAmount: String {
        CurrencyFormatter.formatAbsolute(transaction.amount)
    }
}
