import Foundation
import SwiftData

@Model
final class Race {
    var id: UUID
    var createdAt: Date
    var name: String
    var totalDuration: TimeInterval
    @Relationship(deleteRule: .cascade, inverse: \Split.race)
    var splits: [Split] = []

    init(id: UUID = UUID(), createdAt: Date = Date(), name: String, totalDuration: TimeInterval, splits: [Split] = []) {
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.totalDuration = totalDuration
        self.splits = splits
    }
}
