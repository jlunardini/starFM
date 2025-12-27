//
//  APIModels.swift
//  starFM
//
//  Codable models for parsing Last.fm API JSON responses.
//  Last.fm uses some unusual JSON conventions that require custom CodingKeys.
//

import Foundation

// MARK: - Error Handling

/// Error response format from Last.fm API.
/// When something goes wrong, Last.fm returns: { "error": 4, "message": "..." }
struct LastFMErrorResponse: Codable {
    let error: Int
    let message: String
}

/// Custom error type for Last.fm API operations.
/// Conforms to LocalizedError so we can display user-friendly messages.
enum LastFMError: LocalizedError {
    case invalidCredentials
    case apiError(code: Int, message: String)
    case networkError(Error)
    case decodingError(Error)
    case missingAPIKeys

    /// User-friendly error message (used by .localizedDescription)
    var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid username or password"
        case .apiError(_, let message):
            return message
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError:
            return "Failed to parse response from Last.fm"
        case .missingAPIKeys:
            return "API keys not configured. Check Secrets.xcconfig"
        }
    }
}

// MARK: - Authentication Response

/// Response from auth.getMobileSession API call.
/// Returns a session key that we store for future authenticated requests.
struct AuthResponse: Codable {
    let session: Session

    struct Session: Codable {
        let name: String  // The username
        let key: String   // Session key - store this!
    }
}

// MARK: - Recent Tracks Response

/// Response from user.getRecentTracks API call.
/// Contains a list of tracks the user has recently listened to.
struct RecentTracksResponse: Codable {
    let recenttracks: RecentTracks

    struct RecentTracks: Codable {
        let track: [RecentTrack]
    }
}

/// A single track from the recent tracks list.
/// Note: Last.fm uses "#text" for many values, requiring custom CodingKeys.
struct RecentTrack: Codable, Identifiable {
    let name: String
    let artist: Artist
    let album: Album
    let image: [LastFMImage]
    let date: TrackDate?      // nil if track is currently playing
    let nowPlaying: String?   // "@attr" with "nowplaying" if currently playing

    /// Unique ID for SwiftUI ForEach - combines name + date (or "now" if playing)
    var id: String {
        "\(artist.name)-\(album.name)-\(name)-\(date?.uts ?? "now")"
    }

    // MARK: - Nested Types

    /// Artist info - Last.fm sends: { "#text": "Queen", "mbid": "..." }
    struct Artist: Codable {
        let name: String

        // Maps our "name" property to the "#text" key in JSON
        enum CodingKeys: String, CodingKey {
            case name = "#text"
        }
    }

    /// Album info - Last.fm sends: { "#text": "A Night at the Opera", "mbid": "..." }
    struct Album: Codable {
        let name: String

        enum CodingKeys: String, CodingKey {
            case name = "#text"
        }
    }

    /// When the track was played - Last.fm sends: { "uts": "1699999999", "#text": "..." }
    struct TrackDate: Codable {
        let uts: String  // Unix timestamp as a string

        /// Converts the unix timestamp string to a Date object
        var asDate: Date? {
            guard let timestamp = Double(uts) else { return nil }
            return Date(timeIntervalSince1970: timestamp)
        }
    }

    // Custom decoding to handle the "@attr" nowplaying field
    enum CodingKeys: String, CodingKey {
        case name, artist, album, image, date
        case nowPlaying = "@attr"
    }
}

/// Image from Last.fm - comes in multiple sizes.
/// Last.fm sends: { "#text": "https://...", "size": "large" }
struct LastFMImage: Codable {
    let url: String
    let size: String

    enum CodingKeys: String, CodingKey {
        case url = "#text"
        case size
    }

    /// Returns true if this is the "extralarge" size (best quality)
    var isExtraLarge: Bool {
        size == "extralarge"
    }
}

// MARK: - Flexible Types (Last.fm is inconsistent)

/// A type that can decode from either a String or Int.
/// Last.fm sometimes returns numbers as strings, sometimes as actual numbers.
struct FlexibleInt: Codable {
    let value: Int

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try Int first
        if let intValue = try? container.decode(Int.self) {
            self.value = intValue
        }
        // Try String and convert
        else if let stringValue = try? container.decode(String.self) {
            self.value = Int(stringValue) ?? 0
        }
        // Default to 0
        else {
            self.value = 0
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
}

// MARK: - Album Info Response

/// Response from album.getInfo API call.
/// Contains album details including track listing and user's play stats.
struct AlbumInfoResponse: Codable {
    let album: AlbumDetail
}

/// Detailed album information including tracks and user stats.
struct AlbumDetail: Codable {
    let name: String
    let artist: String
    let image: [LastFMImage]?  // Optional - some albums have no images
    let tracks: AlbumTracks?
    let userplaycount: FlexibleInt?  // Can come as string OR int from Last.fm

    /// Parsed user play count as Int
    var userPlayCountInt: Int {
        userplaycount?.value ?? 0
    }

    /// Wrapper for track list - uses custom decoding to handle Last.fm's quirks
    struct AlbumTracks: Codable {
        let track: [AlbumTrack]

        // Custom decoding to handle: array, single object, or empty/missing
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            // Try array first - with detailed error
            do {
                let tracks = try container.decode([AlbumTrack].self, forKey: .track)
                print("🎵 Decoded \(tracks.count) tracks as array")
                self.track = tracks
                return
            } catch {
                print("🎵 Array decode failed: \(error)")
            }

            // Try single object
            if let singleTrack = try? container.decode(AlbumTrack.self, forKey: .track) {
                print("🎵 Decoded 1 track as single object")
                self.track = [singleTrack]
                return
            }

            // Try empty string (Last.fm sometimes returns "" for empty)
            if let emptyStr = try? container.decode(String.self, forKey: .track) {
                print("🎵 Got empty string for tracks: '\(emptyStr)'")
                self.track = []
                return
            }

            // Default to empty
            print("🎵 Could not decode tracks, defaulting to empty")
            self.track = []
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(track, forKey: .track)
        }

        enum CodingKeys: String, CodingKey {
            case track
        }
    }
}

/// A track within an album's track listing.
struct AlbumTrack: Codable, Identifiable {
    let name: String
    let duration: FlexibleInt?  // Can be string OR int from Last.fm
    let artist: AlbumTrackArtist

    var id: String { name }

    /// Duration in seconds for display
    var durationSeconds: Int {
        duration?.value ?? 0
    }

    /// Artist for album track - has a "name" property
    struct AlbumTrackArtist: Codable {
        let name: String
    }
}

