import UIKit

/// Centralized Design System tokens for colors, spacing, typography, and accessibility identifiers.
enum DesignSystem {
    
    enum Colors {
        static let background = UIColor.systemBackground
        static let secondaryBackground = UIColor.secondarySystemBackground
        static let label = UIColor.label
        static let secondaryLabel = UIColor.secondaryLabel
        static let accent = UIColor.systemBlue
    }
    
    enum Spacing {
        static let tiny: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 16
        static let large: CGFloat = 24
    }
    
    enum CornerRadius {
        static let card: CGFloat = 8
    }
    
    enum Accessibility {
        static let homeCollectionView = "home_collection_view"
        static let homeActivityIndicator = "home_activity_indicator"
        static let posterCell = "poster_collection_view_cell"
        static let posterImage = "movie_poster_image"
        static let movieTitle = "movie_title_label"
        static let movieDetailsScrollView = "movie_details_scroll_view"
    }
}
