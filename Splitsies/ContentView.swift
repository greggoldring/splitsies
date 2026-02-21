//
//  ContentView.swift
//  Splitsies
//
//  Created by Gregg Oldring on 2026-02-14.
//

import SwiftUI
import CoreData

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
        }
    }
}

#Preview {
    ContentView()
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
