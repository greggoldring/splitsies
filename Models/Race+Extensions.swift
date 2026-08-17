import Foundation

extension Race {
    var splitsArray: [Split] {
        splits.sorted { $0.lapNumber < $1.lapNumber }
    }

    var venueDisplayName: String {
        venueName ?? "No venue"
    }

    var hasVenueCoordinates: Bool {
        venueLatitude != nil && venueLongitude != nil
    }

    /// Latest non-nil pressure reading among splits, preferring the most recent lap.
    var latestConditionsSplit: Split? {
        splitsArray.reversed().first { $0.stationPressureHPa != nil }
            ?? splitsArray.last
    }
}
