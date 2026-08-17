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

    /// Venue reference id (bundled or custom). Nil means "No venue".
    var venueID: String?
    /// Offline display copies — survive custom-venue deletion and work without JSON.
    var venueName: String?
    var venueCity: String?
    var venueCountry: String?
    var venueLatitude: Double?
    var venueLongitude: Double?
    var venueElevationM: Double?
    var venueIndoor: Bool?

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        name: String,
        totalDuration: TimeInterval,
        splits: [Split] = [],
        venue: VenueRef? = nil
    ) {
        self.id = id
        self.createdAt = createdAt
        self.name = name
        self.totalDuration = totalDuration
        self.splits = splits
        if let venue {
            self.venueID = venue.id
            self.venueName = venue.name
            self.venueCity = venue.city
            self.venueCountry = venue.country
            self.venueLatitude = venue.latitude
            self.venueLongitude = venue.longitude
            self.venueElevationM = venue.elevationM
            self.venueIndoor = venue.indoor
        }
    }
}
