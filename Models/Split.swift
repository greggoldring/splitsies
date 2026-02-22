import Foundation
import SwiftData

@Model
final class Split {
    var lapNumber: Int
    var splitTime: TimeInterval
    var lapDuration: TimeInterval
    var race: Race?

    init(lapNumber: Int, splitTime: TimeInterval, lapDuration: TimeInterval, race: Race? = nil) {
        self.lapNumber = lapNumber
        self.splitTime = splitTime
        self.lapDuration = lapDuration
        self.race = race
    }
}
