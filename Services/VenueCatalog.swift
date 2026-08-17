import Foundation

/// Loads and queries the bundled `velodromes.json` plus custom venues.
final class VenueCatalog: @unchecked Sendable {
    static let shared = VenueCatalog()

    private let bundled: [BundledVelodrome]
    private let byID: [String: BundledVelodrome]

    let datasetVersion: String
    let datasetCount: Int

    init(bundle: Bundle = .main) {
        if let url = Self.locateVelodromesJSON(in: bundle),
           let data = try? Data(contentsOf: url),
           let decoded = try? JSONDecoder().decode(VelodromeDataset.self, from: data) {
            bundled = decoded.velodromes
            byID = Dictionary(uniqueKeysWithValues: decoded.velodromes.map { ($0.id, $0) })
            datasetVersion = decoded.version
            datasetCount = decoded.count
        } else {
            bundled = []
            byID = [:]
            datasetVersion = "missing"
            datasetCount = 0
        }
    }

    /// Test/helper initializer from raw data.
    init(dataset: VelodromeDataset) {
        bundled = dataset.velodromes
        byID = Dictionary(uniqueKeysWithValues: dataset.velodromes.map { ($0.id, $0) })
        datasetVersion = dataset.version
        datasetCount = dataset.count
    }

    private static func locateVelodromesJSON(in bundle: Bundle) -> URL? {
        if let url = bundle.url(forResource: "velodromes", withExtension: "json") {
            return url
        }
        if let url = bundle.url(forResource: "velodromes", withExtension: "json", subdirectory: "Resources") {
            return url
        }
        return nil
    }

    var allBundled: [BundledVelodrome] { bundled }

    /// Venues eligible for new-session picker (excludes demolished).
    func pickerVenues(custom: [CustomVenue] = []) -> [VenueRef] {
        let bundledRefs = bundled
            .filter { $0.status != .demolished }
            .map(VenueRef.from)
        let customRefs = custom.map(VenueRef.from)
        return (bundledRefs + customRefs).sorted {
            if $0.country != $1.country { return $0.country < $1.country }
            return $0.name < $1.name
        }
    }

    func resolve(id: String, custom: [CustomVenue] = []) -> VenueRef? {
        if let bundled = byID[id] {
            return VenueRef.from(bundled)
        }
        if let custom = custom.first(where: { $0.id == id }) {
            return VenueRef.from(custom)
        }
        return nil
    }

    func search(_ query: String, custom: [CustomVenue] = []) -> [VenueRef] {
        let base = pickerVenues(custom: custom)
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return base }
        let tokens = trimmed.lowercased().split(separator: " ").map(String.init)
        return base.filter { venue in
            let haystack = [venue.name, venue.city, venue.country, venue.region ?? ""]
                .joined(separator: " ")
                .lowercased()
            return tokens.allSatisfy { haystack.contains($0) }
        }
    }

    func groupedByCountry(custom: [CustomVenue] = [], query: String = "") -> [(country: String, venues: [VenueRef])] {
        let venues = search(query, custom: custom)
        let grouped = Dictionary(grouping: venues, by: \.country)
        return grouped.keys.sorted().map { country in
            (country, (grouped[country] ?? []).sorted { $0.name < $1.name })
        }
    }
}
