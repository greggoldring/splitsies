//
//  SplitsiesApp.swift
//  Splitsies
//
//  Created by Gregg Oldring on 2026-02-14.
//

import SwiftUI
import CoreData
import CoreText

@main
struct SplitsiesApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        registerOrbitronFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
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
