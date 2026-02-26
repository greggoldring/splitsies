import SwiftUI
import SwiftData
import UIKit

private let csvDateFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "yyyy-MM-dd HH:mm"
    return f
}()

private func csvFormatDuration(_ seconds: TimeInterval) -> String {
    let totalSeconds = Int(seconds)
    let mins = totalSeconds / 60
    let secs = totalSeconds % 60
    let hundredths = Int((seconds.truncatingRemainder(dividingBy: 1)) * 100)
    return String(format: "%d:%02d.%02d", mins, secs, hundredths)
}

private func csvEscape(_ field: String) -> String {
    if field.contains(",") || field.contains("\"") || field.contains("\n") {
        return "\"" + field.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }
    return field
}

private func generateCSV(from races: [Race]) -> String {
    let header = "Race Name,Date,Total Duration,Lap,Lap Duration,Split Time"
    var rows: [String] = []
    for race in races {
        let name = csvEscape(race.name)
        let date = csvEscape(csvDateFormatter.string(from: race.createdAt))
        let total = csvEscape(csvFormatDuration(race.totalDuration))
        let splits = race.splitsArray
        if splits.isEmpty {
            rows.append([name, date, total, "—", total, total].joined(separator: ","))
        } else {
            for split in splits {
                let lap = "\(split.lapNumber)"
                let lapDuration = csvEscape(csvFormatDuration(split.lapDuration))
                let splitTime = csvEscape(csvFormatDuration(split.splitTime))
                rows.append([name, date, total, lap, lapDuration, splitTime].joined(separator: ","))
            }
        }
    }
    return ([header] + rows).joined(separator: "\n")
}

private struct ExportItem: Identifiable {
    let id = UUID()
    let url: URL
}

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Race.createdAt, order: .reverse) private var races: [Race]
    @State private var exportItem: ExportItem?
    @State private var showEmptyExportAlert = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(races, id: \.id) { race in
                    NavigationLink {
                        RaceDetailView(race: race)
                    } label: {
                        RaceRow(race: race)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            modelContext.delete(race)
                            try? modelContext.save()
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .navigationTitle("Race History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if races.isEmpty {
                            showEmptyExportAlert = true
                        } else {
                            performExport()
                        }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
            .sheet(item: $exportItem, onDismiss: {
                if let item = exportItem {
                    try? FileManager.default.removeItem(at: item.url)
                }
                exportItem = nil
            }) { item in
                ShareSheet(activityItems: [item.url])
            }
            .alert("No history to export", isPresented: $showEmptyExportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Add some races from the Stopwatch tab first.")
            }
        }
    }

    private func performExport() {
        let csv = generateCSV(from: races)
        let dateString: String = {
            let f = DateFormatter()
            f.dateFormat = "yyyy-MM-dd_HH-mm"
            return f.string(from: Date())
        }()
        let fileName = "Splitsies_Export_\(dateString).csv"
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(fileName)
        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            exportItem = ExportItem(url: fileURL)
        } catch {
            print("Export failed: \(error)")
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

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    HistoryView()
        .modelContainer(for: [Item.self, Race.self, Split.self], inMemory: true)
}
