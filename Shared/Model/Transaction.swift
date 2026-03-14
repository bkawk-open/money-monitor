import Foundation
import SwiftData

@Model
final class Transaction {
    @Attribute(.unique) var bankTransactionId: String
    var amount: Double
    var desc: String
    var date: Date
    var category: Category?
    var occasion: Occasion?

    init(bankTransactionId: String, amount: Double, desc: String, date: Date, category: Category? = nil, occasion: Occasion? = nil) {
        self.bankTransactionId = bankTransactionId
        self.amount = amount
        self.desc = desc
        self.date = date
        self.category = category
        self.occasion = occasion
    }

    var isUncategorized: Bool {
        category == nil
    }
}
