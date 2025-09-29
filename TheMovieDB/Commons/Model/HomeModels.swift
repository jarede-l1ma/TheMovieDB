import Foundation

enum Home {
    enum Mode: Equatable {
        case nowPlaying
    }

    struct ItemViewModel: Hashable {
        let id: Int
        let title: String
        let subtitle: String?
        let posterPath: String?
    }

    struct ViewState: Equatable {
        let title: String
        let isLoading: Bool
        let itemsCount: Int
        let isPaginating: Bool
        let isEmpty: Bool
    }
}
