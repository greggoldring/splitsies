import Foundation

/// Production Open-Meteo client. Uses forecast for recent dates and archive for older ones.
struct OpenMeteoWeatherProvider: WeatherProviding {
    let configuration: WeatherAPIConfiguration
    let session: URLSession
    /// How far back (from "now") the forecast endpoint with past_days covers.
    let forecastLookbackDays: Int

    init(
        configuration: WeatherAPIConfiguration = .openMeteo,
        session: URLSession = .shared,
        forecastLookbackDays: Int = 2
    ) {
        self.configuration = configuration
        self.session = session
        self.forecastLookbackDays = forecastLookbackDays
    }

    func weather(latitude: Double, longitude: Double, at date: Date) async throws -> WeatherSample? {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let lookbackLimit = calendar.date(byAdding: .day, value: -forecastLookbackDays, to: now) ?? now
        let useArchive = date < lookbackLimit

        let url: URL
        if useArchive {
            url = try archiveURL(latitude: latitude, longitude: longitude, date: date)
        } else {
            url = try forecastURL(latitude: latitude, longitude: longitude)
        }

        let (data, response) = try await session.data(from: url)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw WeatherProviderError.invalidResponse
        }

        let decoded: OpenMeteoHourlyResponse
        do {
            decoded = try JSONDecoder().decode(OpenMeteoHourlyResponse.self, from: data)
        } catch {
            throw WeatherProviderError.decodingFailed
        }

        return Self.nearestSample(in: decoded, to: date)
    }

    // MARK: - Coordinate coarsening

    /// Decimal places of latitude/longitude sent to the weather API.
    /// One place is ~11 km — at or below the resolution of the models behind these
    /// endpoints, so pressure is effectively unchanged, and far coarser than any
    /// gradient this app cares about.
    ///
    /// This is the single point where coordinates leave the device, so rounding here
    /// makes the precision uniform no matter where the venue came from. That matters:
    /// bundled venues are capped at 3 decimals, but custom-venue coordinates are typed
    /// by the user and were previously sent verbatim at whatever precision they entered.
    /// The published privacy policy states this 1-place bound, so don't widen it without
    /// updating `docs/index.html` to match.
    static let coordinateDecimalPlaces = 1

    /// Format a coordinate for the query string, coarsened and locale-independent
    /// (`locale: nil` keeps the separator a `.` regardless of the user's region).
    nonisolated static func coarsenedCoordinate(_ degrees: Double) -> String {
        String(format: "%.\(coordinateDecimalPlaces)f", locale: nil, degrees)
    }

    // MARK: - URL builders

    func forecastURL(latitude: Double, longitude: Double) throws -> URL {
        var components = URLComponents(url: configuration.forecastBaseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: Self.coarsenedCoordinate(latitude)),
            URLQueryItem(name: "longitude", value: Self.coarsenedCoordinate(longitude)),
            URLQueryItem(name: "hourly", value: "surface_pressure,pressure_msl,temperature_2m,relative_humidity_2m"),
            URLQueryItem(name: "past_days", value: "\(forecastLookbackDays)"),
            URLQueryItem(name: "forecast_days", value: "1"),
            URLQueryItem(name: "timezone", value: "UTC")
        ]
        guard let url = components.url else { throw WeatherProviderError.invalidResponse }
        return url
    }

    func archiveURL(latitude: Double, longitude: Double, date: Date) throws -> URL {
        let formatter = Self.dayFormatter
        let day = formatter.string(from: date)
        var components = URLComponents(url: configuration.archiveBaseURL, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: Self.coarsenedCoordinate(latitude)),
            URLQueryItem(name: "longitude", value: Self.coarsenedCoordinate(longitude)),
            URLQueryItem(name: "hourly", value: "surface_pressure,pressure_msl,temperature_2m,relative_humidity_2m"),
            URLQueryItem(name: "start_date", value: day),
            URLQueryItem(name: "end_date", value: day),
            URLQueryItem(name: "timezone", value: "UTC")
        ]
        guard let url = components.url else { throw WeatherProviderError.invalidResponse }
        return url
    }

    // MARK: - Matching

    nonisolated static func nearestSample(in response: OpenMeteoHourlyResponse, to date: Date) -> WeatherSample? {
        let times = response.hourly.time
        guard !times.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        var bestIndex = 0
        var bestDelta = TimeInterval.greatestFiniteMagnitude

        for (index, raw) in times.enumerated() {
            guard let parsed = formatter.date(from: raw) else { continue }
            let delta = abs(parsed.timeIntervalSince(date))
            if delta < bestDelta {
                bestDelta = delta
                bestIndex = index
            }
        }

        guard let matchedTime = formatter.date(from: times[bestIndex]) else { return nil }
        let surface = response.hourly.surfacePressure.flatMap { $0[safe: bestIndex] ?? nil }
        let msl = response.hourly.pressureMSL.flatMap { $0[safe: bestIndex] ?? nil }
        let temp = response.hourly.temperature2m.flatMap { $0[safe: bestIndex] ?? nil }
        let rh = response.hourly.relativeHumidity2m.flatMap { $0[safe: bestIndex] ?? nil }

        // Prefer surface (station) pressure; fall back to MSL if surface missing.
        let station = surface ?? msl
        guard let station else { return nil }

        return WeatherSample(
            timestamp: matchedTime,
            stationPressureHPa: station,
            seaLevelPressureHPa: msl,
            temperatureC: temp,
            relativeHumidityPct: rh.map { Double($0) }
        )
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let isoFormatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(secondsFromGMT: 0)
        f.dateFormat = "yyyy-MM-dd'T'HH:mm"
        return f
    }()
}

struct OpenMeteoHourlyResponse: Codable, Sendable {
    let hourly: Hourly

    struct Hourly: Codable, Sendable {
        let time: [String]
        let surfacePressure: [Double?]?
        let pressureMSL: [Double?]?
        let temperature2m: [Double?]?
        let relativeHumidity2m: [Int?]?

        enum CodingKeys: String, CodingKey {
            case time
            case surfacePressure = "surface_pressure"
            case pressureMSL = "pressure_msl"
            case temperature2m = "temperature_2m"
            case relativeHumidity2m = "relative_humidity_2m"
        }
    }
}

private extension Array {
    nonisolated subscript(safe index: Int) -> Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}
