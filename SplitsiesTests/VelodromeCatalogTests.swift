import Foundation
import Testing
@testable import Splitsies

struct VelodromeCatalogTests {

    private func loadDataset() throws -> VelodromeDataset {
        let url = try #require(Bundle.main.url(forResource: "velodromes", withExtension: "json"))
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(VelodromeDataset.self, from: data)
    }

    @Test func datasetCountMatchesAndIdsUnique() throws {
        let dataset = try loadDataset()
        #expect(dataset.velodromes.count == dataset.count)
        #expect(dataset.count == 128)

        let ids = dataset.velodromes.map(\.id)
        #expect(Set(ids).count == ids.count)
    }

    @Test func demolishedExcludedFromPickerButResolvable() throws {
        let dataset = try loadDataset()
        let catalog = VenueCatalog(dataset: dataset)

        let demolished = dataset.velodromes.filter { $0.status == .demolished }
        #expect(!demolished.isEmpty)

        let picker = catalog.pickerVenues()
        let pickerIDs = Set(picker.map(\.id))
        for d in demolished {
            #expect(!pickerIDs.contains(d.id))
            let resolved = catalog.resolve(id: d.id)
            #expect(resolved != nil)
            #expect(resolved?.status == .demolished)
        }
    }

    @Test func uncertainAppearsInPicker() throws {
        let dataset = try loadDataset()
        let catalog = VenueCatalog(dataset: dataset)
        let uncertain = dataset.velodromes.filter { $0.status == .uncertain }
        #expect(!uncertain.isEmpty)
        let pickerIDs = Set(catalog.pickerVenues().map(\.id))
        for u in uncertain {
            #expect(pickerIDs.contains(u.id))
        }
    }

    @Test func searchByCityAndCountry() throws {
        let dataset = try loadDataset()
        let catalog = VenueCatalog(dataset: dataset)
        let edmonton = catalog.search("Edmonton")
        #expect(!edmonton.isEmpty)
        #expect(edmonton.allSatisfy { $0.city.localizedCaseInsensitiveContains("Edmonton") || $0.name.localizedCaseInsensitiveContains("Edmonton") })

        let canada = catalog.search("Canada")
        #expect(canada.count >= edmonton.count)
    }

    @Test func groupedByCountry() throws {
        let dataset = try loadDataset()
        let catalog = VenueCatalog(dataset: dataset)
        let groups = catalog.groupedByCountry()
        #expect(!groups.isEmpty)
        #expect(groups.map(\.country) == groups.map(\.country).sorted())
    }
}
