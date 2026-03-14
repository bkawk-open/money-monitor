import Foundation
import PDFKit
import SwiftData

struct PDFImporter {
    enum PDFError: LocalizedError {
        case cannotReadPDF
        case noTransactions
        case invalidFormat

        var errorDescription: String? {
            switch self {
            case .cannotReadPDF: "Could not read the PDF file."
            case .noTransactions: "No new transactions found in file."
            case .invalidFormat: "Invalid PDF format. Expected Halifax statement."
            }
        }
    }

    static func importFile(url: URL, into context: ModelContext) throws -> Int {
        guard let document = PDFDocument(url: url) else {
            throw PDFError.cannotReadPDF
        }

        var allText = ""
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            if let text = page.string {
                allText += text + "\n"
            }
        }

        guard allText.contains("Halifax") || allText.contains("CURRENT ACCOUNT") else {
            throw PDFError.invalidFormat
        }

        let (columnar, lastBalance) = parseColumnarText(allText)
        let inline = parseInlineTransactions(allText, lastBalance: lastBalance)

        // Combine columnar and inline, deduplicating by date+description+amount
        var seen = Set<String>()
        var transactions: [ParsedTransaction] = []
        for txn in columnar {
            let amt = txn.moneyOut ?? txn.moneyIn ?? 0
            let key = "\(txn.dateString)_\(txn.description)_\(String(format: "%.2f", amt))"
            if seen.insert(key).inserted {
                transactions.append(txn)
            }
        }
        for txn in inline {
            let amt = txn.moneyOut ?? txn.moneyIn ?? 0
            let key = "\(txn.dateString)_\(txn.description)_\(String(format: "%.2f", amt))"
            if seen.insert(key).inserted {
                transactions.append(txn)
            }
        }

        guard !transactions.isEmpty else {
            throw PDFError.noTransactions
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yy"
        dateFormatter.locale = Locale(identifier: "en_GB")

        let fullDateFormatter = DateFormatter()
        fullDateFormatter.dateFormat = "dd/MM/yyyy"

        var imported = 0

        for txn in transactions {
            guard let date = dateFormatter.date(from: txn.dateString) else { continue }

            guard let moneyOut = txn.moneyOut else {
                continue // Skip income transactions
            }
            let amount = -moneyOut

            let dateForId = fullDateFormatter.string(from: date)
            let debitStr = String(format: "%.2f", moneyOut)
            let txnId = "\(dateForId)_\(txn.description)_\(debitStr)"

            let existsDescriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate { $0.bankTransactionId == txnId }
            )
            let existing = (try? context.fetch(existsDescriptor)) ?? []
            if !existing.isEmpty { continue }

            let transaction = Transaction(
                bankTransactionId: txnId,
                amount: amount,
                desc: txn.description,
                date: date
            )

            let desc = txn.description
            let categoryDescriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate { $0.desc == desc && $0.category != nil }
            )
            if let match = (try? context.fetch(categoryDescriptor))?.first {
                transaction.category = match.category
            }

            context.insert(transaction)
            imported += 1
        }

        try context.save()
        return imported
    }

    private struct ParsedTransaction {
        let dateString: String
        let description: String
        let type: String
        let moneyIn: Double?
        let moneyOut: Double?
    }

    private static let datePattern = try! NSRegularExpression(pattern: #"^\d{2}\s+\w{3}\s+\d{2}\.?$"#)

    private static let transactionTypes: Set<String> = [
        "BGC", "BP", "CHG", "CHQ", "COR", "CPT", "DD", "DEB",
        "DEP", "FEE", "FPI", "FPO", "MPI", "MPO", "PAY", "SO", "TFR"
    ]

    private static let creditTypes: Set<String> = ["BGC", "FPI", "MPI", "DEP"]

    // MARK: - Columnar Parser

    /// Returns parsed transactions and the last balance value (for inline direction detection)
    private static func parseColumnarText(_ text: String) -> ([ParsedTransaction], Double) {
        let lines = text.components(separatedBy: .newlines)

        var dates: [String] = []
        var descriptions: [String] = []
        var types: [String] = []
        var moneyInValues: [String] = []
        var moneyOutValues: [String] = []
        var balanceValues: [Double] = []

        var inTransactions = false

        var i = 0
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)

            if line.contains("Your Transactions") {
                inTransactions = true
            }

            // Stop at the transaction types legend at the end
            if line.contains("Transaction types") {
                inTransactions = false
            }

            guard inTransactions else { i += 1; continue }

            // Collect dates: lines matching "DD Mon YY" pattern
            if isDateLine(line) {
                let date = line.hasSuffix(".") ? String(line.dropLast()) : line
                dates.append(date)
            }

            // Collect descriptions: lines after "Description" label
            if line == "Description" && i + 1 < lines.count {
                let next = lines[i + 1].trimmingCharacters(in: .whitespaces)
                if !next.isEmpty && !isLabel(next) && !isDateLine(next) && next != "Description" {
                    let desc = next.hasSuffix(".") ? String(next.dropLast()) : next
                    descriptions.append(desc)
                    i += 1
                }
            }

            // Collect types: known transaction type codes
            let cleaned = line.hasSuffix(".") ? String(line.dropLast()) : line
            if transactionTypes.contains(cleaned) {
                types.append(cleaned)
            }

            // Collect money in values
            if line == "Money In (£)" && i + 1 < lines.count {
                let next = lines[i + 1].trimmingCharacters(in: .whitespaces)
                if !next.isEmpty && !isLabel(next) && next != "Money In (£)" {
                    let val = next.hasSuffix(".") ? String(next.dropLast()) : next
                    moneyInValues.append(val)
                    i += 1
                }
            }

            // Collect money out values
            if line == "Money Out (£)" && i + 1 < lines.count {
                let next = lines[i + 1].trimmingCharacters(in: .whitespaces)
                if !next.isEmpty && !isLabel(next) && next != "Money Out (£)" {
                    let val = next.hasSuffix(".") ? String(next.dropLast()) : next
                    moneyOutValues.append(val)
                    i += 1
                }
            }

            // Collect balance values
            if line == "Balance (£)" && i + 1 < lines.count {
                let next = lines[i + 1].trimmingCharacters(in: .whitespaces)
                if !next.isEmpty && !isLabel(next) && next != "Balance (£)" {
                    let val = next.hasSuffix(".") ? String(next.dropLast()) : next
                    if let balance = parseAmount(val) {
                        balanceValues.append(balance)
                    }
                    i += 1
                }
            }

            i += 1
        }

        // Filter out "Date" header entries
        dates = dates.filter { $0.count >= 8 }

        // Build transactions by zipping columns, limited by dates and descriptions
        let count = min(dates.count, descriptions.count)

        var transactions: [ParsedTransaction] = []

        for idx in 0..<count {
            var moneyIn: Double?
            var moneyOut: Double?

            if idx < moneyInValues.count && moneyInValues[idx] != "blank" {
                moneyIn = parseAmount(moneyInValues[idx])
            }
            if idx < moneyOutValues.count && moneyOutValues[idx] != "blank" {
                moneyOut = parseAmount(moneyOutValues[idx])
            }

            if moneyIn == nil && moneyOut == nil {
                continue
            }

            let type = idx < types.count ? types[idx] : "DEB"

            transactions.append(ParsedTransaction(
                dateString: dates[idx],
                description: descriptions[idx],
                type: type,
                moneyIn: moneyIn,
                moneyOut: moneyOut
            ))
        }

        let lastBalance = balanceValues.last ?? 0
        return (transactions, lastBalance)
    }

    // MARK: - Inline Parser (handles last page format)

    /// Parses inline transactions (date → desc → type → amount on consecutive lines).
    /// Uses balance deltas to determine money in vs money out direction.
    private static func parseInlineTransactions(_ text: String, lastBalance: Double) -> [ParsedTransaction] {
        let lines = text.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespaces) }

        // First pass: find inline transaction candidates (date, desc, type, amount, line index)
        struct InlineCandidate {
            let dateString: String
            let description: String
            let type: String
            let amount: Double
            let lineIndex: Int
        }

        var candidates: [InlineCandidate] = []

        var i = 0
        while i < lines.count - 3 {
            let line = lines[i]

            if isDateLine(line) {
                let date = line.hasSuffix(".") ? String(line.dropLast()) : line
                let descRaw = lines[i + 1]
                let desc = descRaw.hasSuffix(".") ? String(descRaw.dropLast()) : descRaw
                let typeRaw = lines[i + 2]
                let type = typeRaw.hasSuffix(".") ? String(typeRaw.dropLast()) : typeRaw
                let amountRaw = lines[i + 3]
                let amountStr = amountRaw.hasSuffix(".") ? String(amountRaw.dropLast()) : amountRaw

                if !isLabel(descRaw) && !isDateLine(descRaw) && !transactionTypes.contains(desc) &&
                   transactionTypes.contains(type),
                   let amount = parseAmount(amountStr) {
                    candidates.append(InlineCandidate(
                        dateString: date, description: desc, type: type,
                        amount: amount, lineIndex: i
                    ))
                    i += 4
                    continue
                }
            }
            i += 1
        }

        guard !candidates.isEmpty else { return [] }

        // Second pass: find balance values after each inline transaction
        // Scan for numeric values that follow the inline block and could be balances
        var balancesAfterInline: [Double] = []
        let lastCandidateEnd = candidates.last!.lineIndex + 4
        for j in (candidates.first!.lineIndex + 4)..<lines.count {
            let line = lines[j]
            let cleaned = line.hasSuffix(".") ? String(line.dropLast()) : line
            if let val = parseAmount(cleaned), !isDateLine(line) && !transactionTypes.contains(cleaned.replacingOccurrences(of: ",", with: "")) {
                // Skip if this value equals one of the candidate amounts (it's an amount, not a balance)
                let isAmount = candidates.contains { abs($0.amount - val) < 0.01 }
                if !isAmount {
                    balancesAfterInline.append(val)
                }
            }
        }

        // Determine direction using balance deltas
        var transactions: [ParsedTransaction] = []
        var prevBalance = lastBalance

        for (idx, candidate) in candidates.enumerated() {
            var moneyIn: Double?
            var moneyOut: Double?

            if idx < balancesAfterInline.count {
                let nextBalance = balancesAfterInline[idx]
                let delta = nextBalance - prevBalance
                if delta > 0 {
                    // Balance increased → money in
                    moneyIn = candidate.amount
                } else {
                    // Balance decreased → money out
                    moneyOut = candidate.amount
                }
                prevBalance = nextBalance
            } else {
                // Fallback: use type-based heuristic
                if creditTypes.contains(candidate.type) {
                    moneyIn = candidate.amount
                } else {
                    moneyOut = candidate.amount
                }
            }

            transactions.append(ParsedTransaction(
                dateString: candidate.dateString,
                description: candidate.description,
                type: candidate.type,
                moneyIn: moneyIn,
                moneyOut: moneyOut
            ))
        }

        return transactions
    }

    // MARK: - Helpers

    private static func isDateLine(_ line: String) -> Bool {
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        return datePattern.firstMatch(in: line, range: range) != nil
    }

    private static func isLabel(_ line: String) -> Bool {
        let trimmed = line.trimmingCharacters(in: .init(charactersIn: "."))
        let labels: Set<String> = ["Column", "Date", "Description", "Type", "Money In (£)",
                                    "Money Out (£)", "Balance (£)", "Your Transactions",
                                    "(Continued on next page)", "blank"]
        return labels.contains(trimmed)
    }

    private static func parseAmount(_ str: String) -> Double? {
        let cleaned = str.replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "£", with: "")
        return Double(cleaned)
    }
}
