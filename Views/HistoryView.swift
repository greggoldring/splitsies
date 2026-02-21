import SwiftUI
import CoreData

struct HistoryView: View {
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \Race.createdAt, ascending: false)],
        animation: .default
    ) private var races: FetchedResults<Race>

    var body: some View {
        NavigationView {
            List {
                ForEach(races, id: \.objectID) { race in
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
            Text(race.name ?? "")
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
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
