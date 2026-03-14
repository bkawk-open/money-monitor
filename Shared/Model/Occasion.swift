import Foundation
import SwiftData

@Model
final class Occasion {
    @Attribute(.unique) var name: String
    var colorHex: String
    @Relationship(deleteRule: .nullify, inverse: \Transaction.occasion)
    var transactions: [Transaction]

    init(name: String, colorHex: String) {
        self.name = name
        self.colorHex = colorHex
        self.transactions = []
    }
}
