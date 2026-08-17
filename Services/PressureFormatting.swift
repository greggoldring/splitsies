import Foundation

enum PressureFormatting {
    nonisolated static func density(_ kgM3: Double) -> String {
        String(format: "%.3f kg/m³", kgM3)
    }

    nonisolated static func pressureChip(
        hPa: Double?,
        source: PressureSource,
        unit: PressureUnit,
        pending: Bool
    ) -> String {
        if let hPa {
            let label: String
            switch source {
            case .barometer: label = "barometer"
            case .weatherAPI: label = "weather"
            case .none: label = "unknown"
            }
            return "\(unit.format(hPa)) · \(label)"
        }
        if pending {
            return "pressure pending"
        }
        return "no pressure"
    }

    nonisolated static func sourceLabel(_ source: PressureSource) -> String {
        switch source {
        case .barometer: return "Barometer"
        case .weatherAPI: return "Weather API"
        case .none: return "None"
        }
    }
}
