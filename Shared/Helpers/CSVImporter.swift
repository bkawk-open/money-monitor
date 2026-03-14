import Foundation
import SwiftData

struct CSVImporter {
    enum CSVError: LocalizedError {
        case invalidFormat
        case noTransactions

        var errorDescription: String? {
            switch self {
            case .invalidFormat: "Invalid CSV format. Expected Halifax transaction export."
            case .noTransactions: "No new transactions found in file."
            }
        }
    }

    static func importFile(url: URL, into context: ModelContext) throws -> Int {
        let content = try String(contentsOf: url, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        guard lines.count > 1 else { throw CSVError.noTransactions }

        let header = lines[0].lowercased()
        guard header.contains("transaction date") && header.contains("transaction description") else {
            throw CSVError.invalidFormat
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd/MM/yyyy"

        var imported = 0

        for line in lines.dropFirst() {
            let fields = parseLine(line)
            guard fields.count >= 8 else { continue }

            let dateString = fields[0].trimmingCharacters(in: .whitespaces)
            let _ = fields[1].trimmingCharacters(in: .whitespaces)
            let description = fields[4].trimmingCharacters(in: .whitespaces)
            let debitString = fields[5].trimmingCharacters(in: .whitespaces)
            let _ = fields[6].trimmingCharacters(in: .whitespaces)

            guard let date = dateFormatter.date(from: dateString) else { continue }

            let amount: Double
            if !debitString.isEmpty, let debit = Double(debitString) {
                amount = -debit
            } else {
                continue // Skip income transactions
            }

            let txnId = "\(dateString)_\(description)_\(debitString)"

            let existsDescriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate { $0.bankTransactionId == txnId }
            )
            let existing = (try? context.fetch(existsDescriptor)) ?? []
            if !existing.isEmpty { continue }

            let transaction = Transaction(
                bankTransactionId: txnId,
                amount: amount,
                desc: description,
                date: date
            )

            let desc = description
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

    private static func parseLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current)
        return fields
    }
}
