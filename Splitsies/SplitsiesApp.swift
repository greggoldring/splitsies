//
//  SplitsiesApp.swift
//  Splitsies
//
//  Created by Gregg Oldring on 2026-02-14.
//

import SwiftUI
import SwiftData

@main
struct SplitsiesApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Race.self,
            Split.self,
            CustomVenue.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            // Lightweight recovery when the on-disk store predates new pressure/venue fields.
            let storeURL = modelConfiguration.url
            try? FileManager.default.removeItem(at: storeURL)
            let related = [
                storeURL.appendingPathExtension("wal"),
                storeURL.appendingPathExtension("shm"),
                URL(fileURLWithPath: storeURL.path + "-wal"),
                URL(fileURLWithPath: storeURL.path + "-shm")
            ]
            for url in related {
                try? FileManager.default.removeItem(at: url)
            }
            do {
                return try ModelContainer(for: schema, configurations: [modelConfiguration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }
}
