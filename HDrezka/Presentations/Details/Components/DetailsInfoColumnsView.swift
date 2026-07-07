import SwiftUI

struct DetailsInfoColumnsView: View {
    private let details: MovieDetailed

    init(details: MovieDetailed) {
        self.details = details
    }

    var body: some View {
        if details.imdbRating != nil
            ||
            details.kpRating != nil
            ||
            details.waRating != nil
            ||
            details.duration != nil
            ||
            details.ageRestriction != nil
        {
            HStack(alignment: .center) {
                if let imdbRating = details.imdbRating {
                    let color = Color.red.mix(with: .green, by: Double(imdbRating.value / 10.0))

                    DetailsInfoColumnView("IMDb", imdbRating.value.description, DetailsStarsView(rating: imdbRating.value * 0.5, color: color), valueColor: color, hover: imdbRating.votesCount, url: URL(string: imdbRating.link))
                }

                if let kpRating = details.kpRating {
                    let color = Color.red.mix(with: .green, by: Double(kpRating.value / 10.0))

                    DetailsInfoColumnView("КиноПоиск", kpRating.value.description, DetailsStarsView(rating: kpRating.value * 0.5, color: color), valueColor: color, hover: kpRating.votesCount, url: URL(string: kpRating.link))
                }

                if let waRating = details.waRating {
                    let color = Color.red.mix(with: .green, by: Double(waRating.value / 10.0))

                    DetailsInfoColumnView("World Art", waRating.value.description, DetailsStarsView(rating: waRating.value * 0.5, color: color), valueColor: color, hover: waRating.votesCount, url: URL(string: waRating.link))
                }

                if let duration = details.duration, duration > 0 {
                    DetailsInfoColumnView(String(localized: "key.info.duration"), duration.description, Text(String(localized: "key.info.minutes-\(duration)").trimmingCharacters(in: .letters.inverted).lowercased()).font(.body.weight(.medium)))
                }

                if let ageRestriction = details.ageRestriction, !ageRestriction.isEmpty {
                    DetailsInfoColumnView(String(localized: "key.info.age"), ageRestriction, Text(String(localized: "key.info.years_old").lowercased()).font(.body.weight(.medium)))
                }
            }

            Divider()
        }
    }
}
