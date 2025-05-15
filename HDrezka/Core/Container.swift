import Alamofire
import FactoryKit
import Foundation

extension Container {
    var session: Factory<Session> {
        self {
            Session(
                rootQueue: .main,
                startRequestsImmediately: false,
                interceptor: CustomInterceptor(),
                redirectHandler: .modify { task, request, _ in
                    var newRequest = task.originalRequest ?? task.currentRequest ?? request
                    newRequest.url = request.url

                    return newRequest
                },
                eventMonitors: [CustomMonitor()]
            )
        }
        .singleton
    }
}

extension Container {
    var accountRepository: Factory<AccountRepository> { self { AccountRepositoryImpl() }.singleton }
    var collectionsRepository: Factory<CollectionsRepository> { self { CollectionsRepositoryImpl() }.singleton }
    var movieDetailsRepository: Factory<MovieDetailsRepository> { self { MovieDetailsRepositoryImpl() }.singleton }
    var movieListsRepository: Factory<MovieListsRepository> { self { MovieListsRepositoryImpl() }.singleton }
    var peopleRepository: Factory<PeopleRepository> { self { PeopleRepositoryImpl() }.singleton }
    var searchRepository: Factory<SearchRepository> { self { SearchRepositoryImpl() }.singleton }
}

extension Container {
    var addToBookmarksUseCase: Factory<AddToBookmarksUseCase> { self { AddToBookmarksUseCase(repository: self.accountRepository()) }.singleton }
    var changeBookmarksCategoryNameUseCase: Factory<ChangeBookmarksCategoryNameUseCase> { self { ChangeBookmarksCategoryNameUseCase(repository: self.accountRepository()) }.singleton }
    var checkEmailUseCase: Factory<CheckEmailUseCase> { self { CheckEmailUseCase(repository: self.accountRepository()) }.singleton }
    var checkUsernameUseCase: Factory<CheckUsernameUseCase> { self { CheckUsernameUseCase(repository: self.accountRepository()) }.singleton }
    var createBookmarksCategoryUseCase: Factory<CreateBookmarksCategoryUseCase> { self { CreateBookmarksCategoryUseCase(repository: self.accountRepository()) }.singleton }
    var deleteBookmarksCategoryUseCase: Factory<DeleteBookmarksCategoryUseCase> { self { DeleteBookmarksCategoryUseCase(repository: self.accountRepository()) }.singleton }
    var getBookmarksByCategoryAddedUseCase: Factory<GetBookmarksByCategoryAddedUseCase> { self { GetBookmarksByCategoryAddedUseCase(repository: self.accountRepository()) }.singleton }
    var getBookmarksByCategoryPopularUseCase: Factory<GetBookmarksByCategoryPopularUseCase> { self { GetBookmarksByCategoryPopularUseCase(repository: self.accountRepository()) }.singleton }
    var getBookmarksByCategoryYearUseCase: Factory<GetBookmarksByCategoryYearUseCase> { self { GetBookmarksByCategoryYearUseCase(repository: self.accountRepository()) }.singleton }
    var getBookmarksUseCase: Factory<GetBookmarksUseCase> { self { GetBookmarksUseCase(repository: self.accountRepository()) }.singleton }
    var getSeriesUpdatesUseCase: Factory<GetSeriesUpdatesUseCase> { self { GetSeriesUpdatesUseCase(repository: self.accountRepository()) }.singleton }
    var getVersionUseCase: Factory<GetVersionUseCase> { self { GetVersionUseCase(repository: self.accountRepository()) }.singleton }
    var getWatchingLaterMoviesUseCase: Factory<GetWatchingLaterMoviesUseCase> { self { GetWatchingLaterMoviesUseCase(repository: self.accountRepository()) }.singleton }
    var logoutUseCase: Factory<LogoutUseCase> { self { LogoutUseCase(repository: self.accountRepository()) }.singleton }
    var moveBetweenBookmarksUseCase: Factory<MoveBetweenBookmarksUseCase> { self { MoveBetweenBookmarksUseCase(repository: self.accountRepository()) }.singleton }
    var removeFromBookmarksUseCase: Factory<RemoveFromBookmarksUseCase> { self { RemoveFromBookmarksUseCase(repository: self.accountRepository()) }.singleton }
    var removeWatchingItemUseCase: Factory<RemoveWatchingItemUseCase> { self { RemoveWatchingItemUseCase(repository: self.accountRepository()) }.singleton }
    var reorderBookmarksCategoriesUseCase: Factory<ReorderBookmarksCategoriesUseCase> { self { ReorderBookmarksCategoriesUseCase(repository: self.accountRepository()) }.singleton }
    var restoreUseCase: Factory<RestoreUseCase> { self { RestoreUseCase(repository: self.accountRepository()) }.singleton }
    var saveWatchingStateUseCase: Factory<SaveWatchingStateUseCase> { self { SaveWatchingStateUseCase(repository: self.accountRepository()) }.singleton }
    var signInUseCase: Factory<SignInUseCase> { self { SignInUseCase(repository: self.accountRepository()) }.singleton }
    var signUpUseCase: Factory<SignUpUseCase> { self { SignUpUseCase(repository: self.accountRepository()) }.singleton }
    var switchWatchedItemUseCase: Factory<SwitchWatchedItemUseCase> { self { SwitchWatchedItemUseCase(repository: self.accountRepository()) }.singleton }
}

extension Container {
    var getCollectionsUseCase: Factory<GetCollectionsUseCase> { self { GetCollectionsUseCase(repository: self.collectionsRepository()) }.singleton }
    var getLatestMoviesInCollectionUseCase: Factory<GetLatestMoviesInCollectionUseCase> { self { GetLatestMoviesInCollectionUseCase(repository: self.collectionsRepository()) }.singleton }
    var getPopularMoviesInCollectionUseCase: Factory<GetPopularMoviesInCollectionUseCase> { self { GetPopularMoviesInCollectionUseCase(repository: self.collectionsRepository()) }.singleton }
    var getSoonMoviesInCollectionUseCase: Factory<GetSoonMoviesInCollectionUseCase> { self { GetSoonMoviesInCollectionUseCase(repository: self.collectionsRepository()) }.singleton }
    var getWatchingNowMoviesInCollectionUseCase: Factory<GetWatchingNowMoviesInCollectionUseCase> { self { GetWatchingNowMoviesInCollectionUseCase(repository: self.collectionsRepository()) }.singleton }
}

extension Container {
    var deleteCommentUseCase: Factory<DeleteCommentUseCase> { self { DeleteCommentUseCase(repository: self.movieDetailsRepository()) }.singleton }
    var getCommentsPageUseCase: Factory<GetCommentsPageUseCase> { self { GetCommentsPageUseCase(repository: self.movieDetailsRepository()) }.singleton }
    var getCommentUseCase: Factory<GetCommentUseCase> { self { GetCommentUseCase(repository: self.movieDetailsRepository()) }.singleton }
    var getLikesUseCase: Factory<GetLikesUseCase> { self { GetLikesUseCase(repository: self.movieDetailsRepository()) }.singleton }
    var getMovieBookmarksUseCase: Factory<GetMovieBookmarksUseCase> { self { GetMovieBookmarksUseCase(repository: self.movieDetailsRepository()) }.singleton }
    var getMovieDetailsUseCase: Factory<GetMovieDetailsUseCase> { self { GetMovieDetailsUseCase(repository: self.movieDetailsRepository()) }.singleton }
    var getMovieThumbnailsUseCase: Factory<GetMovieThumbnailsUseCase> { self { GetMovieThumbnailsUseCase(repository: self.movieDetailsRepository()) }.singleton }
    var getMovieTrailerIdUseCase: Factory<GetMovieTrailerIdUseCase> { self { GetMovieTrailerIdUseCase(repository: self.movieDetailsRepository()) }.singleton }
    var getMovieVideoUseCase: Factory<GetMovieVideoUseCase> { self { GetMovieVideoUseCase(repository: self.movieDetailsRepository()) }.singleton }
    var getSeriesSeasonsUseCase: Factory<GetSeriesSeasonsUseCase> { self { GetSeriesSeasonsUseCase(repository: self.movieDetailsRepository()) }.singleton }
    var rateUseCase: Factory<RateUseCase> { self { RateUseCase(repository: self.movieDetailsRepository()) }.singleton }
    var reportCommentUseCase: Factory<ReportCommentUseCase> { self { ReportCommentUseCase(repository: self.movieDetailsRepository()) }.singleton }
    var sendCommentUseCase: Factory<SendCommentUseCase> { self { SendCommentUseCase(repository: self.movieDetailsRepository()) }.singleton }
    var toggleLikeCommentUseCase: Factory<ToggleLikeCommentUseCase> { self { ToggleLikeCommentUseCase(repository: self.movieDetailsRepository()) }.singleton }
}

extension Container {
    var getFeaturedMoviesUseCase: Factory<GetFeaturedMoviesUseCase> { self { GetFeaturedMoviesUseCase(repository: self.movieListsRepository()) }.singleton }
    var getHotMoviesUseCase: Factory<GetHotMoviesUseCase> { self { GetHotMoviesUseCase(repository: self.movieListsRepository()) }.singleton }
    var getLatestMoviesByCountryUseCase: Factory<GetLatestMoviesByCountryUseCase> { self { GetLatestMoviesByCountryUseCase(repository: self.movieListsRepository()) }.singleton }
    var getLatestMoviesByGenreUseCase: Factory<GetLatestMoviesByGenreUseCase> { self { GetLatestMoviesByGenreUseCase(repository: self.movieListsRepository()) }.singleton }
    var getLatestMoviesUseCase: Factory<GetLatestMoviesUseCase> { self { GetLatestMoviesUseCase(repository: self.movieListsRepository()) }.singleton }
    var getLatestNewestMoviesUseCase: Factory<GetLatestNewestMoviesUseCase> { self { GetLatestNewestMoviesUseCase(repository: self.movieListsRepository()) }.singleton }
    var getMovieListUseCase: Factory<GetMovieListUseCase> { self { GetMovieListUseCase(repository: self.movieListsRepository()) }.singleton }
    var getPopularMoviesByCountryUseCase: Factory<GetPopularMoviesByCountryUseCase> { self { GetPopularMoviesByCountryUseCase(repository: self.movieListsRepository()) }.singleton }
    var getPopularMoviesByGenreUseCase: Factory<GetPopularMoviesByGenreUseCase> { self { GetPopularMoviesByGenreUseCase(repository: self.movieListsRepository()) }.singleton }
    var getPopularMoviesUseCase: Factory<GetPopularMoviesUseCase> { self { GetPopularMoviesUseCase(repository: self.movieListsRepository()) }.singleton }
    var getPopularNewestMoviesUseCase: Factory<GetPopularNewestMoviesUseCase> { self { GetPopularNewestMoviesUseCase(repository: self.movieListsRepository()) }.singleton }
    var getSoonMoviesByCountryUseCase: Factory<GetSoonMoviesByCountryUseCase> { self { GetSoonMoviesByCountryUseCase(repository: self.movieListsRepository()) }.singleton }
    var getSoonMoviesByGenreUseCase: Factory<GetSoonMoviesByGenreUseCase> { self { GetSoonMoviesByGenreUseCase(repository: self.movieListsRepository()) }.singleton }
    var getSoonMoviesUseCase: Factory<GetSoonMoviesUseCase> { self { GetSoonMoviesUseCase(repository: self.movieListsRepository()) }.singleton }
    var getWatchingNowMoviesByCountryUseCase: Factory<GetWatchingNowMoviesByCountryUseCase> { self { GetWatchingNowMoviesByCountryUseCase(repository: self.movieListsRepository()) }.singleton }
    var getWatchingNowMoviesByGenreUseCase: Factory<GetWatchingNowMoviesByGenreUseCase> { self { GetWatchingNowMoviesByGenreUseCase(repository: self.movieListsRepository()) }.singleton }
    var getWatchingNowMoviesUseCase: Factory<GetWatchingNowMoviesUseCase> { self { GetWatchingNowMoviesUseCase(repository: self.movieListsRepository()) }.singleton }
    var getWatchingNowNewestMoviesUseCase: Factory<GetWatchingNowNewestMoviesUseCase> { self { GetWatchingNowNewestMoviesUseCase(repository: self.movieListsRepository()) }.singleton }
}

extension Container {
    var getPersonDetailsUseCase: Factory<GetPersonDetailsUseCase> { self { GetPersonDetailsUseCase(repository: self.peopleRepository()) }.singleton }
}

extension Container {
    var categoriesUseCase: Factory<CategoriesUseCase> { self { CategoriesUseCase(repository: self.searchRepository()) }.singleton }
    var searchUseCase: Factory<SearchUseCase> { self { SearchUseCase(repository: self.searchRepository()) }.singleton }
}
