import Factory
import Foundation

extension Container {
    var account: Factory<AccountRepository> { self { AccountRepositoryImpl() }.cached }
    var collections: Factory<CollectionsRepository> { self { CollectionsRepositoryImpl() }.cached }
    var movieDetails: Factory<MovieDetailsRepository> { self { MovieDetailsRepositoryImpl() }.cached }
    var movieLists: Factory<MovieListsRepository> { self { MovieListsRepositoryImpl() }.cached }
    var people: Factory<PeopleRepository> { self { PeopleRepositoryImpl() }.cached }
    var search: Factory<SearchRepository> { self { SearchRepositoryImpl() }.cached }
}
