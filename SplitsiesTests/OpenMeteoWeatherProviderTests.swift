import Foundation
import Testing
@testable import Splitsies

/// Guards what actually leaves the device. The published privacy policy in
/// `docs/index.html` states that weather requests carry the venue's coordinates
/// rounded to roughly 11 km, so these are the tests that keep that claim true.
struct OpenMeteoWeatherProviderTests {

    private let provider = OpenMeteoWeatherProvider()

    private func queryValue(_ name: String, in url: URL) -> String? {
        URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?
            .first { $0.name == name }?
            .value
    }

    @Test func forecastURLCoarsensCoordinates() throws {
        // Edmonton, at the 3-decimal precision the bundled dataset uses.
        let url = try provider.forecastURL(latitude: 53.557, longitude: -113.552)

        #expect(queryValue("latitude", in: url) == "53.6")
        #expect(queryValue("longitude", in: url) == "-113.6")
        #expect(url.absoluteString.hasPrefix("https://api.open-meteo.com/v1/forecast"))
    }

    @Test func archiveURLCoarsensCoordinates() throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000) // 2023-11-14 UTC
        let url = try provider.archiveURL(latitude: 53.557, longitude: -113.552, date: date)

        #expect(queryValue("latitude", in: url) == "53.6")
        #expect(queryValue("longitude", in: url) == "-113.6")
        #expect(queryValue("start_date", in: url) == "2023-11-14")
        #expect(url.absoluteString.hasPrefix("https://archive-api.open-meteo.com/v1/archive"))
    }

    /// The case that actually motivated the rounding: custom venues are typed by hand
    /// and used to be sent verbatim, at whatever precision the user entered.
    @Test func fullPrecisionCustomVenueCoordinateIsNotSentVerbatim() throws {
        let preciseLat = 53.5570123456
        let preciseLon = -113.5521987654

        let forecast = try provider.forecastURL(latitude: preciseLat, longitude: preciseLon)
        let archive = try provider.archiveURL(latitude: preciseLat, longitude: preciseLon, date: Date())

        for url in [forecast, archive] {
            let query = url.query ?? ""
            #expect(!query.contains("53.5570"))
            #expect(!query.contains("113.5521"))
            #expect(queryValue("latitude", in: url) == "53.6")
            #expect(queryValue("longitude", in: url) == "-113.6")
        }
    }

    @Test(arguments: [
        53.5570123456,
        -113.5521987654,
        0.0,
        -0.04,
        89.99999,
        -179.987654321,
        45.0,
        12.25
    ])
    func coarsenedCoordinateNeverExceedsOneDecimalPlace(_ degrees: Double) {
        let formatted = OpenMeteoWeatherProvider.coarsenedCoordinate(degrees)

        let fraction = formatted.split(separator: ".").dropFirst().first ?? ""
        #expect(fraction.count <= OpenMeteoWeatherProvider.coordinateDecimalPlaces)
        // Locale-independent: the separator must always be a dot, never a comma.
        #expect(!formatted.contains(","))
        #expect(Double(formatted) != nil)
    }

    @Test func coarsenedCoordinateRoundsToNearestTenth() {
        #expect(OpenMeteoWeatherProvider.coarsenedCoordinate(53.549) == "53.5")
        #expect(OpenMeteoWeatherProvider.coarsenedCoordinate(53.551) == "53.6")
        #expect(OpenMeteoWeatherProvider.coarsenedCoordinate(-113.552) == "-113.6")
        #expect(OpenMeteoWeatherProvider.coarsenedCoordinate(0.0) == "0.0")
    }
}
