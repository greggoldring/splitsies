//
//  SplitsiesApp.swift
//  Splitsies
//
//  Created by Gregg Oldring on 2026-02-14.
//

import SwiftUI
import SwiftData
import CoreText

@main
struct SplitsiesApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
            Race.self,
            Split.self
        ])
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        registerOrbitronFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }

    private func registerOrbitronFonts() {
        let subdirectories = ["Fonts", "Fonts/Orbitron", "Fonts/Orbitron/static", nil as String?]
        var fontURLs: [URL] = []

        for subdir in subdirectories {
            if let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: subdir) {
                fontURLs.append(contentsOf: urls)
            }
        }

        guard !fontURLs.isEmpty else { return }
        CTFontManagerRegisterFontURLs(fontURLs as CFArray, .process, true, nil)
    }
}
