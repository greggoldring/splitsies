import SwiftUI
import CoreData

struct RaceDetailView: View {
    let race: Race

    var body: some View {
        List {
            Section("Summary") {
                HStack {
                    Text("Total time")
                    Spacer()
                    Text(formatDuration(race.totalDuration))
                        .fontWeight(.medium)
                }
            }

            Section("Splits") {
                ForEach(race.splitsArray, id: \.lapNumber) { split in
                    HStack {
                        Text("Lap \(Int(split.lapNumber))")
                        Spacer()
                        Text(formatDuration(split.lapDuration))
                            .font(.system(.body, design: .monospaced))
                    }
                }
            }
        }
        .navigationTitle(race.name ?? "")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        let hundredths = Int((seconds.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%d:%02d.%02d", mins, secs, hundredths)
    }
}
