//
//  RootView.swift
//  starFM
//
//  Root view that handles authentication routing.
//  Shows LoginView if not authenticated, RecentTracksView if authenticated.
//

import SwiftUI

/// The app's root view - handles auth state routing.
///
/// Uses @AppStorage to persist auth state across app launches.
/// When user logs in, sessionKey gets set and this view automatically
/// switches to show RecentTracksView.
struct RootView: View {

    // MARK: - Persisted State

    /// The authenticated user's Last.fm username.
    /// Stored in UserDefaults via @AppStorage.
    @AppStorage("lastfm_username") private var username: String = ""

    /// The session key from Last.fm authentication.
    /// If empty, user is not logged in.
    /// Stored in UserDefaults via @AppStorage.
    ///
    // TODO: Move sessionKey storage to Keychain for better security.
    // UserDefaults is not encrypted. Use a library like KeychainAccess
    // or the Security framework directly.
    @AppStorage("lastfm_sessionKey") private var sessionKey: String = ""

    // MARK: - Body

    var body: some View {
        // Simple conditional: show login or main content based on auth state
        if sessionKey.isEmpty {
            // Not logged in - show login screen
            LoginView()
        } else {
            // Logged in - show main tab view
            MainTabView()
        }
    }
}

// MARK: - Preview

#Preview("Not Logged In") {
    RootView()
}

