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

    private var timer: Timer?
    private let modelContext: ModelContext
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm"
        return f
    }()

    struct SplitData: Sendable {
        let lapNumber: Int
        let splitTime: TimeInterval
        let lapDuration: TimeInterval
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    var elapsedTime: TimeInterval {
        guard isRunning, let start = startTime else {
            return pausedElapsed
        }
        return pausedElapsed + Date().timeIntervalSince(start)
    }

    var mostRecentSplitDisplay: String {
        if let last = currentSplits.last {
            return formatTime(last.lapDuration)
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

    func start() {
        guard !isRunning else {
            lap()
            return
        }
        startTime = Date()
        isRunning = true
        displayTime = elapsedTime
        UIApplication.shared.isIdleTimerDisabled = true
        startTimer()
    }

    func lap() {
        guard isRunning else { return }
        let elapsed = elapsedTime
        let previousSplitTime = currentSplits.last?.splitTime ?? 0
        let lapDuration = elapsed - previousSplitTime
        currentSplits.append(SplitData(
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

        // Add final segment (from last lap to stop, or full duration if no laps) so it’s shown and saved
        let previousSplitTime = currentSplits.last?.splitTime ?? 0
        let finalLapDuration = totalDuration - previousSplitTime
        currentSplits.append(SplitData(
            lapNumber: currentSplits.count + 1,
            splitTime: totalDuration,
            lapDuration: finalLapDuration
        ))

        let name = Self.dateFormatter.string(from: Date())
        let race = Race(name: name, totalDuration: totalDuration, splits: [])
        modelContext.insert(race)

        for data in currentSplits {
            let split = Split(lapNumber: data.lapNumber, splitTime: data.splitTime, lapDuration: data.lapDuration, race: race)
            modelContext.insert(split)
        }

        do {
            try modelContext.save()
        } catch {
            print("Failed to save race: \(error)")
        }
    }

    private func reset() {
        stopTimer()
        isRunning = false
        UIApplication.shared.isIdleTimerDisabled = false
        startTime = nil
        pausedElapsed = 0
        currentSplits = []
        displayTime = 0
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self else { return }
                self.displayTime = self.elapsedTime
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
