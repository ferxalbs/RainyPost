//
//  RainyPostApp.swift
//  RainyPost
//
//  Created by Fer on 1/4/26.
//

import SwiftUI
import SwiftData

@main
struct RainyPostApp: App {
    @StateObject private var appState = AppState()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            HistoryEntry.self,
            RequestIndex.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainWindowView()
                .environmentObject(appState)
        }
        .modelContainer(sharedModelContainer)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
    }
}
