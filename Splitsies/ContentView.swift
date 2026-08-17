//
//  ContentView.swift
//  Splitsies
//
//  Created by Gregg Oldring on 2026-02-14.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.scenePhase) private var scenePhase
    @Query private var customVenues: [CustomVenue]

    var body: some View {
        TabView {
            MainStopwatchView()
                .tabItem {
                    Label("Stopwatch", systemImage: "stopwatch")
                }
            HistoryView()
                .tabItem {
                    Label("History", systemImage: "list.bullet")
                }
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Settings", systemImage: "gearshape")
            }
            NavigationStack {
                CreditsView()
            }
            .tabItem {
                Label("Credits", systemImage: "info.circle")
            }
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task {
                let service = PressureBackfillService()
                await service.backfill(modelContext: modelContext, customVenues: Array(customVenues))
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, Race.self, Split.self, CustomVenue.self], inMemory: true)
}
