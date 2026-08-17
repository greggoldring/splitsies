import Foundation
import SwiftData

@Model
final class Split {
    var lapNumber: Int
    var splitTime: TimeInterval
    var lapDuration: TimeInterval
    var race: Race?

    /// Station pressure in hectopascals. Source of truth; never overwritten once set from barometer.
    var stationPressureHPa: Double?
    /// Raw storage for `PressureSource`.
    var pressureSourceRaw: String = PressureSource.none.rawValue
    var capturedAt: Date = Date()
    var venueID: String?
    var temperatureC: Double?
    var relativeHumidityPct: Double?

    var pressureSource: PressureSource {
        get { PressureSource(rawValue: pressureSourceRaw) ?? .none }
        set { pressureSourceRaw = newValue.rawValue }
    }

    init(
        lapNumber: Int,
        splitTime: TimeInterval,
        lapDuration: TimeInterval,
        race: Race? = nil,
        stationPressureHPa: Double? = nil,
        pressureSource: PressureSource = .none,
        capturedAt: Date = Date(),
        venueID: String? = nil,
        temperatureC: Double? = nil,
        relativeHumidityPct: Double? = nil
    ) {
        self.lapNumber = lapNumber
        self.splitTime = splitTime
        self.lapDuration = lapDuration
        self.race = race
        self.stationPressureHPa = stationPressureHPa
        self.pressureSourceRaw = pressureSource.rawValue
        self.capturedAt = capturedAt
        self.venueID = venueID
        self.temperatureC = temperatureC
        self.relativeHumidityPct = relativeHumidityPct
    }
}
