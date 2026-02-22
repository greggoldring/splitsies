import Foundation

extension Race {
    var splitsArray: [Split] {
        splits.sorted { $0.lapNumber < $1.lapNumber }
    }
}
