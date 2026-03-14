import Foundation
import SwiftData

@Model
final class AppSettings {
    var installDate: Date
    var lastFetch: Date?
    var accountId: String?

    init(installDate: Date = Date(), lastFetch: Date? = nil, accountId: String? = nil) {
        self.installDate = installDate
        self.lastFetch = lastFetch
        self.accountId = accountId
    }
}
