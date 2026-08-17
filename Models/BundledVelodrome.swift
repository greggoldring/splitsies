import Foundation

struct VelodromeDataset: Codable, Sendable {
    let dataset: String
    let version: String
    let count: Int
    let velodromes: [BundledVelodrome]
}

struct BundledVelodrome: Codable, Sendable, Identifiable, Hashable {
    let id: String
    let name: String
    let city: String
    let region: String?
    let country: String
    let countryCode: String
    let latitude: Double
    let longitude: Double
    let elevationM: Double?
    let elevationSource: String?
    let indoor: Bool
    let trackLengthM: Double?
    let surface: String?
    let status: VenueStatus
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, name, city, region, country
        case countryCode = "country_code"
        case latitude, longitude
        case elevationM = "elevation_m"
        case elevationSource = "elevation_source"
        case indoor
        case trackLengthM = "track_length_m"
        case surface, status, notes
    }
}
