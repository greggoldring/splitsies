//
//  ContentView.swift
//  Splitsies
//
//  Created by Gregg Oldring on 2026-02-14.
//

import SwiftUI
import SwiftData

struct ContentView: View {
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
                CreditsView()
            }
            .tabItem {
                Label("Credits", systemImage: "info.circle")
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Item.self, Race.self, Split.self], inMemory: true)
}
