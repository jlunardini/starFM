//
//  TrackRowView.swift
//  starFM
//
//  Displays a single track row with artist, track name, and star rating.
//  Used in both RecentTracksView and AlbumDetailView.
//

import SwiftUI
import Kingfisher
import Glur

/// A row displaying track info and its star rating.
///
/// Usage:
/// ```
/// TrackRowView(
///     trackName: "Bohemian Rhapsody",
///     artistName: "Queen",
///     albumName: "A Night at the Opera",
///     rating: $rating
/// )
/// ```
struct TrackRowView: View {

    // MARK: Environment

    // MARK: - Properties
    let trackName: String
    let artistName: String?
    let albumName: String?
    @Binding var rating: Int?
    var showAlbum: Bool = true
    var playCount: Int? = nil
    var imageURL: String? = nil

    // MARK: - Body
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                trackInfo
                Spacer()
                    .frame(height:12)
                StarRatingView(rating: $rating, starSize: 20)
            }
            .padding(.trailing, 8)
            Spacer()
            if let imageURL = imageURL {
                albumArtwork(url: imageURL)
            }
        }
    }

    // MARK: - Subviews
    private func albumArtwork(url: String) -> some View {
        KFImage.url(URL(string: url))
            .placeholder {
                ProgressView()
            }
            .loadDiskFileSynchronously()
            .cacheOriginalImage()
            .fade(duration: 0.25)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width:64, height:64)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var placeholderImage: some View {
        Image(systemName: "music.note")
            .foregroundColor(.secondary)
            .frame(width: 50, height: 50)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(4)
    }

    // MARK: - Subviews
    private var trackInfo: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(trackName)
                .font(.title3)
                .fontWeight(.bold)
                .fontDesign(.rounded)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            if let subtitle = subtitleText {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Computed Properties
    private var subtitleText: String? {
        var parts: [String] = []

        if let artist = artistName {
            parts.append(artist)
        }

        if showAlbum, let album = albumName, !album.isEmpty {
            parts.append(album)
        }

        if let count = playCount {
            parts.append("\(count) plays")
        }

        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }
}

// MARK: - Preview

#Preview("With Album") {
    List {
        TrackRowView(
            trackName: "Bohemian Rhapsody",
            artistName: "Queen",
            albumName: "A Night at the Opera",
            rating: .constant(4)
        )
        TrackRowView(
            trackName: "Don't Stop Me Now",
            artistName: "Queen",
            albumName: "Jazz",
            rating: .constant(nil)
        )
    }
}

#Preview("Without Album + Play Count") {
    List {
        TrackRowView(
            trackName: "Bohemian Rhapsody",
            artistName: "Queen",
            albumName: nil,
            rating: .constant(5),
            showAlbum: false,
            playCount: 42
        )
    }
}

#Preview("No Artist Name") {
    List {
        TrackRowView(
            trackName: "Instrumental Track",
            artistName: nil,
            albumName: "Soundscapes",
            rating: .constant(3),
            playCount: 12
        )
        TrackRowView(
            trackName: "Just Track Name",
            artistName: nil,
            albumName: nil,
            rating: .constant(4)
        )
    }
}
