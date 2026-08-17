import Foundation
import SwiftUI
import SwiftData
import UIKit

@MainActor
@Observable
final class StopwatchViewModel {
    // Timer state
    var isRunning: Bool = false
    var startTime: Date?
    var pausedElapsed: TimeInterval = 0
    var currentSplits: [SplitData] = []

    // Display updates (triggered by timer)
    var displayTime: TimeInterval = 0

    /// Selected venue for the current (or next) session. Nil = no venue.
    var selectedVenue: VenueRef?
    var showVenuePicker: Bool = false
    var showConditionsDetail: Bool = false

    private var timer: Timer?
    private let modelContext: ModelContext
    private let barometer: any BarometerProviding
    private let backfill: PressureBackfillService
    private let catalog: VenueCatalog

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    struct SplitData: Sendable {
        let lapNumber: Int
        let splitTime: TimeInterval
        let lapDuration: TimeInterval
        let capturedAt: Date
        let stationPressureHPa: Double?
        let pressureSource: PressureSource
        let venueID: String?
        let temperatureC: Double?
        let relativeHumidityPct: Double?
    }

    init(
        modelContext: ModelContext,
        barometer: (any BarometerProviding)? = nil,
        backfill: PressureBackfillService? = nil,
        catalog: VenueCatalog = .shared
    ) {
        self.modelContext = modelContext
        self.barometer = barometer ?? BarometerService()
        self.backfill = backfill ?? PressureBackfillService()
        self.catalog = catalog
        restoreLastVenue()
    }

    private func restoreLastVenue() {
        guard let id = AppSettings.lastUsedVenueID else { return }
        let customs = (try? modelContext.fetch(FetchDescriptor<CustomVenue>())) ?? []
        selectedVenue = catalog.resolve(id: id, custom: customs)
    }

    var elapsedTime: TimeInterval {
        guard isRunning, let start = startTime else {
            return pausedElapsed
        }
        return pausedElapsed + Date().timeIntervalSince(start)
    }

    var mostRecentSplitDisplay: String {
        if isRunning {
            if let last = currentSplits.last {
                return formatTime(last.lapDuration)
            }
            return formatTime(elapsedTime)
        }
        return formatTime(elapsedTime)
    }

    var runningTimeDisplay: String {
        if isRunning {
            return formatTime(displayTime)
        }
        return formatTime(elapsedTime)
    }

    var startLapButtonTitle: String {
        isRunning ? "Lap" : "Start"
    }

    var stopResetButtonTitle: String {
        isRunning ? "Stop" : "Reset"
    }

    /// Conditions chip for the live session (from cache or last split).
    var livePressureHPa: Double? {
        if let last = currentSplits.last?.stationPressureHPa {
            return last
        }
        return barometer.latestStationPressureHPa
    }

    var livePressureSource: PressureSource {
        if let last = currentSplits.last {
            return last.pressureSource
        }
        if barometer.latestStationPressureHPa != nil {
            return .barometer
        }
        return .none
    }

    var isPressurePending: Bool {
        livePressureHPa == nil && selectedVenue?.hasCoordinates == true
    }

    func selectVenue(_ venue: VenueRef?) {
        selectedVenue = venue
        AppSettings.lastUsedVenueID = venue?.id
    }

    func start() {
        guard !isRunning else {
            lap()
            return
        }
        startTime = Date()
        isRunning = true
        displayTime = elapsedTime
        UIApplication.shared.isIdleTimerDisabled = true
        barometer.startUpdates()
        startTimer()
    }

    func lap() {
        guard isRunning else { return }
        let elapsed = elapsedTime
        let previousSplitTime = currentSplits.last?.splitTime ?? 0
        let lapDuration = elapsed - previousSplitTime
        currentSplits.append(makeSplitData(
            lapNumber: currentSplits.count + 1,
            splitTime: elapsed,
            lapDuration: lapDuration
        ))
    }

    func stopOrReset() {
        if isRunning {
            stop()
        } else {
            reset()
        }
    }

    private func stop() {
        stopTimer()
        let totalDuration = elapsedTime
        isRunning = false
        UIApplication.shared.isIdleTimerDisabled = false

        pausedElapsed = totalDuration
        displayTime = totalDuration

        // Add final segment (from last lap to stop, or full duration if no laps)
        let previousSplitTime = currentSplits.last?.splitTime ?? 0
        let finalLapDuration = totalDuration - previousSplitTime
        currentSplits.append(makeSplitData(
            lapNumber: currentSplits.count + 1,
            splitTime: totalDuration,
            lapDuration: finalLapDuration
        ))

        barometer.stopUpdates()

        let name = Self.dateFormatter.string(from: Date())
        let race = Race(name: name, totalDuration: totalDuration, splits: [], venue: selectedVenue)
        modelContext.insert(race)

        for data in currentSplits {
            let split = Split(
                lapNumber: data.lapNumber,
                splitTime: data.splitTime,
                lapDuration: data.lapDuration,
                race: race,
                stationPressureHPa: data.stationPressureHPa,
                pressureSource: data.pressureSource,
                capturedAt: data.capturedAt,
                venueID: data.venueID,
                temperatureC: data.temperatureC,
                relativeHumidityPct: data.relativeHumidityPct
            )
            modelContext.insert(split)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save race: \(error)")
        }

        Task {
            let customs = (try? modelContext.fetch(FetchDescriptor<CustomVenue>())) ?? []
            await backfill.backfill(modelContext: modelContext, customVenues: customs)
        }
    }

    private func reset() {
        stopTimer()
        barometer.stopUpdates()
        isRunning = false
        UIApplication.shared.isIdleTimerDisabled = false
        startTime = nil
        pausedElapsed = 0
        currentSplits = []
        displayTime = 0
    }

    private func makeSplitData(lapNumber: Int, splitTime: TimeInterval, lapDuration: TimeInterval) -> SplitData {
        let capturedAt = Date()
        let pressure = barometer.latestStationPressureHPa
        let source: PressureSource = pressure != nil ? .barometer : .none
        return SplitData(
            lapNumber: lapNumber,
            splitTime: splitTime,
            lapDuration: lapDuration,
            capturedAt: capturedAt,
            stationPressureHPa: pressure,
            pressureSource: source,
            venueID: selectedVenue?.id,
            temperatureC: nil,
            relativeHumidityPct: nil
        )
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            guard let self else { return }
            let viewModel = self
            Task { @MainActor in
                viewModel.displayTime = viewModel.elapsedTime
            }
        }
        timer?.tolerance = 0.05
        RunLoop.current.add(timer!, forMode: .common)
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let mins = (totalSeconds % 3600) / 60
        let secs = totalSeconds % 60
        let hundredths = Int((seconds.truncatingRemainder(dividingBy: 1)) * 100)

        if hours > 0 {
            return String(format: "%d:%02d:%02d.%02d", hours, mins, secs, hundredths)
        } else if mins > 0 {
            return String(format: "%d:%02d.%02d", mins, secs, hundredths)
        } else {
            return String(format: "%d.%02d", secs, hundredths)
        }
    }
}
