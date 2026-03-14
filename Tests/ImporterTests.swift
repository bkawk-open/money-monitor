import XCTest
import SwiftData
import PDFKit
@testable import MoneyMonitor_macOS

final class ImporterTests: XCTestCase {

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema([Transaction.self, Category.self, AppSettings.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: [config])
    }

    private var csvURL: URL {
        URL(fileURLWithPath: "/Volumes/bkawk/projects/money-monitor/data/12012066_20261012_1203.csv")
    }

    private var pdfURL: URL {
        URL(fileURLWithPath: "/Volumes/bkawk/projects/money-monitor/data/Statement_2026_3.pdf")
    }

    // The PDF statement covers March 2026 only; CSV covers Feb-March.
    // Filter to March for fair comparison.
    private var marchStart: Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 3, day: 1))!
    }
    private var marchEnd: Date {
        Calendar.current.date(from: DateComponents(year: 2026, month: 4, day: 1))!
    }

    private func marchTransactions(from context: ModelContext) throws -> [Transaction] {
        let start = marchStart
        let end = marchEnd
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.date >= start && $0.date < end },
            sortBy: [SortDescriptor(\.bankTransactionId)]
        )
        return try context.fetch(descriptor)
    }

    /// A type-agnostic key for matching transactions across formats
    private func matchKey(for txn: Transaction) -> String {
        let dateStr = txn.date.formatted(.dateTime.day(.twoDigits).month(.twoDigits).year())
        return "\(dateStr)_\(txn.desc)_\(String(format: "%.2f", abs(txn.amount)))"
    }

    // MARK: - Basic Import Tests

    func testCSVImportsTransactions() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let count = try CSVImporter.importFile(url: csvURL, into: context)
        XCTAssertGreaterThan(count, 0, "CSV should import at least one transaction")
    }

    func testPDFImportsTransactions() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let count = try PDFImporter.importFile(url: pdfURL, into: context)
        XCTAssertGreaterThan(count, 0, "PDF should import at least one transaction")
    }

    // MARK: - March Data Comparison

    func testMarchTransactionCountMatches() throws {
        let csvContainer = try makeContainer()
        let csvContext = ModelContext(csvContainer)
        _ = try CSVImporter.importFile(url: csvURL, into: csvContext)
        let csvMarch = try marchTransactions(from: csvContext)

        let pdfContainer = try makeContainer()
        let pdfContext = ModelContext(pdfContainer)
        _ = try PDFImporter.importFile(url: pdfURL, into: pdfContext)
        let pdfMarch = try marchTransactions(from: pdfContext)

        XCTAssertEqual(csvMarch.count, pdfMarch.count,
            "March: CSV has \(csvMarch.count) transactions, PDF has \(pdfMarch.count)")
    }

    func testMarchAmountsMatchByDescription() throws {
        let csvContainer = try makeContainer()
        let csvContext = ModelContext(csvContainer)
        _ = try CSVImporter.importFile(url: csvURL, into: csvContext)
        let csvMarch = try marchTransactions(from: csvContext)

        let pdfContainer = try makeContainer()
        let pdfContext = ModelContext(pdfContainer)
        _ = try PDFImporter.importFile(url: pdfURL, into: pdfContext)
        let pdfMarch = try marchTransactions(from: pdfContext)

        let csvByKey = Dictionary(grouping: csvMarch, by: matchKey)
        let pdfByKey = Dictionary(grouping: pdfMarch, by: matchKey)

        let csvKeys = Set(csvByKey.keys)
        let pdfKeys = Set(pdfByKey.keys)

        let onlyInCSV = csvKeys.subtracting(pdfKeys).sorted()
        let onlyInPDF = pdfKeys.subtracting(csvKeys).sorted()

        XCTAssertTrue(onlyInCSV.isEmpty,
            "March transactions only in CSV (by desc/date/amount): \(onlyInCSV)")
        XCTAssertTrue(onlyInPDF.isEmpty,
            "March transactions only in PDF (by desc/date/amount): \(onlyInPDF)")
    }

    func testMarchTotalSpendingMatches() throws {
        let csvContainer = try makeContainer()
        let csvContext = ModelContext(csvContainer)
        _ = try CSVImporter.importFile(url: csvURL, into: csvContext)
        let csvMarch = try marchTransactions(from: csvContext)

        let pdfContainer = try makeContainer()
        let pdfContext = ModelContext(pdfContainer)
        _ = try PDFImporter.importFile(url: pdfURL, into: pdfContext)
        let pdfMarch = try marchTransactions(from: pdfContext)

        let csvTotal = csvMarch.reduce(0.0) { $0 + $1.amount }
        let pdfTotal = pdfMarch.reduce(0.0) { $0 + $1.amount }

        XCTAssertEqual(csvTotal, pdfTotal, accuracy: 0.01,
            "March net total: CSV=\(csvTotal), PDF=\(pdfTotal)")
    }

    func testMarchTransactionIdsMatch() throws {
        let csvContainer = try makeContainer()
        let csvContext = ModelContext(csvContainer)
        _ = try CSVImporter.importFile(url: csvURL, into: csvContext)
        let csvMarch = try marchTransactions(from: csvContext)

        let pdfContainer = try makeContainer()
        let pdfContext = ModelContext(pdfContainer)
        _ = try PDFImporter.importFile(url: pdfURL, into: pdfContext)
        let pdfMarch = try marchTransactions(from: pdfContext)

        let csvIds = Set(csvMarch.map(\.bankTransactionId))
        let pdfIds = Set(pdfMarch.map(\.bankTransactionId))

        let onlyInCSV = csvIds.subtracting(pdfIds).sorted()
        let onlyInPDF = pdfIds.subtracting(csvIds).sorted()

        XCTAssertTrue(onlyInCSV.isEmpty,
            "March IDs only in CSV: \(onlyInCSV)")
        XCTAssertTrue(onlyInPDF.isEmpty,
            "March IDs only in PDF: \(onlyInPDF)")
    }

    // MARK: - Deduplication Tests

    func testCSVDeduplication() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let first = try CSVImporter.importFile(url: csvURL, into: context)
        let second = try CSVImporter.importFile(url: csvURL, into: context)

        XCTAssertGreaterThan(first, 0)
        XCTAssertEqual(second, 0, "Re-importing same CSV should import 0 new transactions")
    }

    func testPDFDeduplication() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        let first = try PDFImporter.importFile(url: pdfURL, into: context)
        let second = try PDFImporter.importFile(url: pdfURL, into: context)

        XCTAssertGreaterThan(first, 0)
        XCTAssertEqual(second, 0, "Re-importing same PDF should import 0 new transactions")
    }

    func testCrossFormatDeduplication() throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        _ = try CSVImporter.importFile(url: csvURL, into: context)
        let pdfCount = try PDFImporter.importFile(url: pdfURL, into: context)

        XCTAssertEqual(pdfCount, 0,
            "Importing PDF after CSV should import 0 new — got \(pdfCount)")
    }
}
