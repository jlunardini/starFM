//
//  RatedAlbum.swift
//  starFM
//
//  SwiftData model for storing user's star ratings for albums.
//  All properties are optional to support iCloud sync (CloudKit requirement).
//

import Foundation
import SwiftData

/// An album that the user has rated with stars.
///
/// This is separate from track ratings - it represents the user's
/// overall opinion of the album as a complete work.
@Model
final class RatedAlbum {

    // MARK: - Identification

    /// Unique identifier combining artist and album names.
    /// Format: "artistname-albumname" (lowercased, trimmed)
    var albumID: String?

    /// The name of the album
    var albumName: String?

    /// The artist who made the album
    var artistName: String?

    // MARK: - Rating

    /// User's star rating: 1-5, or nil if not yet rated
    var rating: Int?

    // MARK: - Timestamps

    /// When this rating was first created
    var createdAt: Date?

    /// When this rating was last modified
    var updatedAt: Date?

    // MARK: - Initialization

    /// Empty initializer required by SwiftData
    init() {}

    // MARK: - Helper Methods

    /// Generates a consistent, normalized album ID from artist/album names.
    ///
    /// - Parameters:
    ///   - artist: The artist name
    ///   - album: The album name
    /// - Returns: A normalized ID string like "queen-a night at the opera"
    static func generateAlbumID(artist: String, album: String) -> String {
        let components = [artist, album].map { component in
            component
                .lowercased()
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return components.joined(separator: "-")
    }
}

