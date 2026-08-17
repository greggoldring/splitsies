import Foundation
import CoreMotion

protocol BarometerProviding: AnyObject {
    var isAvailable: Bool { get }
    /// Latest station pressure in hPa, if any reading has arrived.
    var latestStationPressureHPa: Double? { get }
    func startUpdates()
    func stopUpdates()
}

/// Caches CMAltimeter pressure readings for stamp-at-split. Never blocks.
final class BarometerService: NSObject, BarometerProviding, @unchecked Sendable {
    private let altimeter = CMAltimeter()
    private let queue = OperationQueue()
    private let lock = NSLock()
    private var cachedPressureHPa: Double?
    private var isRunning = false

    override init() {
        super.init()
        queue.name = "com.greggoldring.Splitsies.barometer"
        queue.maxConcurrentOperationCount = 1
    }

    var isAvailable: Bool {
        CMAltimeter.isRelativeAltitudeAvailable()
    }

    var latestStationPressureHPa: Double? {
        lock.lock(); defer { lock.unlock() }
        return cachedPressureHPa
    }

    func startUpdates() {
        lock.lock()
        let alreadyRunning = isRunning
        let available = CMAltimeter.isRelativeAltitudeAvailable()
        if available && !alreadyRunning {
            isRunning = true
        }
        lock.unlock()

        guard available, !alreadyRunning else { return }

        altimeter.startRelativeAltitudeUpdates(to: queue) { [weak self] data, _ in
            guard let self, let data else { return }
            // CMAltitudeData.pressure is in kPa → store hPa
            let hPa = data.pressure.doubleValue * 10.0
            self.lock.lock()
            self.cachedPressureHPa = hPa
            self.lock.unlock()
        }
    }

    func stopUpdates() {
        lock.lock()
        let wasRunning = isRunning
        isRunning = false
        lock.unlock()
        guard wasRunning else { return }
        altimeter.stopRelativeAltitudeUpdates()
    }
}

/// Deterministic mock for tests.
final class MockBarometerService: BarometerProviding, @unchecked Sendable {
    var isAvailable: Bool
    var latestStationPressureHPa: Double?
    private(set) var startCount = 0
    private(set) var stopCount = 0

    init(isAvailable: Bool = true, pressureHPa: Double? = nil) {
        self.isAvailable = isAvailable
        self.latestStationPressureHPa = pressureHPa
    }

    func startUpdates() {
        startCount += 1
    }

    func stopUpdates() {
        stopCount += 1
    }
}
