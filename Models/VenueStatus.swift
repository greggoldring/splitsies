import Foundation

enum VenueStatus: String, Codable, Sendable, CaseIterable {
    case active
    case uncertain
    case demolished
}
