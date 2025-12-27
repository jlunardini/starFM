//
//  MainTabView.swift
//  starFM
//
//  Main tab bar containing the app's primary views.
//

import SwiftUI
import SwiftData

/// The main tab bar view shown after login.
struct MainTabView: View {

    var body: some View {
        TabView {
            // Recent tracks tab
            NavigationStack {
                RecentTracksView()
            }
            .tabItem {
                Label("Recent", systemImage: "clock")
            }

            // Stats tab
            StatsView()
            .tabItem {
                Label("Stats", systemImage: "chart.bar")
            }

            // Settings tab
            SettingsView()
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .modelContainer(for: [RatedTrack.self, RatedAlbum.self], inMemory: true)
}

