import Foundation

struct MovieDetailed: Identifiable, Codable, Hashable {
    let movieId: String
    let nameRussian: String
    let nameOriginal: String?
    let hposter: String
    let poster: String
    let duration: Int?
    let description: String
    let releaseDate: String?
    let countries: [MovieCountry]?
    let ageRestriction: String?
    private(set) var rated: Bool
    private(set) var rating: Float?
    private(set) var votes: String?
    let imdbRating: MovieRating?
    let kpRating: MovieRating?
    let genres: [MovieGenre]?
    let lists: [MovieList]?
    let collections: [MoviesCollection]?
    let slogan: String?
    let schedule: [SeriesScheduleGroup]?
    let franchise: [MovieFranchisePart]?
    let producer: [PersonSimple]?
    let actors: [PersonSimple]?
    let available: Bool
    let comingSoon: Bool
    let favs: String
    let adb: String?
    let type: String?
    let voiceActing: [MovieVoiceActing]?
    let series: Series?
    let voiceActingRating: [MovieVoiceActingRating]?
    let watchAlsoMovies: [MovieSimple]
    let commentsCount: Int
    let id: UUID

    init(movieId: String, nameRussian: String, nameOriginal: String?, hposter: String, poster: String, duration: Int?, description: String, releaseDate: String?, countries: [MovieCountry]?, ageRestriction: String?, rated: Bool, rating: Float? = nil, votes: String? = nil, imdbRating: MovieRating?, kpRating: MovieRating?, genres: [MovieGenre]?, lists: [MovieList]?, collections: [MoviesCollection]?, slogan: String?, schedule: [SeriesScheduleGroup]?, franchise: [MovieFranchisePart]?, producer: [PersonSimple]?, actors: [PersonSimple]?, available: Bool, comingSoon: Bool, favs: String, adb: String?, type: String?, voiceActing: [MovieVoiceActing]?, series: Series?, voiceActingRating: [MovieVoiceActingRating]?, watchAlsoMovies: [MovieSimple], commentsCount: Int, id: UUID = .init()) {
        self.movieId = movieId
        self.nameRussian = nameRussian
        self.nameOriginal = nameOriginal
        self.hposter = hposter
        self.poster = poster
        self.duration = duration
        self.description = description
        self.releaseDate = releaseDate
        self.countries = countries
        self.ageRestriction = ageRestriction
        self.rated = rated
        self.rating = rating
        self.votes = votes
        self.imdbRating = imdbRating
        self.kpRating = kpRating
        self.genres = genres
        self.lists = lists
        self.collections = collections
        self.slogan = slogan
        self.schedule = schedule
        self.franchise = franchise
        self.producer = producer
        self.actors = actors
        self.available = available
        self.comingSoon = comingSoon
        self.favs = favs
        self.adb = adb
        self.type = type
        self.voiceActing = voiceActing
        self.series = series
        self.voiceActingRating = voiceActingRating
        self.watchAlsoMovies = watchAlsoMovies
        self.commentsCount = commentsCount
        self.id = id
    }

    mutating func rate(_ rating: Float? = nil, _ votes: String? = nil) {
        self.rated = true

        if let rating {
            self.rating = rating
        }

        if let votes {
            self.votes = votes
        }
    }
}
