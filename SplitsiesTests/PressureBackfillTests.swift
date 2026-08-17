import Foundation
import Testing
import SwiftData
@testable import Splitsies

@MainActor
struct PressureBackfillTests {

    private func makeContainer() throws -> ModelContainer {
        try ModelContainer(
            for: Race.self, Split.self, CustomVenue.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func nearestHourMatching() async {
        let hourly = OpenMeteoHourlyResponse.Hourly(
            time: [
                "2023-11-14T21:00",
                "2023-11-14T22:00",
                "2023-11-14T23:00"
            ],
            surfacePressure: [1000, 1010, 1020],
            pressureMSL: [1015, 1025, 1035],
            temperature2m: [10, 11, 12],
            relativeHumidity2m: [40, 50, 60]
        )
        let response = OpenMeteoHourlyResponse(hourly: hourly)

        // Target closest to 22:00 UTC
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = cal.date(from: DateComponents(year: 2023, month: 11, day: 14, hour: 22, minute: 10))!
        let sample = OpenMeteoWeatherProvider.nearestSample(in: response, to: date)
        #expect(sample != nil)
        #expect(sample?.stationPressureHPa == 1010)
        #expect(sample?.temperatureC == 11)
        #expect(sample?.relativeHumidityPct == 50)
    }

    @Test func groupsOneRequestPerVenueHour() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)

        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(secondsFromGMT: 0)!
        let hourA = cal.date(from: DateComponents(year: 2024, month: 6, day: 1, hour: 10))!
        let hourALater = hourA.addingTimeInterval(15 * 60)
        let hourB = cal.date(from: DateComponents(year: 2024, month: 6, day: 1, hour: 11))!

        let venueID = "ca-coronation-park-sports-and-recreation-centre-vel"
        let race = Race(
            name: "Test",
            totalDuration: 100,
            venue: VenueRef(
                id: venueID,
                name: "Test Track",
                city: "Edmonton",
                region: "Alberta",
                country: "Canada",
                countryCode: "CA",
                latitude: 53.557,
                longitude: -113.552,
                elevationM: 671,
                indoor: true,
                status: .active,
                isCustom: false
            )
        )
        context.insert(race)

        for (i, date) in [hourA, hourALater, hourB].enumerated() {
            let split = Split(
                lapNumber: i + 1,
                splitTime: Double(i + 1),
                lapDuration: 1,
                race: race,
                stationPressureHPa: nil,
                pressureSource: .none,
                capturedAt: date,
                venueID: venueID
            )
            context.insert(split)
        }
        try context.save()

        let groups = PressureBackfillService.groupByVenueAndHour(Array(race.splits))
        #expect(groups.count == 2) // two hours, same venue

        let mock = MockWeatherProvider()
        mock.samples = [
            WeatherSample(timestamp: hourA, stationPressureHPa: 950, seaLevelPressureHPa: 1030, temperatureC: 15, relativeHumidityPct: 40),
            WeatherSample(timestamp: hourB, stationPressureHPa: 951, seaLevelPressureHPa: 1031, temperatureC: 16, relativeHumidityPct: 41)
        ]

        // Load real catalog so venue resolves
        let catalog: VenueCatalog
        if let url = Bundle.main.url(forResource: "velodromes", withExtension: "json"),
           let data = try? Data(contentsOf: url),
           let dataset = try? JSONDecoder().decode(VelodromeDataset.self, from: data) {
            catalog = VenueCatalog(dataset: dataset)
        } else {
            // Fallback minimal catalog for the test venue
            let dataset = VelodromeDataset(
                dataset: "test",
                version: "0",
                count: 1,
                velodromes: [
                    BundledVelodrome(
                        id: venueID,
                        name: "Coronation",
                        city: "Edmonton",
                        region: "Alberta",
                        country: "Canada",
                        countryCode: "CA",
                        latitude: 53.557,
                        longitude: -113.552,
                        elevationM: 671,
                        elevationSource: "estimate",
                        indoor: true,
                        trackLengthM: 250,
                        surface: "wood",
                        status: .active,
                        notes: nil
                    )
                ]
            )
            catalog = VenueCatalog(dataset: dataset)
        }

        AppSettings.weatherAPIEnabled = true
        let service = PressureBackfillService(weather: mock, catalog: catalog)
        let updated = await service.backfill(modelContext: context)
        #expect(mock.requestCount == 2)
        #expect(updated == 3)
        #expect(race.splits.allSatisfy { $0.pressureSource == .weatherAPI })
        #expect(race.splits.allSatisfy { $0.stationPressureHPa != nil })
    }

    @Test func silentFailureLeavesPending() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let venueID = "test-venue"
        let race = Race(
            name: "Fail",
            totalDuration: 10,
            venue: VenueRef(
                id: venueID,
                name: "X",
                city: "Y",
                region: nil,
                country: "Z",
                countryCode: nil,
                latitude: 1,
                longitude: 2,
                elevationM: 100,
                indoor: false,
                status: .active,
                isCustom: true
            )
        )
        context.insert(race)
        let split = Split(
            lapNumber: 1,
            splitTime: 1,
            lapDuration: 1,
            race: race,
            pressureSource: .none,
            capturedAt: Date(),
            venueID: venueID
        )
        context.insert(split)
        try context.save()

        let mock = MockWeatherProvider()
        mock.error = WeatherProviderError.invalidResponse

        let catalog = VenueCatalog(dataset: VelodromeDataset(
            dataset: "t", version: "0", count: 0, velodromes: []
        ))
        // resolve via custom venues
        let custom = CustomVenue(id: venueID, name: "X", latitude: 1, longitude: 2, elevationM: 100)
        context.insert(custom)

        AppSettings.weatherAPIEnabled = true
        let service = PressureBackfillService(weather: mock, catalog: catalog)
        let updated = await service.backfill(modelContext: context, customVenues: [custom])
        #expect(updated == 0)
        #expect(split.pressureSource == .none)
        #expect(split.stationPressureHPa == nil)
    }

    @Test func neverOverwritesBarometer() async throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let venueID = "baro-venue"
        let race = Race(
            name: "Baro",
            totalDuration: 10,
            venue: VenueRef(
                id: venueID,
                name: "B",
                city: "C",
                region: nil,
                country: "D",
                countryCode: nil,
                latitude: 10,
                longitude: 20,
                elevationM: 50,
                indoor: true,
                status: .active,
                isCustom: true
            )
        )
        context.insert(race)
        let split = Split(
            lapNumber: 1,
            splitTime: 1,
            lapDuration: 1,
            race: race,
            stationPressureHPa: 999.0,
            pressureSource: .barometer,
            capturedAt: Date(),
            venueID: venueID
        )
        context.insert(split)
        try context.save()

        let mock = MockWeatherProvider()
        mock.samples = [
            WeatherSample(timestamp: Date(), stationPressureHPa: 1111, seaLevelPressureHPa: 1111, temperatureC: 20, relativeHumidityPct: 30)
        ]
        let custom = CustomVenue(id: venueID, name: "B", latitude: 10, longitude: 20)
        let catalog = VenueCatalog(dataset: VelodromeDataset(dataset: "t", version: "0", count: 0, velodromes: []))

        AppSettings.weatherAPIEnabled = true
        let service = PressureBackfillService(weather: mock, catalog: catalog)
        let updated = await service.backfill(modelContext: context, customVenues: [custom])
        #expect(updated == 0)
        #expect(mock.requestCount == 0) // filtered out before fetch (not pending)
        #expect(split.stationPressureHPa == 999.0)
        #expect(split.pressureSource == .barometer)
    }
}
