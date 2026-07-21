import Kingfisher
import SwiftUI

struct PersonDetailsView: View {
    private let details: PersonDetailed

    @Environment(\.openWindow) private var openWindow
    @Environment(\.dismissWindow) private var dismissWindow

    init(details: PersonDetailed) {
        self.details = details
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 27) {
            Button {
                if let url = URL(string: details.hphoto) ?? URL(string: details.photo) {
                    dismissWindow(id: "imageViewer")

                    openWindow(id: "imageViewer", value: url)
                }
            } label: {
                KFImage
                    .url(URL(string: details.hphoto))
                    .placeholder {
                        KFImage
                            .url(URL(string: details.photo))
                            .placeholder {
                                Color.gray.shimmering()
                            }
                            .resizable()
                            .loadTransition(.blurReplace(.downUp), animation: .bouncy)
                            .cancelOnDisappear(true)
                            .retry(NetworkRetryStrategy())
                    }
                    .resizable()
                    .loadTransition(.blurReplace(.downUp), animation: .bouncy)
                    .cancelOnDisappear(true)
                    .retry(NetworkRetryStrategy())
                    .imageFill(2 / 3)
                    .frame(width: 250)
                    .contentShape(.rect(cornerRadius: 6))
                    .clipShape(.rect(cornerRadius: 6))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(details.nameRu)
                        .font(.largeTitle.weight(.semibold))
                        .textSelection(.enabled)

                    if let nameOriginal = details.nameOrig {
                        Text(nameOriginal)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                    }
                }

                if details.career?.isEmpty == false
                    ||
                    details.birthDate?.isEmpty == false
                    ||
                    details.birthPlace?.isEmpty == false
                    ||
                    details.deathDate?.isEmpty == false
                    ||
                    details.deathPlace?.isEmpty == false
                    ||
                    details.height?.isEmpty == false
                {
                    VStack(alignment: .leading, spacing: 0) {
                        if let career = details.career, !career.isEmpty {
                            PersonInfoRowView(String(localized: "key.person.career"), career)
                        }

                        if let height = details.height, !height.isEmpty {
                            if details.career?.isEmpty == false {
                                Divider()
                            }

                            PersonInfoRowView(String(localized: "key.person.height"), height)
                        }

                        if let birthDate = details.birthDate, !birthDate.isEmpty {
                            if details.career?.isEmpty == false || details.height?.isEmpty == false {
                                Divider()
                            }

                            PersonInfoRowView(String(localized: "key.person.birth_date"), birthDate)
                        }

                        if let birthPlace = details.birthPlace, !birthPlace.isEmpty {
                            if details.career?.isEmpty == false || details.birthDate?.isEmpty == false || details.height?.isEmpty == false {
                                Divider()
                            }

                            PersonInfoRowView(String(localized: "key.person.birth_place"), birthPlace)
                        }

                        if let deathDate = details.deathDate, !deathDate.isEmpty {
                            if details.career?.isEmpty == false || details.birthDate?.isEmpty == false || details.birthPlace?.isEmpty == false || details.height?.isEmpty == false {
                                Divider()
                            }

                            PersonInfoRowView(String(localized: "key.person.death_date"), deathDate)
                        }

                        if let deathPlace = details.deathPlace, !deathPlace.isEmpty {
                            if details.career?.isEmpty == false || details.birthDate?.isEmpty == false || details.birthPlace?.isEmpty == false || details.deathDate?.isEmpty == false || details.height?.isEmpty == false {
                                Divider()
                            }

                            PersonInfoRowView(String(localized: "key.person.death_place"), deathPlace)
                        }
                    }
                    .padding(.horizontal, 10)
                    .background(.quinary, in: .rect(cornerRadius: 6))
                    .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                }
            }
        }
        .padding(.horizontal, 36)

        if let actorMovies = details.actorMovies, !actorMovies.isEmpty {
            Divider()
                .padding(.horizontal, 36)

            PersonMoviesRowView(String(localized: "key.person.actor"), actorMovies)
        }

        if let actressMovies = details.actressMovies, !actressMovies.isEmpty {
            Divider()
                .padding(.horizontal, 36)

            PersonMoviesRowView(String(localized: "key.person.actress"), actressMovies)
        }

        if let artistMovies = details.artistMovies, !artistMovies.isEmpty {
            Divider()
                .padding(.horizontal, 36)

            PersonMoviesRowView(String(localized: "key.person.artist"), artistMovies)
        }

        if let directorMovies = details.directorMovies, !directorMovies.isEmpty {
            Divider()
                .padding(.horizontal, 36)

            PersonMoviesRowView(String(localized: "key.person.director"), directorMovies)
        }

        if let editorMovies = details.editorMovies, !editorMovies.isEmpty {
            Divider()
                .padding(.horizontal, 36)

            PersonMoviesRowView(String(localized: "key.person.editor"), editorMovies)
        }

        if let operatorMovies = details.operatorMovies, !operatorMovies.isEmpty {
            Divider()
                .padding(.horizontal, 36)

            PersonMoviesRowView(String(localized: "key.person.operator"), operatorMovies)
        }

        if let producerMovies = details.producerMovies, !producerMovies.isEmpty {
            Divider()
                .padding(.horizontal, 36)

            PersonMoviesRowView(String(localized: "key.person.producer"), producerMovies)
        }

        if let screenwriterMovies = details.screenwriterMovies, !screenwriterMovies.isEmpty {
            Divider()
                .padding(.horizontal, 36)

            PersonMoviesRowView(String(localized: "key.person.screenwriter"), screenwriterMovies)
        }

        if let composerMovies = details.composerMovies, !composerMovies.isEmpty {
            Divider()
                .padding(.horizontal, 36)

            PersonMoviesRowView(String(localized: "key.person.composer"), composerMovies)
        }
    }
}
