import Foundation
import SwiftData

/// Groups pending splits by venue+hour and fills pressure from a weather provider.
/// Failures are silent; barometer-sourced splits are never overwritten.
@MainActor
final class PressureBackfillService {
    private let weather: any WeatherProviding
    private let catalog: VenueCatalog

    init(weather: any WeatherProviding = OpenMeteoWeatherProvider(), catalog: VenueCatalog = .shared) {
        self.weather = weather
        self.catalog = catalog
    }

    /// Find splits needing backfill and fill them. Returns number of splits updated.
    @discardableResult
    func backfill(modelContext: ModelContext, customVenues: [CustomVenue] = []) async -> Int {
        guard AppSettings.weatherAPIEnabled else { return 0 }

        let descriptor = FetchDescriptor<Split>()
        guard let allSplits = try? modelContext.fetch(descriptor) else { return 0 }

        let pending = allSplits.filter { split in
            split.pressureSource == .none
                && split.stationPressureHPa == nil
                && split.venueID != nil
        }
        guard !pending.isEmpty else { return 0 }

        let groups = Self.groupByVenueAndHour(pending)
        var updated = 0

        for (key, splits) in groups {
            guard let venue = catalog.resolve(id: key.venueID, custom: customVenues),
                  let lat = venue.latitude,
                  let lon = venue.longitude else {
                continue
            }

            let sample: WeatherSample?
            do {
                sample = try await weather.weather(latitude: lat, longitude: lon, at: key.hourStart)
            } catch {
                continue // silent failure; retry next time
            }
            guard let sample, let pressure = sample.stationPressureHPa else { continue }

            for split in splits {
                // Never overwrite barometer (or already-filled) data
                guard split.pressureSource == .none, split.stationPressureHPa == nil else { continue }
                split.stationPressureHPa = pressure
                split.pressureSource = .weatherAPI
                if let t = sample.temperatureC { split.temperatureC = t }
                if let rh = sample.relativeHumidityPct { split.relativeHumidityPct = rh }
                updated += 1
            }
        }

        if updated > 0 {
            try? modelContext.save()
        }
        return updated
    }

    struct VenueHourKey: Hashable, Sendable {
        let venueID: String
        let hourStart: Date
    }

    static func groupByVenueAndHour(_ splits: [Split]) -> [VenueHourKey: [Split]] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var result: [VenueHourKey: [Split]] = [:]
        for split in splits {
            guard let venueID = split.venueID else { continue }
            let comps = calendar.dateComponents([.year, .month, .day, .hour], from: split.capturedAt)
            guard let hourStart = calendar.date(from: comps) else { continue }
            let key = VenueHourKey(venueID: venueID, hourStart: hourStart)
            result[key, default: []].append(split)
        }
        return result
    }
}

/// In-memory mock weather provider for tests.
final class MockWeatherProvider: WeatherProviding, @unchecked Sendable {
    var samples: [WeatherSample] = []
    /// Optional keyed samples: "lat,lon,hourEpoch"
    var samplesByKey: [String: WeatherSample] = [:]
    var error: Error?
    private(set) var requestCount = 0
    private(set) var requestedDates: [Date] = []

    func weather(latitude: Double, longitude: Double, at date: Date) async throws -> WeatherSample? {
        requestCount += 1
        requestedDates.append(date)
        if let error { throw error }
        let key = Self.key(latitude: latitude, longitude: longitude, date: date)
        if let exact = samplesByKey[key] { return exact }
        return Self.nearest(in: samples, to: date) ?? samples.first
    }

    static func key(latitude: Double, longitude: Double, date: Date) -> String {
        let hour = Int(floor(date.timeIntervalSince1970 / 3600.0))
        return String(format: "%.4f,%.4f,%d", latitude, longitude, hour)
    }

    static func nearest(in samples: [WeatherSample], to date: Date) -> WeatherSample? {
        samples.min { abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date)) }
    }
}
