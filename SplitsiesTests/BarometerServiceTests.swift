import Foundation
import Testing
import SwiftData
@testable import Splitsies

struct BarometerServiceTests {

    @Test func cacheAndStampFlow() {
        let mock = MockBarometerService(isAvailable: true, pressureHPa: 1012.5)
        mock.startUpdates()
        #expect(mock.startCount == 1)
        #expect(mock.latestStationPressureHPa == 1012.5)

        // Stamp from cache — no per-split request
        let stamped = mock.latestStationPressureHPa
        #expect(stamped == 1012.5)
        #expect(mock.startCount == 1)

        mock.stopUpdates()
        #expect(mock.stopCount == 1)
    }

    @Test func unavailableSensorPath() {
        let mock = MockBarometerService(isAvailable: false, pressureHPa: nil)
        #expect(mock.isAvailable == false)
        mock.startUpdates()
        #expect(mock.latestStationPressureHPa == nil)
    }

    @Test @MainActor func stopwatchStampsFromBarometerCache() throws {
        let container = try ModelContainer(
            for: Race.self, Split.self, CustomVenue.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let barometer = MockBarometerService(isAvailable: true, pressureHPa: 1005.0)
        let vm = StopwatchViewModel(modelContext: context, barometer: barometer)

        vm.start()
        #expect(barometer.startCount == 1)
        vm.lap()
        #expect(vm.currentSplits.count == 1)
        #expect(vm.currentSplits[0].stationPressureHPa == 1005.0)
        #expect(vm.currentSplits[0].pressureSource == .barometer)

        // Update cache mid-session; next lap picks it up
        barometer.latestStationPressureHPa = 1006.2
        vm.lap()
        #expect(vm.currentSplits[1].stationPressureHPa == 1006.2)

        vm.stopOrReset()
        #expect(barometer.stopCount == 1)
    }

    @Test @MainActor func stopwatchSavesLatestBarometerPressureForUnstampedLaps() throws {
        let container = try ModelContainer(
            for: Race.self, Split.self, CustomVenue.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let barometer = MockBarometerService(isAvailable: true, pressureHPa: nil)
        let vm = StopwatchViewModel(modelContext: context, barometer: barometer)

        vm.start()
        vm.lap()
        #expect(vm.currentSplits[0].stationPressureHPa == nil)

        barometer.latestStationPressureHPa = 1008.4
        vm.stopOrReset()

        let races = try context.fetch(FetchDescriptor<Race>())
        #expect(races.count == 1)
        let savedSplits = races[0].splitsArray
        #expect(savedSplits.count == 2)
        #expect(savedSplits.allSatisfy { $0.stationPressureHPa == 1008.4 })
        #expect(savedSplits.allSatisfy { $0.pressureSource == .barometer })
    }

    @Test @MainActor func stopwatchWorksWithoutBarometer() throws {
        let container = try ModelContainer(
            for: Race.self, Split.self, CustomVenue.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        let barometer = MockBarometerService(isAvailable: false, pressureHPa: nil)
        let vm = StopwatchViewModel(modelContext: context, barometer: barometer)

        vm.start()
        vm.lap()
        #expect(vm.currentSplits[0].stationPressureHPa == nil)
        #expect(vm.currentSplits[0].pressureSource == .none)
        vm.stopOrReset()
    }
}
