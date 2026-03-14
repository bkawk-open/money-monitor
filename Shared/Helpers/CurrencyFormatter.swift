import Foundation

enum CurrencyFormatter {
    private static let formatter: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = "GBP"
        return f
    }()

    static func format(_ value: Double) -> String {
        formatter.string(from: NSNumber(value: value)) ?? "£\(value)"
    }

    static func formatAbsolute(_ value: Double) -> String {
        format(abs(value))
    }
}
