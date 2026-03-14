import Foundation
import SwiftData
import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

@Model
final class Category {
    @Attribute(.unique) var name: String
    var colorHex: String
    @Relationship(deleteRule: .nullify, inverse: \Transaction.category)
    var transactions: [Transaction]

    init(name: String, colorHex: String) {
        self.name = name
        self.colorHex = colorHex
        self.transactions = []
    }

    var color: Color {
        Color(hex: colorHex)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        #if canImport(AppKit)
        guard let components = NSColor(self).usingColorSpace(.sRGB) else { return "808080" }
        let r = Int(components.redComponent * 255)
        let g = Int(components.greenComponent * 255)
        let b = Int(components.blueComponent * 255)
        return String(format: "%02X%02X%02X", r, g, b)
        #elseif canImport(UIKit)
        var red: CGFloat = 0; var green: CGFloat = 0; var blue: CGFloat = 0
        UIColor(self).getRed(&red, green: &green, blue: &blue, alpha: nil)
        return String(format: "%02X%02X%02X", Int(red * 255), Int(green * 255), Int(blue * 255))
        #else
        return "808080"
        #endif
    }
}
