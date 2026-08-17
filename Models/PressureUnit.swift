import Foundation

enum PressureUnit: String, Codable, Sendable, CaseIterable, Identifiable {
    case hPa
    case inHg
    case mmHg

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .hPa: return "hPa"
        case .inHg: return "inHg"
        case .mmHg: return "mmHg"
        }
    }

    /// Convert stored hPa to the selected display unit.
    nonisolated func convert(fromHPa hPa: Double) -> Double {
        switch self {
        case .hPa: return hPa
        case .inHg: return hPa * 0.0295299830714
        case .mmHg: return hPa * 0.750061561303
        }
    }

    nonisolated func format(_ hPa: Double) -> String {
        let value = convert(fromHPa: hPa)
        switch self {
        case .hPa:
            return String(format: "%.1f hPa", value)
        case .inHg:
            return String(format: "%.2f inHg", value)
        case .mmHg:
            return String(format: "%.1f mmHg", value)
        }
    }
}
