//
//  RatedTrack.swift
//  starFM
//
//  SwiftData model for storing user's star ratings for tracks.
//  All properties are optional to support iCloud sync (CloudKit requirement).
//

import Foundation
import SwiftData

/// A track that the user has rated with stars.
///
/// This is the only model we persist - everything else (album info, play counts)
/// is fetched live from the Last.fm API.
///
/// ## iCloud Sync Requirements:
/// - All properties MUST be optional (CloudKit limitation)
/// - No unique constraints allowed
/// - No default values in property declarations (set in init or after creation)
@Model
final class RatedTrack {

    // MARK: - Identification

    /// Unique identifier combining artist, album, and track names.
    /// Format: "artistname-albumname-trackname" (lowercased, trimmed)
    /// Used to match ratings back to tracks from the Last.fm API.
    var trackID: String?

    /// The name of the track (e.g., "Bohemian Rhapsody")
    var trackName: String?

    /// The artist who performed the track (e.g., "Queen")
    var artistName: String?

    /// The album the track appears on (e.g., "A Night at the Opera")
    var albumName: String?

    // MARK: - Rating

    /// User's star rating: 1-5, or nil if not yet rated.
    /// We don't store 0 - if a user wants to "unrate", we delete the record.
    var rating: Int?

    // MARK: - Timestamps

    /// When this rating was first created
    var createdAt: Date?

    /// When this rating was last modified
    var updatedAt: Date?

    // MARK: - Initialization

    /// Empty initializer required by SwiftData.
    /// Properties are set after creation.
    init() {}

    // MARK: - Helper Methods

    /// Generates a consistent, normalized track ID from artist/album/track names.
    ///
    /// This ensures we can match a rating to any track from the API, even if
    /// capitalization or whitespace differs slightly.
    ///
    /// - Parameters:
    ///   - artist: The artist name from Last.fm
    ///   - album: The album name from Last.fm
    ///   - track: The track name from Last.fm
    /// - Returns: A normalized ID string like "queen-a night at the opera-bohemian rhapsody"
    static func generateTrackID(artist: String, album: String, track: String) -> String {
        // Normalize each component: lowercase and trim whitespace
        let components = [artist, album, track].map { component in
            component
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        // Join with hyphens to create unique ID
        return components.joined(separator: "-")
    }
}

