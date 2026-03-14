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
        CurrencyFormatter.formatAbsolute(transaction.amount)
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

    private func seedDefaultCategoriesIfNeeded() {
        DefaultData.seedCategoriesIfNeeded(into: modelContext, existingCount: categories.count)
    }

    private func seedDefaultOccasionsIfNeeded() {
        DefaultData.seedOccasionsIfNeeded(into: modelContext, existingCount: occasions.count)
    }

}
