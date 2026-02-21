import Foundation
import CoreData

extension Split {

    convenience init(
        context: NSManagedObjectContext,
        lapNumber: Int,
        splitTime: TimeInterval,
        lapDuration: TimeInterval,
        race: Race? = nil
    ) {
        self.init(context: context)
        self.lapNumber = Int16(lapNumber)
        self.splitTime = splitTime
        self.lapDuration = lapDuration
        self.race = race
    }
}
