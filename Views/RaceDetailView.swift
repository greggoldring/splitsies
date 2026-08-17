import SwiftUI
import SwiftData

struct RaceDetailView: View {
    @Bindable var race: Race
    @Environment(\.modelContext) private var modelContext
    @AppStorage("settings.pressureUnit") private var pressureUnitRaw: String = PressureUnit.hPa.rawValue

    private var unit: PressureUnit {
        PressureUnit(rawValue: pressureUnitRaw) ?? .hPa
    }

    var body: some View {
        List {
            Section("Name") {
                TextField("Race name", text: $race.name)
                    .onSubmit { try? modelContext.save() }
            }

            Section("Summary") {
                HStack {
                    Text("Total time")
                    Spacer()
                    Text(formatDuration(race.totalDuration))
                        .fontWeight(.medium)
                }
                HStack {
                    Text("Venue")
                    Spacer()
                    Text(race.venueDisplayName)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.trailing)
                }
            }

            Section("Splits") {
                ForEach(race.splitsArray, id: \.lapNumber) { split in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Lap \(split.lapNumber)")
                            Spacer()
                            Text(formatDuration(split.lapDuration))
                                .font(.system(.body, design: .monospaced))
                        }
                        SplitPressureLabel(
                            split: split,
                            elevationM: race.venueElevationM,
                            unit: unit,
                            canBackfill: race.hasVenueCoordinates
                        )
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle(race.name)
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

struct SplitPressureLabel: View {
    let split: Split
    let elevationM: Double?
    let unit: PressureUnit
    var canBackfill: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            if let hPa = split.stationPressureHPa {
                Text(unit.format(hPa))
                if let density = split.airDensityKgM3 {
                    Text("·")
                    Text(PressureFormatting.density(density))
                }
                Text("·")
                Text(PressureFormatting.sourceLabel(split.pressureSource))
                    .foregroundStyle(.tertiary)
            } else if canBackfill && split.pressureSource == .none {
                Text("pressure pending")
                    .foregroundStyle(.orange)
            } else {
                Text("no pressure")
                    .foregroundStyle(.tertiary)
            }
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}
