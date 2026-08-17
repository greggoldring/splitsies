import Foundation

extension Split {
    /// Sea-level pressure when elevation is known (from race or provided).
    func seaLevelPressureHPa(elevationM: Double?) -> Double? {
        guard let stationPressureHPa else { return nil }
        return PressureMath.seaLevelPressure(
            stationHPa: stationPressureHPa,
            elevationM: elevationM,
            temperatureC: temperatureC
        )
    }

    var airDensityKgM3: Double? {
        guard let stationPressureHPa else { return nil }
        return PressureMath.airDensity(
            stationHPa: stationPressureHPa,
            temperatureC: temperatureC,
            relativeHumidityPct: relativeHumidityPct
        )
    }
}
