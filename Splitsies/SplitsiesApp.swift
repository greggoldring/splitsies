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
        registerSpaceMonoFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(sharedModelContainer)
    }

    private func registerSpaceMonoFonts() {
        guard let urls = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts/SpaceMono"),
              !urls.isEmpty else {
            #if DEBUG
            assertionFailure("SpaceMono fonts not found in bundle at Fonts/SpaceMono")
            #endif
            print("Warning: SpaceMono fonts not found in bundle at Fonts/SpaceMono")
            return
        }
        var ctError: Unmanaged<CFError>?
        let success = CTFontManagerRegisterFontURLs(urls as CFArray, .process, true, &ctError)
        guard success else {
            let error = ctError?.takeRetainedValue()
            #if DEBUG
            if let error = error {
                assertionFailure("Failed to register SpaceMono fonts: \(error)")
            } else {
                assertionFailure("Failed to register SpaceMono fonts for an unknown reason.")
            }
            #endif
            if let error = error {
                print("Error: Failed to register SpaceMono fonts: \(error)")
            } else {
                print("Error: Failed to register SpaceMono fonts for an unknown reason.")
            }
            return
        }
    }
}
