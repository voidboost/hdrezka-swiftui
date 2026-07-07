import SwiftUI

struct DetailsInfoRowsView: View {
    private let details: MovieDetailed

    init(details: MovieDetailed) {
        self.details = details
    }

    var body: some View {
        if details.slogan?.isEmpty == false
            ||
            details.releaseDate?.isEmpty == false
            ||
            details.year?.isEmpty == false
            ||
            details.countries?.isEmpty == false
            ||
            details.genres?.isEmpty == false
            ||
            details.producer?.isEmpty == false
            ||
            details.actors?.isEmpty == false
            ||
            details.lists?.isEmpty == false
            ||
            details.collections?.isEmpty == false
            ||
            details.rating != nil
        {
            VStack(alignment: .leading, spacing: 0) {
                if let slogan = details.slogan, !slogan.isEmpty {
                    DetailsInfoRowView(String(localized: "key.info.slogan"), slogan)
                }

                if let releaseDate = details.releaseDate, !releaseDate.isEmpty {
                    if details.slogan?.isEmpty == false {
                        Divider()
                    }

                    DetailsInfoRowView(String(localized: "key.info.date"), releaseDate)
                }

                if let year = details.year, !year.isEmpty {
                    if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false {
                        Divider()
                    }

                    DetailsInfoRowView(String(localized: "key.info.year"), year)
                }

                if let countries = details.countries, !countries.isEmpty {
                    if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.year?.isEmpty == false {
                        Divider()
                    }

                    DetailsInfoRowWithButtonsView(
                        String(localized: "key.info.country"),
                        String(localized: "key.info.country.description"),
                        countries
                    )
                }

                if let genres = details.genres, !genres.isEmpty {
                    if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.year?.isEmpty == false || details.countries?.isEmpty == false {
                        Divider()
                    }

                    DetailsInfoRowWithButtonsView(
                        String(localized: "key.info.genres"),
                        String(localized: "key.info.genres.description"),
                        genres
                    )
                }

                if let producer = details.producer, !producer.isEmpty {
                    if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.year?.isEmpty == false || details.countries?.isEmpty == false || details.genres?.isEmpty == false {
                        Divider()
                    }

                    DetailsInfoRowWithButtonsView(
                        String(localized: "key.info.producer"),
                        String(localized: "key.info.producer.description"),
                        producer
                    )
                }

                if let actors = details.actors, !actors.isEmpty {
                    if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.year?.isEmpty == false || details.countries?.isEmpty == false || details.genres?.isEmpty == false || details.producer?.isEmpty == false {
                        Divider()
                    }

                    DetailsInfoRowWithButtonsView(
                        String(localized: "key.info.actors"),
                        String(localized: "key.info.actors.description"),
                        actors
                    )
                }

                if let lists = details.lists, !lists.isEmpty {
                    if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.year?.isEmpty == false || details.countries?.isEmpty == false || details.genres?.isEmpty == false || details.producer?.isEmpty == false || details.actors?.isEmpty == false {
                        Divider()
                    }

                    DetailsInfoRowWithButtonsView(
                        String(localized: "key.info.lists"),
                        String(localized: "key.info.lists.description"),
                        lists
                    )
                }

                if let collections = details.collections, !collections.isEmpty {
                    if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.year?.isEmpty == false || details.countries?.isEmpty == false || details.genres?.isEmpty == false || details.producer?.isEmpty == false || details.actors?.isEmpty == false || details.lists?.isEmpty == false {
                        Divider()
                    }

                    DetailsInfoRowWithButtonsView(
                        String(localized: "key.info.collections"),
                        String(localized: "key.info.collections.description"),
                        collections
                    )
                }

                if let rating = details.rating {
                    if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.year?.isEmpty == false || details.countries?.isEmpty == false || details.genres?.isEmpty == false || details.producer?.isEmpty == false || details.actors?.isEmpty == false || details.lists?.isEmpty == false || details.collections?.isEmpty == false {
                        Divider()
                    }

                    DetailsInfoRowRatingView(String(localized: "key.info.rating"), rating, details.rated, details.votes)
                }
            }
            .padding(.horizontal, 10)
            .background(.quinary, in: .rect(cornerRadius: 6))
            .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
        }
    }
}
