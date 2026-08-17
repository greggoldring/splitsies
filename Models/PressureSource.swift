import Foundation

enum PressureSource: String, Codable, Sendable, CaseIterable {
    case barometer
    case weatherAPI
    case none
}
