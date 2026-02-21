import Foundation
import CoreData

@MainActor
final class RaceRepository {
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func save(_ race: Race) throws {
        context.insert(race)
        try context.save()
    }

    func fetchAllRaces() throws -> [Race] {
        let request = NSFetchRequest<Race>(entityName: "Race")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Race.createdAt, ascending: false)]
        return try context.fetch(request)
    }

    func delete(_ race: Race) throws {
        context.delete(race)
        try context.save()
    }
}
