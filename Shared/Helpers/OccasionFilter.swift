import SwiftData

enum OccasionFilter: Equatable {
    case all
    case noOccasion
    case occasion(PersistentIdentifier)
}
