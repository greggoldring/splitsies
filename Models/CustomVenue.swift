import Foundation
import SwiftData

@Model
final class CustomVenue {
    var id: String
    var name: String
    var city: String
    var country: String
    var latitude: Double?
    var longitude: Double?
    var elevationM: Double?
    var indoor: Bool
    var createdAt: Date

    init(
        id: String = UUID().uuidString,
        name: String,
        city: String = "",
        country: String = "",
        latitude: Double? = nil,
        longitude: Double? = nil,
        elevationM: Double? = nil,
        indoor: Bool = false,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.city = city
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
        self.elevationM = elevationM
        self.indoor = indoor
        self.createdAt = createdAt
    }
}
