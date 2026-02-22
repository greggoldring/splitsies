import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \Race.createdAt, order: .reverse) private var races: [Race]

    var body: some View {
        NavigationStack {
            List {
                ForEach(races, id: \.id) { race in
                    NavigationLink {
                        RaceDetailView(race: race)
                    } label: {
                        RaceRow(race: race)
                    }
                }
            }
            .navigationTitle("Race History")
        }
    }
}

private struct RaceRow: View {
    let race: Race

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(race.name)
                .font(.headline)
            HStack(spacing: 16) {
                Text(formatDuration(race.totalDuration))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("\(race.splitsArray.count) splits")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let mins = totalSeconds / 60
        let secs = totalSeconds % 60
        let hundredths = Int((seconds.truncatingRemainder(dividingBy: 1)) * 100)
        return String(format: "%d:%02d.%02d", mins, secs, hundredths)
    }
}

#Preview {
    HistoryView()
        .modelContainer(for: [Item.self, Race.self, Split.self], inMemory: true)
}
