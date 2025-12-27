//
//  SettingsView.swift
//  starFM
//
//  Settings screen - placeholder for future settings.
//

import SwiftUI

/// Settings view - currently a placeholder.
struct SettingsView: View {

    // MARK: - Auth State (for logout)

    @AppStorage("lastfm_username") private var username: String = ""
    @AppStorage("lastfm_sessionKey") private var sessionKey: String = ""

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Account section
                Section("Account") {
                    HStack {
                        Text("Logged in as")
                        Spacer()
                        Text(username)
                            .foregroundColor(.secondary)
                    }

                    Button("Log Out", role: .destructive) {
                        logout()
                    }
                }

                // Placeholder sections for future settings
                Section("Preferences") {
                    Text("Coming soon...")
                        .foregroundColor(.secondary)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Methods

    private func logout() {
        sessionKey = ""
        username = ""
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}

