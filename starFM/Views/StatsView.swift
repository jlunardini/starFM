//
//  StatsView.swift
//  starFM
//
//  Displays statistics about the user's ratings.
//

import SwiftUI
import SwiftData

/// What type of ratings to show stats for
enum StatsType: String, CaseIterable {
    case tracks = "Tracks"
    case albums = "Albums"
}

/// Shows statistics about rated tracks and albums.
///
/// Currently scoped to the current month.
/// TODO: Expand to support last 6 months and year-to-date views.
struct StatsView: View {

    // MARK: - Data

    @Query private var allTrackRatings: [RatedTrack]
    @Query private var allAlbumRatings: [RatedAlbum]

    // MARK: - State

    @State private var selectedType: StatsType = .tracks

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                // Time period header
                Section {
                    HStack {
                        Image(systemName: "calendar")
                            .foregroundColor(.accentColor)
                        Text(currentMonthName)
                            .fontWeight(.medium)
                    }
                } header: {
                    Text("Showing stats for")
                }

                // Stats content based on selected type
                if selectedType == .tracks {
                    trackStatsContent
                } else {
                    albumStatsContent
                }
            }
            .navigationTitle("Stats")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Picker("Stats Type", selection: $selectedType) {
                        ForEach(StatsType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 200)
                }
            }
        }
    }

    // MARK: - Track Stats Content

    @ViewBuilder
    private var trackStatsContent: some View {
        // Overview section
        Section("Overview") {
            StatRow(label: "Tracks Rated", value: "\(currentMonthTrackRatings.count)")
            StatRow(label: "Average Rating", value: averageTrackRatingText)
        }

        // Rating distribution
        Section("Rating Distribution") {
            ForEach(1...5, id: \.self) { stars in
                ratingDistributionRow(stars: stars, count: trackCountForRating(stars))
            }
        }

        // Top rated section (5-star tracks this month)
        if !fiveStarTracks.isEmpty {
            Section("5-Star Tracks This Month") {
                ForEach(fiveStarTracks.prefix(10), id: \.trackID) { track in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(track.trackName ?? "Unknown Track")
                            .font(.body)
                        Text(track.artistName ?? "Unknown Artist")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Album Stats Content

    @ViewBuilder
    private var albumStatsContent: some View {
        // Overview section
        Section("Overview") {
            StatRow(label: "Albums Rated", value: "\(currentMonthAlbumRatings.count)")
            StatRow(label: "Average Rating", value: averageAlbumRatingText)
        }

        // Rating distribution
        Section("Rating Distribution") {
            ForEach(1...5, id: \.self) { stars in
                ratingDistributionRow(stars: stars, count: albumCountForRating(stars))
            }
        }

        // Top rated section (5-star albums this month)
        if !fiveStarAlbums.isEmpty {
            Section("5-Star Albums This Month") {
                ForEach(fiveStarAlbums.prefix(10), id: \.albumID) { album in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(album.albumName ?? "Unknown Album")
                            .font(.body)
                        Text(album.artistName ?? "Unknown Artist")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    // MARK: - Shared Subviews

    private func ratingDistributionRow(stars: Int, count: Int) -> some View {
        HStack {
            HStack(spacing: 2) {
                ForEach(1...stars, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                        .font(.caption)
                }
            }
            .frame(width: 80, alignment: .leading)

            Spacer()

            Text("\(count)")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Date Helpers

    private var startOfCurrentMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: Date())
        return calendar.date(from: components) ?? Date()
    }

    private var currentMonthName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }

    // MARK: - Track Stats Helpers

    private var currentMonthTrackRatings: [RatedTrack] {
        allTrackRatings.filter { rating in
            guard let createdAt = rating.createdAt else { return false }
            return createdAt >= startOfCurrentMonth
        }
    }

    private var averageTrackRatingText: String {
        let ratings = currentMonthTrackRatings
        guard !ratings.isEmpty else { return "—" }

        let total = ratings.compactMap { $0.rating }.reduce(0, +)
        let count = ratings.filter { $0.rating != nil }.count
        guard count > 0 else { return "—" }

        return String(format: "%.1f", Double(total) / Double(count))
    }

    private func trackCountForRating(_ rating: Int) -> Int {
        currentMonthTrackRatings.filter { $0.rating == rating }.count
    }

    private var fiveStarTracks: [RatedTrack] {
        currentMonthTrackRatings.filter { $0.rating == 5 }
    }

    // MARK: - Album Stats Helpers

    private var currentMonthAlbumRatings: [RatedAlbum] {
        allAlbumRatings.filter { rating in
            guard let createdAt = rating.createdAt else { return false }
            return createdAt >= startOfCurrentMonth
        }
    }

    private var averageAlbumRatingText: String {
        let ratings = currentMonthAlbumRatings
        guard !ratings.isEmpty else { return "—" }

        let total = ratings.compactMap { $0.rating }.reduce(0, +)
        let count = ratings.filter { $0.rating != nil }.count
        guard count > 0 else { return "—" }

        return String(format: "%.1f", Double(total) / Double(count))
    }

    private func albumCountForRating(_ rating: Int) -> Int {
        currentMonthAlbumRatings.filter { $0.rating == rating }.count
    }

    private var fiveStarAlbums: [RatedAlbum] {
        currentMonthAlbumRatings.filter { $0.rating == 5 }
    }
}

// MARK: - Helper Views

/// A simple label-value row for stats
struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Preview

#Preview {
    StatsView()
        .modelContainer(for: [RatedTrack.self, RatedAlbum.self], inMemory: true)
}

