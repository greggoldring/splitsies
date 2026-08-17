import Foundation

/// Open-Meteo's free tier is non-commercial; endpoint must be swappable before commercial launch.
struct WeatherAPIConfiguration: Sendable {
    var forecastBaseURL: URL
    var archiveBaseURL: URL

    static let openMeteo = WeatherAPIConfiguration(
        forecastBaseURL: URL(string: "https://api.open-meteo.com/v1/forecast")!,
        archiveBaseURL: URL(string: "https://archive-api.open-meteo.com/v1/archive")!
    )
}

struct WeatherSample: Sendable, Equatable {
    let timestamp: Date
    let stationPressureHPa: Double?
    let seaLevelPressureHPa: Double?
    let temperatureC: Double?
    let relativeHumidityPct: Double?
}

protocol WeatherProviding: Sendable {
    /// Fetch hourly weather near the given coordinates covering `date`.
    func weather(latitude: Double, longitude: Double, at date: Date) async throws -> WeatherSample?
}

enum WeatherProviderError: Error {
    case invalidResponse
    case decodingFailed
}
