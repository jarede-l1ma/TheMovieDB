import Foundation

struct PagedResponse<T: Decodable>: Decodable {
    let page: Int
    let results: [T]
    let totalPages: Int
    let totalResults: Int
}

struct Movie: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String?
    let overview: String?
    let posterPath: String?
    let backdropPath: String?
    let releaseDate: String?
    let voteAverage: Double?
}

enum MediaType: String, Decodable {
    case movie
}

enum SearchResult: Decodable, Hashable {
    case movie(Movie)

    private enum CodingKeys: String, CodingKey { case mediaType = "media_type" }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(MediaType.self, forKey: .mediaType)

        switch type {
        case .movie:
            self = .movie(try Movie(from: decoder))
        }
    }
}
