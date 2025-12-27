//
//  StarRatingView.swift
//  starFM
//
//  Reusable star rating picker component.
//  Displays 5 tappable stars for rating tracks.
//

import SwiftUI

/// A 5-star rating picker.
///
/// Usage:
/// ```
/// @State private var rating: Int? = nil
/// StarRatingView(rating: $rating)
/// ```
///
/// - Tap a star to set that rating (1-5)
/// - Tap the same star again to clear the rating (sets to nil)
struct StarRatingView: View {

    // MARK: - Properties

    /// Binding to the current rating (1-5, or nil if unrated)
    @Binding var rating: Int?

    /// Size of each star icon
    var starSize: CGFloat = 20

    /// Color for filled stars
    var filledColor: Color = .yellow

    /// Color for empty stars
    var emptyColor: Color = .gray

    // MARK: - Body

    var body: some View {
        HStack(spacing: 4) {
            // Create 5 star buttons
            ForEach(1...5, id: \.self) { starNumber in
                starButton(for: starNumber)
            }
        }
        .transition(.blurReplace)
    }

    // MARK: - Subviews

    /// Creates a single star button.
    ///
    /// - Parameter starNumber: Which star this is (1-5)
    /// - Returns: A tappable star image
    @ViewBuilder
    private func starButton(for starNumber: Int) -> some View {
        Button {
            handleTap(starNumber: starNumber)
        } label: {
            Image(systemName: starImageName(for: starNumber))
                .font(.system(size: starSize))
                .foregroundColor(starColor(for: starNumber))
                .contentTransition(.symbolEffect)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helper Methods

    /// Handles a tap on a star.
    ///
    /// - If tapping the currently selected rating, clears it (sets to nil)
    /// - Otherwise, sets the rating to the tapped star number
    private func handleTap(starNumber: Int) {
        withAnimation(.smooth) {
            if rating == starNumber {
                // Tapping the same star clears the rating
                rating = nil
            } else {
                rating = starNumber
            }
        }
    }

    /// Returns the SF Symbol name for a star position.
    ///
    /// - Parameter starNumber: Which star (1-5)
    /// - Returns: "star.fill" if rated at or above this position, "star" otherwise
    private func starImageName(for starNumber: Int) -> String {
        guard let currentRating = rating else {
            return "star"  // No rating = all empty stars
        }
        return starNumber <= currentRating ? "star.fill" : "star"
    }

    /// Returns the color for a star position.
    ///
    /// - Parameter starNumber: Which star (1-5)
    /// - Returns: Filled color if rated at or above this position, empty color otherwise
    private func starColor(for starNumber: Int) -> Color {
        guard let currentRating = rating else {
            return emptyColor
        }
        return starNumber <= currentRating ? filledColor : emptyColor
    }
}

// MARK: - Preview

#Preview("No Rating") {
    StarRatingView(rating: .constant(nil))
        .padding()
}

#Preview("3 Stars") {
    StarRatingView(rating: .constant(3))
        .padding()
}

#Preview("5 Stars - Large") {
    StarRatingView(rating: .constant(5), starSize: 32)
        .padding()
}

