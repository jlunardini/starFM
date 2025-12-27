//
//  AlbumDetailView.swift
//  starFM
//
//  Displays full album details including artwork, stats, and track listing.
//  Each track can be rated with stars.
//

import SwiftUI
import SwiftData

/// Full album view with artwork, stats, and track listing.
///
/// Fetches album info from Last.fm API on appear.
/// Shows existing ratings and allows rating any track.
struct AlbumDetailView: View {

    // MARK: - Environment & Data
    @Environment(\.modelContext) private var modelContext
    @Query private var allTrackRatings: [RatedTrack]
    @Query private var allAlbumRatings: [RatedAlbum]
    @AppStorage("lastfm_username") private var username: String = ""

    // MARK: - Input Properties
    let artistName: String
    let albumName: String

    // MARK: - Local State
    @State private var albumDetail: AlbumDetail?
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // MARK: - Body
    var body: some View {
        ZStack {
            if isLoading && albumDetail == nil {
                ProgressView("Loading album...")
            } else if let error = errorMessage, albumDetail == nil {
                errorView(message: error)
            } else if let album = albumDetail {
                albumContent(album: album)
            } else {
                Text("No album data")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadAlbumInfo()
        }
    }

    // MARK: - Subviews
    private func albumContent(album: AlbumDetail) -> some View {
        ScrollView(showsIndicators:false) {
            VStack(spacing: 0) {
                AlbumHeaderView(
                    albumName: album.name,
                    artistName: album.artist,
                    imageURL: bestImageURL(from: album.image),
                    playCount: album.userPlayCountInt
                )
                Spacer()
                    .frame(height:20)
                StarRatingView(rating: albumRatingBinding, starSize: 24)
               Spacer()
                    .frame(height:42)
                HStack {
                    Spacer()
                    if let avg = averageTrackRating {
                        Text("Avg: \(avg, specifier: "%.1f") ★")
                            .fontWeight(.medium)
                            .fontDesign(.rounded)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .transition(.blurReplace)
                    }
                }
                .padding(.horizontal)
                if let tracks = album.tracks?.track, !tracks.isEmpty {
                    Spacer()
                         .frame(height:4)
                    trackList(tracks: tracks)
                } else {
                    noTracksView
                }
            }
        }
        .contentMargins(.bottom, 24)
        .ignoresSafeArea(.all, edges: .top)
    }

    private var noTracksView: some View {
        VStack(spacing: 8) {
            Image(systemName: "music.note.list")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("No track listing available")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("Last.fm doesn't have track data for this album")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private func trackList(tracks: [AlbumTrack]) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(tracks) { track in
                VStack(spacing: 0) {
                    TrackRowView(
                        trackName: track.name,
                        artistName: nil,
                        albumName: nil,
                        rating: ratingBinding(for: track),
                        showAlbum: false
                    )
                    .padding(.horizontal)
                    .padding(.vertical, 12)

                    Divider()
                        .padding(.leading)
                }
            }
        }
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Text("Failed to load album")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await loadAlbumInfo()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Computed Properties

    /// The album ID for this album
    private var currentAlbumID: String {
        RatedAlbum.generateAlbumID(artist: artistName, album: albumName)
    }

    /// Average rating of all rated tracks on this album
    private var averageTrackRating: Double? {
        // Get all track ratings for this album
        let albumTrackRatings = allTrackRatings.filter {
            $0.albumName?.lowercased() == albumName.lowercased() &&
            $0.artistName?.lowercased() == artistName.lowercased() &&
            $0.rating != nil
        }

        guard !albumTrackRatings.isEmpty else { return nil }

        let total = albumTrackRatings.compactMap { $0.rating }.reduce(0, +)
        return Double(total) / Double(albumTrackRatings.count)
    }

    /// Binding for the album's overall rating
    private var albumRatingBinding: Binding<Int?> {
        Binding(
            get: {
                allAlbumRatings.first { $0.albumID == currentAlbumID }?.rating
            },
            set: { newRating in
                saveAlbumRating(newRating)
            }
        )
    }

    // MARK: - Methods

    /// Saves or updates the album rating
    private func saveAlbumRating(_ rating: Int?) {
        if let existing = allAlbumRatings.first(where: { $0.albumID == currentAlbumID }) {
            if let rating = rating {
                existing.rating = rating
                existing.updatedAt = Date()
            } else {
                modelContext.delete(existing)
            }
        } else if let rating = rating {
            let newAlbumRating = RatedAlbum()
            newAlbumRating.albumID = currentAlbumID
            newAlbumRating.albumName = albumName
            newAlbumRating.artistName = artistName
            newAlbumRating.rating = rating
            newAlbumRating.createdAt = Date()
            newAlbumRating.updatedAt = Date()

            modelContext.insert(newAlbumRating)
        }
    }

    /// Fetches album details from Last.fm API
    private func loadAlbumInfo() async {
        isLoading = true
        errorMessage = nil

        do {
            let album = try await LastFMService.shared.getAlbumInfo(
                artist: artistName,
                album: albumName,
                user: username
            )
            albumDetail = album

            // Debug: Check what we got for tracks
            print("📀 Album loaded: \(album.name)")
            print("🎵 Tracks object: \(album.tracks != nil ? "exists" : "nil")")
            print("🎵 Track count: \(album.tracks?.track.count ?? 0)")
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Gets the best quality image URL from the array of images.
    ///
    /// Last.fm provides images in multiple sizes. We prefer "extralarge"
    /// for best quality, falling back to the last image in the array.
    ///
    /// - Parameter images: Array of LastFMImage from the API
    /// - Returns: URL string for the best available image, or nil
    private func bestImageURL(from images: [LastFMImage]?) -> String? {
        guard let images = images, !images.isEmpty else { return nil }

        // Try to find extralarge first
        if let extraLarge = images.first(where: { $0.isExtraLarge }) {
            return extraLarge.url.isEmpty ? nil : extraLarge.url
        }

        // Fall back to last image (usually largest)
        let lastImage = images.last
        return lastImage?.url.isEmpty == false ? lastImage?.url : nil
    }

    /// Creates a binding for a track's rating (same pattern as RecentTracksView)
    private func ratingBinding(for track: AlbumTrack) -> Binding<Int?> {
        let trackID = RatedTrack.generateTrackID(
            artist: artistName,
            album: albumName,
            track: track.name
        )

        return Binding(
            get: {
                allTrackRatings.first { $0.trackID == trackID }?.rating
            },
            set: { newRating in
                saveTrackRating(newRating, for: track, trackID: trackID)
            }
        )
    }

    /// Saves or updates a track rating in SwiftData
    private func saveTrackRating(_ rating: Int?, for track: AlbumTrack, trackID: String) {
        if let existing = allTrackRatings.first(where: { $0.trackID == trackID }) {
            if let rating = rating {
                existing.rating = rating
                existing.updatedAt = Date()
            } else {
                modelContext.delete(existing)
            }
        } else if let rating = rating {
            let newRating = RatedTrack()
            newRating.trackID = trackID
            newRating.trackName = track.name
            newRating.artistName = artistName
            newRating.albumName = albumName
            newRating.rating = rating
            newRating.createdAt = Date()
            newRating.updatedAt = Date()

            modelContext.insert(newRating)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AlbumDetailView(
            artistName: "Queen",
            albumName: "A Night at the Opera"
        )
    }
    .modelContainer(for: [RatedTrack.self, RatedAlbum.self], inMemory: true)
}

