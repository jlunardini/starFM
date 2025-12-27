//
//  RecentTracksView.swift
//  starFM
//
//  Displays the user's recent listening history from Last.fm.
//  Each track shows its star rating and navigates to album details on tap.
//

import SwiftUI
import SwiftData

/// Main view showing recent tracks with ratings.
///
/// - Fetches recent tracks from Last.fm API on appear
/// - Displays existing ratings from SwiftData
/// - Tapping a track navigates to its album detail view
struct RecentTracksView: View {

    // MARK: - Environment & Data
    @Environment(\.modelContext) private var modelContext
    @Query private var allTrackRatings: [RatedTrack]
    @AppStorage("lastfm_username") private var username: String = ""
    @Namespace private var recentTracksNamespace


    // MARK: - Local State
    @State private var recentTracks: [RecentTrack] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // MARK: - Body
    var body: some View {
        Group {
            if isLoading && recentTracks.isEmpty {
                ProgressView("Loading tracks...")
            } else if let error = errorMessage, recentTracks.isEmpty {
                errorView(message: error)
            } else {
                trackList
            }
        }
        .navigationTitle("Recent Tracks")
        .task {
            await loadTracks()
        }
        .refreshable {
            await loadTracks()
        }
    }

    // MARK: - Subviews
    private var trackList: some View {
        List(recentTracks) { track in
            if track.album.name.isEmpty {
                TrackRowView(
                    trackName: track.name,
                    artistName: track.artist.name,
                    albumName: nil,  // No album to show
                    rating: ratingBinding(for: track),
                    imageURL: bestImageURL(from: track.image)
                )
//                .listRowSeparator(.hidden)
            } else {
                NavigationLink {
                    AlbumDetailView(
                        artistName: track.artist.name,
                        albumName: track.album.name
                    )
                    .navigationTransition(.zoom(sourceID: track.name, in: recentTracksNamespace))
                } label: {
                    TrackRowView(
                        trackName: track.name,
                        artistName: track.artist.name,
                        albumName: track.album.name,
                        rating: ratingBinding(for: track),
                        imageURL: bestImageURL(from: track.image)
                    )
                    .matchedTransitionSource(id: track.name, in: recentTracksNamespace)
                }
//                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
    }

    private func bestImageURL(from images: [LastFMImage]) -> String? {
        // Try to find "large" size first (good balance of quality and size)
        if let large = images.first(where: { $0.size == "large" }) {
            return large.url.isEmpty ? nil : large.url
        }
        // Fall back to last image (usually largest)
        if let last = images.last {
            return last.url.isEmpty ? nil : last.url
        }
        return nil
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Text("Failed to load tracks")
                .font(.headline)

            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await loadTracks()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    // MARK: - Methods

    private func loadTracks() async {
        isLoading = true
        errorMessage = nil

        do {
            recentTracks = try await LastFMService.shared.getRecentTracks(
                for: username,
                limit: 50
            )
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }

    /// Creates a binding for a track's rating.
    ///
    /// This bridges between the API track data and our SwiftData ratings.
    /// - Get: Looks up existing rating by trackID
    /// - Set: Creates or updates a RatedTrack in SwiftData
    ///
    /// - Parameter track: The track from the Last.fm API
    /// - Returns: A binding to the track's rating (nil if unrated)
    private func ratingBinding(for track: RecentTrack) -> Binding<Int?> {
        // Generate the ID we use to match tracks
        let trackID = RatedTrack.generateTrackID(
            artist: track.artist.name,
            album: track.album.name,
            track: track.name
        )

        return Binding(
            get: {
                // Find existing rating by trackID
                allTrackRatings.first { $0.trackID == trackID }?.rating
            },
            set: { newRating in
                saveRating(newRating, for: track, trackID: trackID)
            }
        )
    }

    /// Saves or updates a rating in SwiftData.
    ///
    /// - Parameters:
    ///   - rating: The new rating (1-5), or nil to delete
    ///   - track: The track being rated
    ///   - trackID: Pre-computed track ID
    private func saveRating(_ rating: Int?, for track: RecentTrack, trackID: String) {
        // Check if we already have a rating for this track
        if let existing = allTrackRatings.first(where: { $0.trackID == trackID }) {
            if let rating = rating {
                // Update existing rating
                existing.rating = rating
                existing.updatedAt = Date()
            } else {
                // Rating cleared - delete the record
                modelContext.delete(existing)
            }
        } else if let rating = rating {
            // Create new rating (only if rating is not nil)
            let newRating = RatedTrack()
            newRating.trackID = trackID
            newRating.trackName = track.name
            newRating.artistName = track.artist.name
            newRating.albumName = track.album.name
            newRating.rating = rating
            newRating.createdAt = Date()
            newRating.updatedAt = Date()

            modelContext.insert(newRating)
        }
        // SwiftData auto-saves, no need to call save() explicitly
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        RecentTracksView()
    }
    .modelContainer(for: RatedTrack.self, inMemory: true)
}

