import Combine
import Foundation

// Temporary bridge for code not yet migrated to TCA. Delete once nothing calls use cases synchronously.

func legacyPublisher<T>(_ operation: @escaping @Sendable () async throws -> T) -> AnyPublisher<T, Error> {
    Deferred {
        var task: Task<Void, Never>?

        return Future<T, Error> { promise in
            nonisolated(unsafe) let promise = promise

            task = Task {
                do {
                    try await promise(.success(operation()))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .handleEvents(receiveCancel: { task?.cancel() })
    }
    .receive(on: DispatchQueue.main)
    .eraseToAnyPublisher()
}

extension AddToBookmarksUseCase {
    func callAsFunction(movieId: String, bookmarkUserCategory: Int) -> AnyPublisher<Bool, Error> {
        legacyPublisher { try await self(movieId: movieId, bookmarkUserCategory: bookmarkUserCategory) }
    }
}

extension ChangeBookmarksCategoryNameUseCase {
    func callAsFunction(id: Int, newName: String) -> AnyPublisher<Bool, Error> {
        legacyPublisher { try await self(id: id, newName: newName) }
    }
}

extension CreateBookmarksCategoryUseCase {
    func callAsFunction(name: String) -> AnyPublisher<Bookmark, Error> {
        legacyPublisher { try await self(name: name) }
    }
}

extension DeleteBookmarksCategoryUseCase {
    func callAsFunction(id: Int) -> AnyPublisher<Bool, Error> {
        legacyPublisher { try await self(id: id) }
    }
}

extension GetBookmarksByCategoryAddedUseCase {
    func callAsFunction(id: Int, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(id: id, genre: genre, page: page) }
    }
}

extension GetBookmarksByCategoryPopularUseCase {
    func callAsFunction(id: Int, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(id: id, genre: genre, page: page) }
    }
}

extension GetBookmarksByCategoryYearUseCase {
    func callAsFunction(id: Int, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(id: id, genre: genre, page: page) }
    }
}

extension GetBookmarksUseCase {
    func callAsFunction() -> AnyPublisher<[Bookmark], Error> {
        legacyPublisher { try await self() }
    }
}

extension GetSeriesUpdatesUseCase {
    func callAsFunction() -> AnyPublisher<[SeriesUpdateGroup], Error> {
        legacyPublisher { try await self() }
    }
}

extension GetVersionUseCase {
    func callAsFunction() -> AnyPublisher<String, Error> {
        legacyPublisher { try await self() }
    }
}

extension GetWatchingLaterMoviesUseCase {
    func callAsFunction() -> AnyPublisher<[MovieWatchLater], Error> {
        legacyPublisher { try await self() }
    }
}

extension LogoutUseCase {
    func callAsFunction() -> AnyPublisher<Bool, Error> {
        legacyPublisher { try await self() }
    }
}

extension MoveBetweenBookmarksUseCase {
    func callAsFunction(movies: [String], fromBookmarkUserCategory: Int, toBookmarkUserCategory: Int) -> AnyPublisher<Int, Error> {
        legacyPublisher { try await self(movies: movies, fromBookmarkUserCategory: fromBookmarkUserCategory, toBookmarkUserCategory: toBookmarkUserCategory) }
    }
}

extension RemoveFromBookmarksUseCase {
    func callAsFunction(movies: [String], bookmarkUserCategory: Int) -> AnyPublisher<Bool, Error> {
        legacyPublisher { try await self(movies: movies, bookmarkUserCategory: bookmarkUserCategory) }
    }
}

extension RemoveWatchingItemUseCase {
    func callAsFunction(item: MovieWatchLater) -> AnyPublisher<Bool, Error> {
        legacyPublisher { try await self(item: item) }
    }
}

extension ReorderBookmarksCategoriesUseCase {
    func callAsFunction(newOrder: [Bookmark]) -> AnyPublisher<Bool, Error> {
        legacyPublisher { try await self(newOrder: newOrder) }
    }
}

extension RestoreUseCase {
    func callAsFunction(login: String) -> AnyPublisher<String?, Error> {
        legacyPublisher { try await self(login: login) }
    }
}

extension SaveWatchingStateUseCase {
    func callAsFunction(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, position: Int? = nil, total: Int? = nil) -> AnyPublisher<Bool, Error> {
        legacyPublisher { try await self(voiceActing: voiceActing, season: season, episode: episode, position: position, total: total) }
    }
}

extension SignInUseCase {
    func callAsFunction(login: String, password: String) -> AnyPublisher<Void, Error> {
        legacyPublisher { try await self(login: login, password: password) }
    }
}

extension SignUpUseCase {
    func callAsFunction(email: String, login: String, password: String, verifyCode: String, step: Int) -> AnyPublisher<Void, Error> {
        legacyPublisher { try await self(email: email, login: login, password: password, verifyCode: verifyCode, step: step) }
    }
}

extension SwitchWatchedItemUseCase {
    func callAsFunction(item: MovieWatchLater) -> AnyPublisher<Bool, Error> {
        legacyPublisher { try await self(item: item) }
    }
}

extension CallUseCase {
    func callAsFunction<D: Decodable & Sendable>(data: some Encodable & Sendable) -> AnyPublisher<Aria2Response<D>, Error> {
        legacyPublisher { try await self(data: data) }
    }
}

extension MulticallUseCase {
    func callAsFunction<D: Decodable & Sendable>(data: [some Encodable & Sendable]) -> AnyPublisher<[Aria2Response<D>], Error> {
        legacyPublisher { try await self(data: data) }
    }
}

extension GetCollectionsUseCase {
    func callAsFunction(page: Int) -> AnyPublisher<[MoviesCollection], Error> {
        legacyPublisher { try await self(page: page) }
    }
}

extension GetLatestMoviesInCollectionUseCase {
    func callAsFunction(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(collectionId: collectionId, page: page) }
    }
}

extension GetPopularMoviesInCollectionUseCase {
    func callAsFunction(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(collectionId: collectionId, page: page) }
    }
}

extension GetSoonMoviesInCollectionUseCase {
    func callAsFunction(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(collectionId: collectionId, page: page) }
    }
}

extension GetWatchingNowMoviesInCollectionUseCase {
    func callAsFunction(collectionId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(collectionId: collectionId, page: page) }
    }
}

extension DeleteCommentUseCase {
    func callAsFunction(id: String, hash: String) -> AnyPublisher<(Bool, String?), Error> {
        legacyPublisher { try await self(id: id, hash: hash) }
    }
}

extension GetCommentUseCase {
    func callAsFunction(movieId: String, commentId: String) -> AnyPublisher<Comment, Error> {
        legacyPublisher { try await self(movieId: movieId, commentId: commentId) }
    }
}

extension GetCommentsPageUseCase {
    func callAsFunction(movieId: String, page: Int) -> AnyPublisher<[Comment], Error> {
        legacyPublisher { try await self(movieId: movieId, page: page) }
    }
}

extension GetLikesUseCase {
    func callAsFunction(id: String) -> AnyPublisher<[Like], Error> {
        legacyPublisher { try await self(id: id) }
    }
}

extension GetMovieBookmarksUseCase {
    func callAsFunction(movieId: String) -> AnyPublisher<[Bookmark], Error> {
        legacyPublisher { try await self(movieId: movieId) }
    }
}

extension GetMovieDetailsUseCase {
    func callAsFunction(movieId: String) -> AnyPublisher<MovieDetailed, Error> {
        legacyPublisher { try await self(movieId: movieId) }
    }
}

extension GetMovieThumbnailsUseCase {
    func callAsFunction(path: String) -> AnyPublisher<WebVTT, Error> {
        legacyPublisher { try await self(path: path) }
    }
}

extension GetMovieTrailerIdUseCase {
    func callAsFunction(movieId: String) -> AnyPublisher<String, Error> {
        legacyPublisher { try await self(movieId: movieId) }
    }
}

extension GetMovieVideoUseCase {
    func callAsFunction(voiceActing: MovieVoiceActing, season: MovieSeason?, episode: MovieEpisode?, favs: String) -> AnyPublisher<MovieVideo, Error> {
        legacyPublisher { try await self(voiceActing: voiceActing, season: season, episode: episode, favs: favs) }
    }
}

extension GetSeriesSeasonsUseCase {
    func callAsFunction(movieId: String, voiceActing: MovieVoiceActing, favs: String) -> AnyPublisher<[MovieSeason], Error> {
        legacyPublisher { try await self(movieId: movieId, voiceActing: voiceActing, favs: favs) }
    }
}

extension RateUseCase {
    func callAsFunction(id: String, rating: Int) -> AnyPublisher<(Float?, String?)?, Error> {
        legacyPublisher { try await self(id: id, rating: rating) }
    }
}

extension ReportCommentUseCase {
    func callAsFunction(id: String, issue: Int, text: String) -> AnyPublisher<Bool, Error> {
        legacyPublisher { try await self(id: id, issue: issue, text: text) }
    }
}

extension SendCommentUseCase {
    func callAsFunction(id: String?, postId: String, name: String?, text: String, adb: String?, type: String?) -> AnyPublisher<SendCommentResult, Error> {
        legacyPublisher { try await self(id: id, postId: postId, name: name, text: text, adb: adb, type: type) }
    }
}

extension ToggleLikeCommentUseCase {
    func callAsFunction(id: String) -> AnyPublisher<(Int, Bool), Error> {
        legacyPublisher { try await self(id: id) }
    }
}

extension GetHotMoviesUseCase {
    func callAsFunction(genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(genre: genre) }
    }
}

extension GetLatestMoviesByCountryUseCase {
    func callAsFunction(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(countryId: countryId, genre: genre, page: page) }
    }
}

extension GetLatestMoviesByGenreUseCase {
    func callAsFunction(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(genreId: genreId, page: page) }
    }
}

extension GetLatestMoviesUseCase {
    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(page: page, genre: genre) }
    }
}

extension GetLatestNewestMoviesUseCase {
    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(page: page, genre: genre) }
    }
}

extension GetMovieListUseCase {
    func callAsFunction(listId: String, page: Int) -> AnyPublisher<(String, [MovieSimple]), Error> {
        legacyPublisher { try await self(listId: listId, page: page) }
    }
}

extension GetPopularMoviesByCountryUseCase {
    func callAsFunction(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(countryId: countryId, genre: genre, page: page) }
    }
}

extension GetPopularMoviesByGenreUseCase {
    func callAsFunction(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(genreId: genreId, page: page) }
    }
}

extension GetPopularMoviesUseCase {
    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(page: page, genre: genre) }
    }
}

extension GetPopularNewestMoviesUseCase {
    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(page: page, genre: genre) }
    }
}

extension GetSoonMoviesByCountryUseCase {
    func callAsFunction(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(countryId: countryId, genre: genre, page: page) }
    }
}

extension GetSoonMoviesByGenreUseCase {
    func callAsFunction(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(genreId: genreId, page: page) }
    }
}

extension GetSoonMoviesUseCase {
    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(page: page, genre: genre) }
    }
}

extension GetWatchingNowMoviesByCountryUseCase {
    func callAsFunction(countryId: String, genre: Int, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(countryId: countryId, genre: genre, page: page) }
    }
}

extension GetWatchingNowMoviesByGenreUseCase {
    func callAsFunction(genreId: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(genreId: genreId, page: page) }
    }
}

extension GetWatchingNowMoviesUseCase {
    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(page: page, genre: genre) }
    }
}

extension GetWatchingNowNewestMoviesUseCase {
    func callAsFunction(page: Int, genre: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(page: page, genre: genre) }
    }
}

extension GetPersonDetailsUseCase {
    func callAsFunction(id: String) -> AnyPublisher<PersonDetailed, Error> {
        legacyPublisher { try await self(id: id) }
    }
}

extension CategoriesUseCase {
    func callAsFunction() -> AnyPublisher<[MovieType], Error> {
        legacyPublisher { try await self() }
    }
}

extension SearchUseCase {
    func callAsFunction(query: String, page: Int) -> AnyPublisher<[MovieSimple], Error> {
        legacyPublisher { try await self(query: query, page: page) }
    }
}
