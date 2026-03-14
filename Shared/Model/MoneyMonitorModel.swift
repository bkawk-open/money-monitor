import Foundation
import SwiftData
import SwiftUI

@MainActor
final class MoneyMonitorModel: ObservableObject {
    private var modelContext: ModelContext?

    @Published var uncategorizedCount = 0
    @Published var totalCount = 0
    @Published var lastImportDate: Date?
    @Published var lastError: String?
    @Published var missingStatementForLastMonth = false
    @Published var lastTransactionDate: Date?

    func configure(modelContext: ModelContext) {
        self.modelContext = modelContext
        updateCounts()
    }

    var settings: AppSettings? {
        guard let context = modelContext else { return nil }
        let descriptor = FetchDescriptor<AppSettings>()
        if let existing = try? context.fetch(descriptor).first {
            return existing
        }
        let settings = AppSettings()
        context.insert(settings)
        try? context.save()
        return settings
    }

    func importCSV(url: URL) {
        guard let context = modelContext else { return }
        lastError = nil

        do {
            let imported = try CSVImporter.importFile(url: url, into: context)
            if imported > 0 {
                lastImportDate = Date()
                settings?.lastFetch = Date()
                try? context.save()
            }
            updateCounts()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func importPDF(url: URL) {
        guard let context = modelContext else { return }
        lastError = nil

        do {
            let imported = try PDFImporter.importFile(url: url, into: context)
            if imported > 0 {
                lastImportDate = Date()
                settings?.lastFetch = Date()
                try? context.save()
            }
            updateCounts()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func updateCounts() {
        guard let context = modelContext else { return }
        let uncatDescriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.category == nil }
        )
        uncategorizedCount = (try? context.fetchCount(uncatDescriptor)) ?? 0

        let allDescriptor = FetchDescriptor<Transaction>()
        totalCount = (try? context.fetchCount(allDescriptor)) ?? 0

        updateLastTransactionDate()
        checkMissingStatement()
    }

    private func updateLastTransactionDate() {
        guard let context = modelContext else { return }
        var descriptor = FetchDescriptor<Transaction>(
            sortBy: [SortDescriptor(\Transaction.date, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        lastTransactionDate = (try? context.fetch(descriptor))?.first?.date
    }

    private func checkMissingStatement() {
        guard let context = modelContext else { return }
        guard totalCount > 0 else {
            missingStatementForLastMonth = false
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: now)
        guard let startOfCurrentMonth = calendar.date(from: currentMonthComponents),
              let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfCurrentMonth) else { return }

        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate<Transaction> { txn in
                txn.date >= startOfLastMonth && txn.date < startOfCurrentMonth
            }
        )
        let count = (try? context.fetchCount(descriptor)) ?? 0
        missingStatementForLastMonth = count == 0
    }
}
