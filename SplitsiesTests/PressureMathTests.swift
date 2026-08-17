import Foundation
import Testing
@testable import Splitsies

struct PressureMathTests {

    @Test func airDensityISASeaLevelDryAir() {
        // 1013.25 hPa, 15 °C, 0% RH → ≈ 1.225 kg/m³
        let density = PressureMath.airDensity(
            stationHPa: 1013.25,
            temperatureC: 15,
            relativeHumidityPct: 0
        )
        #expect(density != nil)
        #expect(abs(density! - 1.225) < 0.002)
    }

    @Test func seaLevelReductionEdmontonExample() {
        // Station 950 hPa at 671 m, 15 °C → ≈ 1028 hPa via the specified formula
        // (prompt ballpark was ~1030 ± 1; assert against the formula itself)
        let p0 = PressureMath.seaLevelPressure(
            stationHPa: 950,
            elevationM: 671,
            temperatureC: 15
        )
        #expect(p0 != nil)
        #expect(abs(p0! - 1028.0) < 1.5)
        #expect(p0! > 1025 && p0! < 1032)
    }

    @Test func airDensityNilWithoutTemperature() {
        let density = PressureMath.airDensity(
            stationHPa: 1013.25,
            temperatureC: nil,
            relativeHumidityPct: 50
        )
        #expect(density == nil)
    }

    @Test func seaLevelNilWithoutElevation() {
        let p0 = PressureMath.seaLevelPressure(
            stationHPa: 950,
            elevationM: nil,
            temperatureC: 15
        )
        #expect(p0 == nil)
    }

    @Test func moistAirLessDenseThanDry() {
        let dry = PressureMath.airDensity(stationHPa: 1013.25, temperatureC: 20, relativeHumidityPct: 0)!
        let moist = PressureMath.airDensity(stationHPa: 1013.25, temperatureC: 20, relativeHumidityPct: 100)!
        #expect(moist < dry)
    }

    @Test func defaultTemperatureUsedForSeaLevel() {
        let withDefault = PressureMath.seaLevelPressure(stationHPa: 950, elevationM: 671, temperatureC: nil)!
        let with15 = PressureMath.seaLevelPressure(stationHPa: 950, elevationM: 671, temperatureC: 15)!
        #expect(abs(withDefault - with15) < 0.0001)
    }
}
