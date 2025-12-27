//
//  AlbumHeaderView.swift
//  starFM
//
//  Displays album artwork and listening statistics.
//  Used at the top of AlbumDetailView.
//

import Glur
import SwiftUI
import Kingfisher

/// Header component showing album art and stats.
///
/// Usage:
/// ```
/// AlbumHeaderView(
///     albumName: "A Night at the Opera",
///     artistName: "Queen",
///     imageURL: "https://...",
///     playCount: 42
/// )
/// ```
struct AlbumHeaderView: View {

    // MARK: - Properties
    let albumName: String
    let artistName: String
    let imageURL: String?
    let playCount: Int

    // MARK: - Body
    var body: some View {
        ZStack(alignment:.bottom) {
            blurredAlbumArtwork
            VStack(spacing: 0) {
                albumArtwork
                VStack {
                    Spacer()
                        .frame(height: 20)
                    albumInfo
                    Spacer()
                        .frame(height: 16)
                    playCountView
                }
                .padding(.horizontal)
            }
        }
    }

    // MARK: - Subviews
    
    private var blurredAlbumArtwork: some View {
        Group {
            if let urlString = imageURL, let url = URL(string: urlString) {
                KFImage.url(url)
                    .loadDiskFileSynchronously()
                    .cacheOriginalImage()
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 400)
                    .offset(y: 220)
                    .scaleEffect(5.0, anchor: .bottom)
                    .glur(
                        radius: 24.0,
                        offset: 0.0,
                        interpolation: 0.00,
                        direction: .down,
                        noise: 0.05,
                        drawingGroup: true
                    )
                    .overlay(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                .clear,
                                Color(uiColor: .systemBackground).opacity(0.3),
                                Color(uiColor: .systemBackground).opacity(0.6),
                                Color(uiColor: .systemBackground).opacity(0.9),
                                Color(uiColor: .systemBackground),
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .clipped()
            }
        }
    }
    
    private var albumArtwork: some View {
        Group {
            if let urlString = imageURL, let url = URL(string: urlString) {
                    KFImage.url(url)
                        .placeholder { placeholderImage }
                        .loadDiskFileSynchronously()
                        .cacheOriginalImage()
                        .fade(duration: 0.25)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                        )
                        .padding(.top, 36)
                        .frame(maxWidth: .infinity, maxHeight: 220)
            } else {
                placeholderImage
            }
        }
    }
    private var placeholderImage: some View {
        Image(systemName: "music.note")
            .font(.system(size: 60))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .background(Color.gray.opacity(0.2))
            .cornerRadius(8)
            .frame(minHeight: 400)
    }

    private var albumInfo: some View {
        VStack(alignment: .center, spacing: 4) {
            Text(albumName)
                .fontDesign(.rounded)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, alignment: .center)
            Text(artistName)
                .font(.subheadline)
                .fontDesign(.rounded)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var playCountView: some View {
        HStack {
            Image(systemName: "play.circle.fill")
                .foregroundColor(.accentColor)
                .font(.subheadline)
            Text("\(playCount) plays")
                .fontWeight(.medium)
                .fontDesign(.rounded)
                .font(.callout)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.1))
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview("With Image URL") {
    AlbumHeaderView(
        albumName: "A Night at the Opera",
        artistName: "Queen",
        imageURL:
            "https://kagi.com/proxy/marie_davidson_city_of_clowns_ce3c592799.jpg?c=fi3aA80vSajwRE6-e_5400-Y4PsKhLgrp83BOS-QmLskpfpDLMhVJlr6s0SgPJLbVKUSSOa_TogDJC7qUKtWSuv3-XFbXwoio7XwPunyx2Ak6sL6QEgYGxNT8igwNqDPVr59dBWdsenVU9QSb6iJ6Q%3D%3D",
        playCount: 42
    )
}

#Preview("No Image") {
    AlbumHeaderView(
        albumName: "Unknown Album",
        artistName: "Unknown Artist",
        imageURL: nil,
        playCount: 0
    )
}
