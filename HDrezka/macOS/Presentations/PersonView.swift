import Defaults
import Kingfisher
import SwiftUI

struct PersonView: View {
    private let title: String

    @State private var viewModel: PersonViewModel

    init(person: PersonSimple) {
        title = person.name
        viewModel = PersonViewModel(id: person.personId)
    }

    @Default(.mirror) private var mirror

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 18) {
                if let details = viewModel.state.data {
                    PersonViewComponent(details: details)
                }
            }
            .padding(.vertical, 18)
        }
        .scrollIndicators(.visible, axes: .vertical)
        .viewModifier { view in
            if #available(macOS 26, *) {
                view.scrollEdgeEffectStyle(.soft, for: .all)
            } else {
                view
            }
        }
        .overlay {
            if let error = viewModel.state.error {
                ErrorStateView(error) {
                    viewModel.load()
                }
                .padding(.vertical, 18)
                .padding(.horizontal, 36)
            } else if viewModel.state == .loading {
                LoadingStateView()
                    .padding(.vertical, 18)
                    .padding(.horizontal, 36)
            }
        }
        .transition(.opacity)
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Button {
                    viewModel.load()
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .keyboardShortcut("r", modifiers: .command)
                .disabled(viewModel.state.data == nil)
            }

            ToolbarItem(placement: .primaryAction) {
                ShareLink(item: (mirror != _mirror.defaultValue ? mirror : Const.redirectMirror).appending(path: viewModel.id, directoryHint: .notDirectory)) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(viewModel.state.data == nil)
            }
        }
        .onAppear {
            switch viewModel.state {
            case .data:
                break
            default:
                viewModel.load()
            }
        }
        .background(.background)
    }

    private struct PersonViewComponent: View {
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
                                .loadTransition(.blurReplace, animation: .easeInOut)
                                .cancelOnDisappear(true)
                        }
                        .resizable()
                        .loadTransition(.blurReplace, animation: .easeInOut)
                        .cancelOnDisappear(true)
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
                                InfoRow(String(localized: "key.person.career"), career)
                            }

                            if let height = details.height, !height.isEmpty {
                                if details.career?.isEmpty == false {
                                    Divider()
                                }

                                InfoRow(String(localized: "key.person.height"), height)
                            }

                            if let birthDate = details.birthDate, !birthDate.isEmpty {
                                if details.career?.isEmpty == false || details.height?.isEmpty == false {
                                    Divider()
                                }

                                InfoRow(String(localized: "key.person.birth_date"), birthDate)
                            }

                            if let birthPlace = details.birthPlace, !birthPlace.isEmpty {
                                if details.career?.isEmpty == false || details.birthDate?.isEmpty == false || details.height?.isEmpty == false {
                                    Divider()
                                }

                                InfoRow(String(localized: "key.person.birth_place"), birthPlace)
                            }

                            if let deathDate = details.deathDate, !deathDate.isEmpty {
                                if details.career?.isEmpty == false || details.birthDate?.isEmpty == false || details.birthPlace?.isEmpty == false || details.height?.isEmpty == false {
                                    Divider()
                                }

                                InfoRow(String(localized: "key.person.death_date"), deathDate)
                            }

                            if let deathPlace = details.deathPlace, !deathPlace.isEmpty {
                                if details.career?.isEmpty == false || details.birthDate?.isEmpty == false || details.birthPlace?.isEmpty == false || details.deathDate?.isEmpty == false || details.height?.isEmpty == false {
                                    Divider()
                                }

                                InfoRow(String(localized: "key.person.death_place"), deathPlace)
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

                MoviesRow(String(localized: "key.person.actor"), actorMovies)
            }

            if let actressMovies = details.actressMovies, !actressMovies.isEmpty {
                Divider()
                    .padding(.horizontal, 36)

                MoviesRow(String(localized: "key.person.actress"), actressMovies)
            }

            if let artistMovies = details.artistMovies, !artistMovies.isEmpty {
                Divider()
                    .padding(.horizontal, 36)

                MoviesRow(String(localized: "key.person.artist"), artistMovies)
            }

            if let directorMovies = details.directorMovies, !directorMovies.isEmpty {
                Divider()
                    .padding(.horizontal, 36)

                MoviesRow(String(localized: "key.person.director"), directorMovies)
            }

            if let editorMovies = details.editorMovies, !editorMovies.isEmpty {
                Divider()
                    .padding(.horizontal, 36)

                MoviesRow(String(localized: "key.person.editor"), editorMovies)
            }

            if let operatorMovies = details.operatorMovies, !operatorMovies.isEmpty {
                Divider()
                    .padding(.horizontal, 36)

                MoviesRow(String(localized: "key.person.operator"), operatorMovies)
            }

            if let producerMovies = details.producerMovies, !producerMovies.isEmpty {
                Divider()
                    .padding(.horizontal, 36)

                MoviesRow(String(localized: "key.person.producer"), producerMovies)
            }

            if let screenwriterMovies = details.screenwriterMovies, !screenwriterMovies.isEmpty {
                Divider()
                    .padding(.horizontal, 36)

                MoviesRow(String(localized: "key.person.screenwriter"), screenwriterMovies)
            }

            if let composerMovies = details.composerMovies, !composerMovies.isEmpty {
                Divider()
                    .padding(.horizontal, 36)

                MoviesRow(String(localized: "key.person.composer"), composerMovies)
            }
        }
    }

    private struct InfoRow: View {
        private let title: String
        private let info: String

        init(_ title: String, _ info: String) {
            self.title = title
            self.info = info
        }

        var body: some View {
            HStack(alignment: .center) {
                Text(title)
                    .font(.body)

                Spacer()

                Text(info)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(.vertical, 8)
        }
    }

    private struct MoviesRow: View {
        private let title: String
        private let movies: [MovieSimple]

        init(_ title: String, _ movies: [MovieSimple]) {
            self.title = title
            self.movies = movies
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 18) {
                HStack(alignment: .center, spacing: 9) {
                    Text(title).font(.title.bold())

                    Spacer()

                    if movies.count > 10 {
                        NavigationLink(value: Destinations.customList(movies, title)) {
                            HStack(alignment: .center) {
                                Text("key.see_all")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.accentColor)

                                Image(systemName: "chevron.right")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .buttonStyle(.accessoryBar)
                    }
                }
                .padding(.horizontal, 36)

                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 18) {
                        ForEach(movies.prefix(10)) { movie in
                            CardView(movie: movie, reservesSpace: true)
                                .frame(width: 150)
                        }
                    }
                    .padding(.horizontal, 36)
                }
                .scrollIndicators(.never)
            }
        }
    }
}
