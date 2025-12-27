//
//  starFMApp.swift
//  starFM
//
//  Created by Johncarlos Lunardini on 12/12/25.
//

import SwiftUI
import SwiftData

@main
struct starFMApp: App {

    /// The shared SwiftData container for the app.
    ///
    /// This configures:
    /// - Which models to persist (RatedTrack and RatedAlbum)
    /// - iCloud sync via CloudKit (requires iCloud capability in Xcode)
    var sharedModelContainer: ModelContainer = {
        // Define which models are part of our schema
        let schema = Schema([
            RatedTrack.self,
            RatedAlbum.self
        ])

        // Configure the container with iCloud sync enabled
        // .automatic = sync to user's iCloud if available, local-only if not
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .automatic  // Enables iCloud sync!
        )

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            // RootView handles auth routing - shows LoginView or RecentTracksView
            RootView()
        }
        // Inject the model container so all child views can access SwiftData
        .modelContainer(sharedModelContainer)
    }
}
