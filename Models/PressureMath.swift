import Foundation

/// Pure atmospheric calculations. Raw captured values remain the source of truth.
enum PressureMath {
    /// Sea-level reduction using the barometric formula.
    /// `p0 = p * (1 − 0.0065·h / (T + 0.0065·h + 273.15))^−5.257`
    /// Temperature defaults to 15 °C when unknown. Requires elevation.
    nonisolated static func seaLevelPressure(
        stationHPa: Double,
        elevationM: Double?,
        temperatureC: Double? = nil
    ) -> Double? {
        guard let elevationM else { return nil }
        let t = temperatureC ?? 15.0
        let denominator = t + 0.0065 * elevationM + 273.15
        guard denominator != 0 else { return nil }
        let ratio = 1.0 - (0.0065 * elevationM) / denominator
        guard ratio > 0 else { return nil }
        return stationHPa * pow(ratio, -5.257)
    }

    /// Moist-air density in kg/m³. Returns nil when temperature is unknown.
    nonisolated static func airDensity(
        stationHPa: Double,
        temperatureC: Double?,
        relativeHumidityPct: Double?
    ) -> Double? {
        guard let temperatureC else { return nil }
        let tk = temperatureC + 273.15
        guard tk > 0 else { return nil }

        let rh = relativeHumidityPct ?? 0
        // Magnus saturation vapor pressure (hPa)
        let es = 6.1094 * exp((17.625 * temperatureC) / (temperatureC + 243.04))
        let pv = (rh / 100.0) * es
        let pd = stationHPa - pv

        let rd = 287.058
        let rv = 461.495
        return (pd * 100.0) / (rd * tk) + (pv * 100.0) / (rv * tk)
    }
}
