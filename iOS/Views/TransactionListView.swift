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

    @Binding var selectedMonth: Date
    @State private var selectedTransaction: Transaction?

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

    private var isCurrentMonth: Bool {
        let cal = Calendar.current
        return cal.isDate(selectedMonth, equalTo: Date(), toGranularity: .month)
    }

    private var uncategorizedTotal: String {
        let total = uncategorized.reduce(0.0) { $0 + abs($1.amount) }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        return formatter.string(from: NSNumber(value: total)) ?? "£\(total)"
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

    var body: some View {
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

            Divider()

            HStack {
                Text("Uncategorized")
                    .font(.caption)
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
            .padding(.vertical, 10)

            Divider()

            if uncategorized.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 32))
                        .foregroundStyle(.green)
                    Text("All caught up!")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
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
                                Button {
                                    selectedTransaction = txn
                                } label: {
                                    HStack {
                                        Text(txn.desc)
                                            .font(.callout)
                                            .lineLimit(1)
                                            .foregroundStyle(.primary)

                                        Spacer()

                                        Text(formattedAmount(txn.amount))
                                            .font(.callout.monospacedDigit())
                                            .foregroundStyle(.primary)

                                        Image(systemName: "chevron.right")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                    .padding(.horizontal)
                                    .padding(.vertical, 10)
                                    .background(Color.white.opacity(0.03))
                                }
                                .buttonStyle(.plain)
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.16, green: 0.16, blue: 0.16))
        .navigationTitle("")
        .navigationBarHidden(true)
        .sheet(item: $selectedTransaction) { txn in
            NavigationStack {
                CategoryPickerView(transaction: txn) {
                    model.updateCounts()
                    selectedTransaction = nil
                }
            }
            .presentationDetents([.medium, .large], selection: .constant(.large))
        }
    }

    private func formattedAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        return formatter.string(from: NSNumber(value: abs(value))) ?? "£\(abs(value))"
    }
}
