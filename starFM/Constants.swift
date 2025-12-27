//
//  Constants.swift
//  starFM
//
//  App-wide constants for Last.fm API configuration.
//  API keys are loaded from Info.plist, which gets them from Secrets.xcconfig.
//

import Foundation

/// Central place for API keys and configuration.
///
/// ## How the secrets flow works:
/// 1. You put your actual keys in `Secrets.xcconfig` (gitignored)
/// 2. Xcode reads the xcconfig and injects values during build
/// 3. The values end up in Info.plist via $(VARIABLE_NAME) syntax
/// 4. At runtime, we read them from Bundle.main.infoDictionary
///
/// This keeps your keys out of source control while still being accessible in code.
enum Constants {

    // MARK: - Last.fm API Credentials

    /// Your Last.fm API key (loaded from Secrets.xcconfig → Info.plist)
    /// Returns empty string if not configured (will cause API errors)
    static var lastFMAPIKey: String {
        // Bundle.main.infoDictionary is a dictionary of everything in Info.plist
        // We look up our custom key and cast it to String
        guard let key = Bundle.main.infoDictionary?["LASTFM_API_KEY"] as? String,
              !key.isEmpty,
              key != "$(LASTFM_API_KEY)" else {  // Catches unconfigured xcconfig
            print("⚠️ Warning: LASTFM_API_KEY not configured in Secrets.xcconfig")
            return ""
        }
        return key
    }

    /// Your Last.fm shared secret (loaded from Secrets.xcconfig → Info.plist)
    /// Used for signing authenticated API requests
    static var lastFMSharedSecret: String {
        guard let secret = Bundle.main.infoDictionary?["LASTFM_SHARED_SECRET"] as? String,
              !secret.isEmpty,
              secret != "$(LASTFM_SHARED_SECRET)" else {
            print("⚠️ Warning: LASTFM_SHARED_SECRET not configured in Secrets.xcconfig")
            return ""
        }
        return secret
    }

    // MARK: - API Configuration

    /// Base URL for all Last.fm API requests
    static let lastFMBaseURL = "https://ws.audioscrobbler.com/2.0/"
}
