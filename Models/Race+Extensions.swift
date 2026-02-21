import Foundation
import CoreData

extension Race {

    var splitsArray: [Split] {
        (splits as? Set<Split>)?.sorted { $0.lapNumber < $1.lapNumber } ?? []
    }

    convenience init(
        context: NSManagedObjectContext,
        id: UUID = UUID(),
        createdAt: Date = Date(),
        name: String,
        totalDuration: TimeInterval,
        splits: [Split] = []
    ) {
        self.init(context: context)
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.totalDuration = totalDuration
        self.splits = NSSet(array: splits)
    }

    nonisolated public override func awakeFromInsert() {
        super.awakeFromInsert()
        if id == nil { id = UUID() }
        if createdAt == nil { createdAt = Date() }
    }
}
