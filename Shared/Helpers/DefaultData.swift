import Foundation
import SwiftData

enum DefaultData {
    static let categories: [(name: String, colorHex: String)] = [
        ("Housing", "3498DB"),
        ("Bills & Utilities", "E67E22"),
        ("Supermarkets", "2ECC71"),
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

    static let occasions: [(name: String, colorHex: String)] = [
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

    static func seedCategoriesIfNeeded(into context: ModelContext, existingCount: Int) {
        guard existingCount == 0 else { return }
        for (name, color) in categories {
            context.insert(Category(name: name, colorHex: color))
        }
        try? context.save()
    }

    static func seedOccasionsIfNeeded(into context: ModelContext, existingCount: Int) {
        guard existingCount == 0 else { return }
        for (name, color) in occasions {
            context.insert(Occasion(name: name, colorHex: color))
        }
        try? context.save()
    }
}
