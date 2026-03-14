import SwiftUI
import SwiftData

struct CategoryPickerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.name) private var categories: [Category]
    @Query(sort: \Occasion.name) private var occasions: [Occasion]

    let transaction: Transaction
    var onDone: () -> Void

    @State private var selectedOccasion: Occasion?

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(transaction.desc)
                        .font(.body.bold())
                        .lineLimit(1)
                    Spacer()
                    Text(formattedAmount)
                        .font(.body.bold().monospacedDigit())
                }
                Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Occasion")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                FlowLayout(spacing: 6) {
                    Button {
                        selectedOccasion = nil
                    } label: {
                        Text("None")
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(selectedOccasion == nil ? Color.white.opacity(0.15) : Color.secondary.opacity(0.15))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(selectedOccasion == nil ? Color.white.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)

                    ForEach(occasions) { occasion in
                        Button {
                            selectedOccasion = occasion
                        } label: {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color(hex: occasion.colorHex))
                                    .frame(width: 8, height: 8)
                                Text(occasion.name)
                                    .font(.caption)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(selectedOccasion?.id == occasion.id ? Color.white.opacity(0.15) : Color.secondary.opacity(0.15))
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .strokeBorder(selectedOccasion?.id == occasion.id ? Color.white.opacity(0.4) : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)

            }
            .padding(.vertical, 6)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Category")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                if !categories.isEmpty {
                    FlowLayout(spacing: 6) {
                        ForEach(categories) { category in
                            Button {
                                assignCategory(category)
                            } label: {
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(category.color)
                                        .frame(width: 8, height: 8)
                                    Text(category.name)
                                        .font(.caption)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.secondary.opacity(0.15))
                                .cornerRadius(12)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }

            }
            .padding(.vertical, 6)

            Spacer()
        }
        .onAppear {
            selectedOccasion = transaction.occasion
            seedDefaultCategoriesIfNeeded()
            seedDefaultOccasionsIfNeeded()
        }
        .navigationTitle("Categorize")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
    }

    private var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "GBP"
        return formatter.string(from: NSNumber(value: abs(transaction.amount))) ?? "\(transaction.amount)"
    }

    private func assignCategory(_ category: Category) {
        transaction.category = category
        transaction.occasion = selectedOccasion

        let desc = transaction.desc
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.desc == desc && $0.category == nil }
        )
        if let matches = try? modelContext.fetch(descriptor) {
            for txn in matches {
                txn.category = category
                txn.occasion = selectedOccasion
            }
        }

        try? modelContext.save()
        onDone()
        dismiss()
    }

    private static let defaultCategories: [(String, String)] = [
        ("Housing", "3498DB"),
        ("Bills & Utilities", "E67E22"),
        ("Groceries", "2ECC71"),
        ("Transport", "1ABC9C"),
        ("Shopping", "9B59B6"),
        ("Eating Out", "E91E63"),
        ("Subscriptions", "00BCD4"),
        ("Travel", "8BC34A"),
        ("Health & Fitness", "FF9800"),
        ("Entertainment", "E74C3C"),
        ("Financial", "607D8B"),
        ("Transfers", "795548"),
        ("Gambling", "FF5722"),
        ("Other", "673AB7"),
    ]

    private func seedDefaultCategoriesIfNeeded() {
        guard categories.isEmpty else { return }
        for (name, color) in Self.defaultCategories {
            modelContext.insert(Category(name: name, colorHex: color))
        }
        try? modelContext.save()
    }

    private static let defaultOccasions: [(String, String)] = [
        ("Holiday", "FF6B6B"),
        ("Birthday", "FFD93D"),
        ("Wedding", "6BCB77"),
        ("Christmas", "4D96FF"),
        ("Moving House", "FF8E53"),
        ("New Baby", "C780E8"),
        ("Graduation", "45B7D1"),
        ("Anniversary", "F97B22"),
        ("Weekend Trip", "20C997"),
        ("Night Out", "845EC2"),
        ("Work Travel", "FF6F91"),
        ("Family Visit", "67E6DC"),
        ("Home Improvement", "FFC75F"),
        ("Car Purchase", "D65DB1"),
        ("Medical", "2C73D2"),
    ]

    private func seedDefaultOccasionsIfNeeded() {
        guard occasions.isEmpty else { return }
        for (name, color) in Self.defaultOccasions {
            modelContext.insert(Occasion(name: name, colorHex: color))
        }
        try? modelContext.save()
    }

}

private struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y),
                                  proposal: .unspecified)
        }
    }

    private struct ArrangeResult {
        var size: CGSize
        var positions: [CGPoint]
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> ArrangeResult {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return ArrangeResult(
            size: CGSize(width: maxWidth, height: y + rowHeight),
            positions: positions
        )
    }
}
