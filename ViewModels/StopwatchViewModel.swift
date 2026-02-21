import Foundation
import SwiftUI
import CoreData
import Combine
import UIKit

@MainActor
final class StopwatchViewModel: ObservableObject {
    // Timer state
    @Published var isRunning: Bool = false
    @Published var startTime: Date?
    @Published var pausedElapsed: TimeInterval = 0
    @Published var currentSplits: [SplitData] = []

    // Display updates (triggered by timer)
    @Published var displayTime: TimeInterval = 0

    private var timer: Timer?
    private let raceRepository: RaceRepository
    private let context: NSManagedObjectContext
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

    init(context: NSManagedObjectContext) {
        self.context = context
        self.raceRepository = RaceRepository(context: context)
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

        let name = Self.dateFormatter.string(from: Date())
        let race = Race(context: context, name: name, totalDuration: totalDuration, splits: [])

        for data in currentSplits {
            let split = Split(context: context, lapNumber: data.lapNumber, splitTime: data.splitTime, lapDuration: data.lapDuration, race: race)
            race.addToSplits(split)
        }

        do {
            try context.save()
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
                self?.displayTime = self?.elapsedTime ?? 0
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
