import Foundation
@testable import TheMovieDB

extension Movie {
    static func fixture(
        id: Int = 1,
        title: String? = "Movie 1",
        overview: String? = "Overview 1",
        posterPath: String? = "/poster1.jpg",
        backdropPath: String? = "/backdrop1.jpg",
        releaseDate: String? = "2024-01-01",
        voteAverage: Double? = 8.5
    ) -> Movie {
        Movie(
            id: id,
            title: title,
            overview: overview,
            posterPath: posterPath,
            backdropPath: backdropPath,
            releaseDate: releaseDate,
            voteAverage: voteAverage
        )
    }

    /// A list of distinct movies, one per id, titled "Movie <id>".
    static func fixtures(ids: ClosedRange<Int>) -> [Movie] {
        ids.map { id in
            .fixture(
                id: id,
                title: "Movie \(id)",
                overview: "Overview \(id)",
                posterPath: "/poster\(id).jpg",
                backdropPath: "/backdrop\(id).jpg",
                releaseDate: "2024-01-\(String(format: "%02d", id))"
            )
        }
    }
}

extension PagedResponse where T == Movie {
    static func fixture(page: Int = 1, movies: [Movie] = Movie.fixtures(ids: 1...3), totalPages: Int = 5) -> PagedResponse<Movie> {
        PagedResponse(page: page, results: movies, totalPages: totalPages, totalResults: totalPages * movies.count)
    }
}

extension Home.ItemViewModel {
    static func fixture(
        id: Int = 1,
        title: String = "Movie 1",
        subtitle: String? = "2024-01-01",
        posterPath: String? = "/poster1.jpg"
    ) -> Home.ItemViewModel {
        Home.ItemViewModel(id: id, title: title, subtitle: subtitle, posterPath: posterPath)
    }

}

extension Array where Element == Home.ItemViewModel {
    /// The view models the Home interactor is expected to produce for `Movie.fixtures(ids:)`.
    static func fixtures(ids: ClosedRange<Int>) -> [Home.ItemViewModel] {
        Movie.fixtures(ids: ids).map {
            .fixture(id: $0.id, title: $0.title ?? "", subtitle: $0.releaseDate, posterPath: $0.posterPath)
        }
    }
}
