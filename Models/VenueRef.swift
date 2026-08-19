import Foundation

/// Unified venue reference used by pickers and pressure services.
struct VenueRef: Identifiable, Hashable, Sendable {
    let id: String
    let name: String
    let city: String
    let region: String?
    let country: String
    let countryCode: String?
    let latitude: Double?
    let longitude: Double?
    let elevationM: Double?
    let indoor: Bool
    let status: VenueStatus
    let isCustom: Bool

    var hasCoordinates: Bool {
        latitude != nil && longitude != nil
    }

    var displaySubtitle: String {
        let parts = [city, country].filter { !$0.isEmpty }
        return parts.joined(separator: ", ")
    }

    nonisolated static func from(_ bundled: BundledVelodrome) -> VenueRef {
        VenueRef(
            id: bundled.id,
            name: bundled.name,
            city: bundled.city,
            region: bundled.region,
            country: bundled.country,
            countryCode: bundled.countryCode,
            latitude: bundled.latitude,
            longitude: bundled.longitude,
            elevationM: bundled.elevationM,
            indoor: bundled.indoor,
            status: bundled.status,
            isCustom: false
        )
    }

    nonisolated static func from(_ custom: CustomVenue) -> VenueRef {
        VenueRef(
            id: custom.id,
            name: custom.name,
            city: custom.city,
            region: nil,
            country: custom.country,
            countryCode: nil,
            latitude: custom.latitude,
            longitude: custom.longitude,
            elevationM: custom.elevationM,
            indoor: custom.indoor,
            status: .active,
            isCustom: true
        )
    }
}
