//
//  LastFMService.swift
//  starFM
//
//  Singleton service for all Last.fm API interactions.
//  Handles authentication, fetching recent tracks, and album info.
//

import Foundation
import CryptoKit  // For MD5 hashing (used in API signing)

/// Singleton service for Last.fm API calls.
///
/// Usage:
/// ```
/// let tracks = try await LastFMService.shared.getRecentTracks(for: "username", limit: 50)
/// ```
final class LastFMService {

    // MARK: - Singleton

    /// Shared instance - use this to make API calls
    static let shared = LastFMService()

    /// Private init prevents creating other instances
    private init() {}

    // MARK: - Authentication

    /// Authenticates with Last.fm and returns a session key.
    ///
    /// The session key should be stored (e.g., in @AppStorage) and used for
    /// future authenticated requests. Session keys don't expire.
    ///
    /// - Parameters:
    ///   - username: The user's Last.fm username
    ///   - password: The user's Last.fm password
    /// - Returns: A session key string to store for future use
    /// - Throws: `LastFMError` if authentication fails
    func authenticate(username: String, password: String) async throws -> String {
        // Check that API keys are configured
        guard !Constants.lastFMAPIKey.isEmpty,
              !Constants.lastFMSharedSecret.isEmpty else {
            throw LastFMError.missingAPIKeys
        }

        // Build the parameters for auth.getMobileSession
        // Note: password is sent in plain text (Last.fm requires this for mobile auth)
        let params: [String: String] = [
            "method": "auth.getMobileSession",
            "username": username,
            "password": password,
            "api_key": Constants.lastFMAPIKey
        ]

        // Sign and execute the request
        let response: AuthResponse = try await performSignedRequest(params: params, httpMethod: "POST")

        return response.session.key
    }

    // MARK: - Recent Tracks

    /// Fetches the user's recently played tracks from Last.fm.
    ///
    /// - Parameters:
    ///   - user: The Last.fm username to fetch tracks for
    ///   - limit: Maximum number of tracks to return (default 50, max 200)
    /// - Returns: Array of recently played tracks
    /// - Throws: `LastFMError` if the request fails
    func getRecentTracks(for user: String, limit: Int = 50) async throws -> [RecentTrack] {
        let params: [String: String] = [
            "method": "user.getRecentTracks",
            "user": user,
            "api_key": Constants.lastFMAPIKey,
            "limit": String(limit),
            "format": "json"
        ]

        // This endpoint doesn't require signing (public data)
        let response: RecentTracksResponse = try await performRequest(params: params)

        return response.recenttracks.track
    }

    // MARK: - Album Info

    /// Fetches detailed album information including track listing and user stats.
    ///
    /// - Parameters:
    ///   - artist: The artist name
    ///   - album: The album name
    ///   - user: The username (to get personalized play counts)
    /// - Returns: Album details with tracks and stats
    /// - Throws: `LastFMError` if the request fails
    func getAlbumInfo(artist: String, album: String, user: String) async throws -> AlbumDetail {
        // Debug: Log what we're requesting
        print("🔍 Fetching album: '\(album)' by '\(artist)'")

        let params: [String: String] = [
            "method": "album.getInfo",
            "artist": artist,
            "album": album,
            "username": user,  // Include user to get their play count
            "api_key": Constants.lastFMAPIKey,
            "format": "json"
        ]

        let response: AlbumInfoResponse = try await performRequest(params: params)

        return response.album
    }

    // MARK: - Private Helpers

    /// Performs a signed API request (required for auth endpoints).
    ///
    /// Last.fm requires certain endpoints to include an "api_sig" parameter,
    /// which is an MD5 hash of all parameters + the shared secret.
    ///
    /// - Parameters:
    ///   - params: The request parameters (will be signed)
    ///   - httpMethod: HTTP method (GET or POST)
    /// - Returns: Decoded response of type T
    private func performSignedRequest<T: Codable>(
        params: [String: String],
        httpMethod: String
    ) async throws -> T {
        // Add signature to params
        var signedParams = params
        signedParams["api_sig"] = generateSignature(params: params)
        signedParams["format"] = "json"

        return try await performRequest(params: signedParams, httpMethod: httpMethod)
    }

    /// Performs an API request and decodes the response.
    ///
    /// - Parameters:
    ///   - params: Query parameters
    ///   - httpMethod: HTTP method (default GET)
    /// - Returns: Decoded response of type T
    private func performRequest<T: Codable>(
        params: [String: String],
        httpMethod: String = "GET"
    ) async throws -> T {
        // Build URL with query parameters
        var urlComponents = URLComponents(string: Constants.lastFMBaseURL)!
        urlComponents.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }

        guard let url = urlComponents.url else {
            throw LastFMError.networkError(URLError(.badURL))
        }

        // Create request
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod

        // Execute request
        let (data, _): (Data, URLResponse)
        do {
            (data, _) = try await URLSession.shared.data(for: request)
        } catch {
            throw LastFMError.networkError(error)
        }

        // Check for Last.fm error response first
        // Last.fm returns 200 OK even for errors, so we check the body
        if let errorResponse = try? JSONDecoder().decode(LastFMErrorResponse.self, from: data) {
            // Error code 4 = invalid credentials
            if errorResponse.error == 4 {
                throw LastFMError.invalidCredentials
            }
            throw LastFMError.apiError(code: errorResponse.error, message: errorResponse.message)
        }

        // Decode successful response
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            // Debug logging - shows what went wrong with parsing
            print("⚠️ Decoding error: \(error)")
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📄 Raw response (first 1000 chars): \(String(jsonString.prefix(1000)))")
            }
            throw LastFMError.decodingError(error)
        }
    }

    /// Generates the API signature required for authenticated requests.
    ///
    /// Last.fm signature algorithm:
    /// 1. Sort all parameters alphabetically by key
    /// 2. Concatenate as: key1value1key2value2...
    /// 3. Append the shared secret
    /// 4. MD5 hash the result
    /// 5. Return as lowercase hex string
    ///
    /// - Parameter params: The parameters to sign
    /// - Returns: MD5 signature as hex string
    private func generateSignature(params: [String: String]) -> String {
        // Step 1: Sort parameters alphabetically by key
        let sortedParams = params.sorted { $0.key < $1.key }

        // Step 2: Concatenate as key1value1key2value2...
        var signatureBase = ""
        for (key, value) in sortedParams {
            signatureBase += "\(key)\(value)"
        }

        // Step 3: Append shared secret
        signatureBase += Constants.lastFMSharedSecret

        // Step 4: MD5 hash
        // Insecure.MD5 is fine here - we're not using it for security,
        // just because Last.fm's API requires it
        let digest = Insecure.MD5.hash(data: Data(signatureBase.utf8))

        // Step 5: Convert to lowercase hex string
        let signature = digest.map { String(format: "%02hhx", $0) }.joined()

        return signature
    }
}

