import Defaults
import Kingfisher
import SwiftUI
import YouTubePlayerKit

struct DetailsView: View {
    private let title: String?

    @State private var viewModel: DetailsViewModel

    init(movie: MovieSimple) {
        title = movie.name
        viewModel = DetailsViewModel(id: movie.movieId)
    }

    @State private var isBookmarksPresented = false
    @State private var isCreateBookmarkPresented = false
    @State private var isSchedulePresented = false

    @Default(.isLoggedIn) private var isLoggedIn
    @Default(.mirror) private var mirror

    @State private var topSafeAreaInset: CGFloat = .zero

    @State private var countryDestination: MovieCountry?
    @State private var genreDestination: MovieGenre?
    @State private var personDestination: PersonSimple?
    @State private var listDestination: MovieList?
    @State private var collectionDestination: MoviesCollection?

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 18) {
                if let details = viewModel.state.data {
                    DetailsViewComponent(
                        details: details,
                        trailerId: viewModel.trailerId,
                        topSafeAreaInset: topSafeAreaInset,
                        isSchedulePresented: $isSchedulePresented,
                        countryDestination: $countryDestination,
                        genreDestination: $genreDestination,
                        personDestination: $personDestination,
                        listDestination: $listDestination,
                        collectionDestination: $collectionDestination,
                    )
                    .environment(viewModel)
                }
            }
        }
        .scrollIndicators(.visible, axes: .vertical)
        .viewModifier { view in
            if #available(macOS 26, *) {
                view.scrollEdgeEffectStyle(.soft, for: .all)
            } else {
                view
            }
        }
        .ignoresSafeArea(edges: .top)
        .contentMargins(.top, topSafeAreaInset, for: .scrollIndicators)
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
        .navigationTitle(viewModel.state.data?.nameRussian ?? title ?? "")
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

            ToolbarItemGroup(placement: .primaryAction) {
                if let details = viewModel.state.data {
                    NavigationLink(value: Destinations.comments(details)) {
                        HStack(alignment: .center, spacing: 4) {
                            Image(systemName: "bubble.left.and.bubble.right")

                            if let details = viewModel.state.data, details.commentsCount > 0 {
                                Text(verbatim: "(\(details.commentsCount))")
                            }
                        }
                    }
                }

                if isLoggedIn {
                    Button {
                        isBookmarksPresented = true
                    } label: {
                        Image(systemName: "bookmark")
                    }
                    .disabled(viewModel.state.data == nil)
                }

                ShareLink(item: (mirror != _mirror.defaultValue ? mirror : Const.redirectMirror).appending(path: viewModel.id, directoryHint: .notDirectory)) {
                    Image(systemName: "square.and.arrow.up")
                }
                .disabled(viewModel.state.data == nil)
            }
        }
        .onGeometryChange(for: CGFloat.self) { geometry in
            geometry.safeAreaInsets.top
        } action: { inset in
            topSafeAreaInset = inset
        }
        .onAppear {
            switch viewModel.state {
            case .data:
                break
            default:
                viewModel.load()
            }
        }
        .sheet(isPresented: $isBookmarksPresented) {
            BookmarksSheetView(id: viewModel.id, isCreateBookmarkPresented: $isCreateBookmarkPresented)
        }
        .sheet(isPresented: $isCreateBookmarkPresented) {
            CreateBookmarkSheetView()
        }
        .sheet(isPresented: $isSchedulePresented) {
            if let details = viewModel.state.data, let schedule = details.schedule, !schedule.isEmpty {
                ScheduleSheetView(schedule: schedule)
            }
        }
        .alert("key.ops", isPresented: $viewModel.isErrorPresented) {
            Button(role: .cancel) {} label: {
                Text("key.ok")
            }
        } message: {
            if let error = viewModel.error {
                Text(error.localizedDescription)
            }
        }
        .dialogSeverity(.critical)
        .onChange(of: isCreateBookmarkPresented) {
            isBookmarksPresented = !isCreateBookmarkPresented
        }
        .background(.background)
        .navigationDestination(item: $countryDestination) {
            ListView(country: $0)
        }
        .navigationDestination(item: $genreDestination) {
            ListView(genre: $0)
        }
        .navigationDestination(item: $personDestination) {
            PersonView(person: $0)
        }
        .navigationDestination(item: $listDestination) {
            ListView(list: $0)
        }
        .navigationDestination(item: $collectionDestination) {
            ListView(collection: $0)
        }
    }

    private struct DetailsViewComponent: View {
        private let details: MovieDetailed
        private let trailerId: String?
        private let topSafeAreaInset: CGFloat
        @Binding private var isSchedulePresented: Bool

        @Environment(Downloader.self) private var downloader

        @Binding private var countryDestination: MovieCountry?
        @Binding private var genreDestination: MovieGenre?
        @Binding private var personDestination: PersonSimple?
        @Binding private var listDestination: MovieList?
        @Binding private var collectionDestination: MoviesCollection?

        init(details: MovieDetailed,
             trailerId: String?,
             topSafeAreaInset: CGFloat,
             isSchedulePresented: Binding<Bool>,
             countryDestination: Binding<MovieCountry?>,
             genreDestination: Binding<MovieGenre?>,
             personDestination: Binding<PersonSimple?>,
             listDestination: Binding<MovieList?>,
             collectionDestination: Binding<MoviesCollection?>)
        {
            self.details = details
            self.trailerId = trailerId
            self.topSafeAreaInset = topSafeAreaInset
            _isSchedulePresented = isSchedulePresented
            _countryDestination = countryDestination
            _genreDestination = genreDestination
            _personDestination = personDestination
            _listDestination = listDestination
            _collectionDestination = collectionDestination
        }

        @State private var isPlayPresented: Bool = false
        @State private var isDownloadPresented: Bool = false
        @State private var isOpenExternalPlayerPresented: Bool = false

        @State private var franchiseExpanded: Bool = false

        @State private var blurHeght: CGFloat = .zero

        @Environment(\.colorScheme) private var colorScheme
        @Environment(\.openWindow) private var openWindow
        @Environment(\.openURL) private var openURL
        @Environment(\.dismissWindow) private var dismissWindow

        var body: some View {
            VStack(spacing: 18) {
                VStack(spacing: 18) {
                    HStack(alignment: .bottom, spacing: 27) {
                        Button {
                            if let url = URL(string: details.hposter) ?? URL(string: details.poster) {
                                dismissWindow(id: "imageViewer")

                                openWindow(id: "imageViewer", value: url)
                            }
                        } label: {
                            KFImage
                                .url(URL(string: details.hposter))
                                .placeholder {
                                    KFImage
                                        .url(URL(string: details.poster))
                                        .placeholder {
                                            Color.gray.shimmering()
                                        }
                                        .resizable()
                                        .loadTransition(.blurReplace, animation: .easeInOut)
                                        .cancelOnDisappear(true)
                                        .retry(NetworkRetryStrategy())
                                }
                                .resizable()
                                .loadTransition(.blurReplace, animation: .easeInOut)
                                .cancelOnDisappear(true)
                                .retry(NetworkRetryStrategy())
                                .imageFill(2 / 3)
                                .frame(width: 300)
                                .contentShape(.rect(cornerRadius: 6))
                                .clipShape(.rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(details.nameRussian)
                                    .font(.largeTitle.weight(.semibold))
                                    .textSelection(.enabled)

                                if let nameOriginal = details.nameOriginal {
                                    Text(nameOriginal)
                                        .font(.title3)
                                        .foregroundStyle(.secondary)
                                        .textSelection(.enabled)
                                }
                            }

                            HStack(alignment: .center, spacing: 12) {
                                if details.available {
                                    Button {
                                        isPlayPresented = true
                                    } label: {
                                        Label("key.watch", systemImage: "play.fill")
                                            .font(.body)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .lineLimit(1)
                                            .contentShape(.capsule)
                                            .background(Color.accentColor, in: .capsule)
                                    }
                                    .buttonStyle(.plain)
                                    .sheet(isPresented: $isPlayPresented) {
                                        WatchSheetView(id: details.movieId)
                                    }

                                    if downloader.isRunning {
                                        Button {
                                            isDownloadPresented = true
                                        } label: {
                                            Label("key.download", systemImage: "arrow.down.circle")
                                                .font(.body)
                                                .foregroundStyle(Color.accentColor)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 7)
                                                .lineLimit(1)
                                                .contentShape(.capsule)
                                                .background(.tertiary.opacity(0.05), in: .capsule)
                                                .overlay(.tertiary.opacity(0.2), in: .capsule.stroke(lineWidth: 1))
                                        }
                                        .buttonStyle(.plain)
                                        .sheet(isPresented: $isDownloadPresented) {
                                            DownloadSheetView(id: details.movieId)
                                        }
                                    }

                                    if !ExternalPlayers.allCases.compactMap({ NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0.bundleIdentifier) }).isEmpty || !ExternalPlayers.allCases.compactMap({ NSWorkspace.shared.urlForApplication(toOpen: $0.url) }).isEmpty {
                                        Button {
                                            isOpenExternalPlayerPresented = true
                                        } label: {
                                            Label("key.open.external", systemImage: "arrow.up.forward.app")
                                                .font(.body)
                                                .foregroundStyle(Color.accentColor)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 7)
                                                .lineLimit(1)
                                                .contentShape(.capsule)
                                                .background(.tertiary.opacity(0.05), in: .capsule)
                                                .overlay(.tertiary.opacity(0.2), in: .capsule.stroke(lineWidth: 1))
                                        }
                                        .buttonStyle(.plain)
                                        .sheet(isPresented: $isOpenExternalPlayerPresented) {
                                            OpenExternalPlayerSheetView(id: details.movieId)
                                        }
                                    }
                                } else if details.comingSoon {
                                    Button {} label: {
                                        Label("key.soon", systemImage: "clock")
                                            .font(.body)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(Color.accentColor, in: .capsule)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(true)
                                } else {
                                    Button {} label: {
                                        Label("key.unavailable", systemImage: "network.slash")
                                            .font(.body)
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                            .background(Color.accentColor, in: .capsule)
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(true)
                                }
                            }

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
                                        InfoRow(String(localized: "key.info.slogan"), slogan)
                                    }

                                    if let releaseDate = details.releaseDate, !releaseDate.isEmpty {
                                        if details.slogan?.isEmpty == false {
                                            Divider()
                                        }

                                        InfoRow(String(localized: "key.info.date"), releaseDate)
                                    }

                                    if let year = details.year, !year.isEmpty {
                                        if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false {
                                            Divider()
                                        }

                                        InfoRow(String(localized: "key.info.year"), year)
                                    }

                                    if let countries = details.countries, !countries.isEmpty {
                                        if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.year?.isEmpty == false {
                                            Divider()
                                        }

                                        InfoRowWithButtons(
                                            String(localized: "key.info.country"),
                                            String(localized: "key.info.country.description"),
                                            countries,
                                            countryDestination: $countryDestination,
                                            genreDestination: $genreDestination,
                                            personDestination: $personDestination,
                                            listDestination: $listDestination,
                                            collectionDestination: $collectionDestination,
                                        )
                                    }

                                    if let genres = details.genres, !genres.isEmpty {
                                        if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.year?.isEmpty == false || details.countries?.isEmpty == false {
                                            Divider()
                                        }

                                        InfoRowWithButtons(
                                            String(localized: "key.info.genres"),
                                            String(localized: "key.info.genres.description"),
                                            genres,
                                            countryDestination: $countryDestination,
                                            genreDestination: $genreDestination,
                                            personDestination: $personDestination,
                                            listDestination: $listDestination,
                                            collectionDestination: $collectionDestination,
                                        )
                                    }

                                    if let producer = details.producer, !producer.isEmpty {
                                        if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.year?.isEmpty == false || details.countries?.isEmpty == false || details.genres?.isEmpty == false {
                                            Divider()
                                        }

                                        InfoRowWithButtons(
                                            String(localized: "key.info.producer"),
                                            String(localized: "key.info.producer.description"),
                                            producer,
                                            countryDestination: $countryDestination,
                                            genreDestination: $genreDestination,
                                            personDestination: $personDestination,
                                            listDestination: $listDestination,
                                            collectionDestination: $collectionDestination,
                                        )
                                    }

                                    if let actors = details.actors, !actors.isEmpty {
                                        if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.year?.isEmpty == false || details.countries?.isEmpty == false || details.genres?.isEmpty == false || details.producer?.isEmpty == false {
                                            Divider()
                                        }

                                        InfoRowWithButtons(
                                            String(localized: "key.info.actors"),
                                            String(localized: "key.info.actors.description"),
                                            actors,
                                            countryDestination: $countryDestination,
                                            genreDestination: $genreDestination,
                                            personDestination: $personDestination,
                                            listDestination: $listDestination,
                                            collectionDestination: $collectionDestination,
                                        )
                                    }

                                    if let lists = details.lists, !lists.isEmpty {
                                        if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.year?.isEmpty == false || details.countries?.isEmpty == false || details.genres?.isEmpty == false || details.producer?.isEmpty == false || details.actors?.isEmpty == false {
                                            Divider()
                                        }

                                        InfoRowWithButtons(
                                            String(localized: "key.info.lists"),
                                            String(localized: "key.info.lists.description"),
                                            lists,
                                            countryDestination: $countryDestination,
                                            genreDestination: $genreDestination,
                                            personDestination: $personDestination,
                                            listDestination: $listDestination,
                                            collectionDestination: $collectionDestination,
                                        )
                                    }

                                    if let collections = details.collections, !collections.isEmpty {
                                        if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.year?.isEmpty == false || details.countries?.isEmpty == false || details.genres?.isEmpty == false || details.producer?.isEmpty == false || details.actors?.isEmpty == false || details.lists?.isEmpty == false {
                                            Divider()
                                        }

                                        InfoRowWithButtons(
                                            String(localized: "key.info.collections"),
                                            String(localized: "key.info.collections.description"),
                                            collections,
                                            countryDestination: $countryDestination,
                                            genreDestination: $genreDestination,
                                            personDestination: $personDestination,
                                            listDestination: $listDestination,
                                            collectionDestination: $collectionDestination,
                                        )
                                    }

                                    if let rating = details.rating {
                                        if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.year?.isEmpty == false || details.countries?.isEmpty == false || details.genres?.isEmpty == false || details.producer?.isEmpty == false || details.actors?.isEmpty == false || details.lists?.isEmpty == false || details.collections?.isEmpty == false {
                                            Divider()
                                        }

                                        InfoRowRating(String(localized: "key.info.rating"), rating, details.rated, details.votes)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .background(.quinary, in: .rect(cornerRadius: 6))
                                .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                            }
                        }
                    }

                    Divider().opacity(0)
                }
                .onGeometryChange(for: CGFloat.self) { geometry in
                    geometry.size.height
                } action: { height in
                    blurHeght = height
                }

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

                            InfoColumn("IMDb", imdbRating.value.description, StarsView(rating: imdbRating.value * 0.5, color: color), valueColor: color, hover: imdbRating.votesCount, url: URL(string: imdbRating.link))
                        }

                        if let kpRating = details.kpRating {
                            let color = Color.red.mix(with: .green, by: Double(kpRating.value / 10.0))

                            InfoColumn("КиноПоиск", kpRating.value.description, StarsView(rating: kpRating.value * 0.5, color: color), valueColor: color, hover: kpRating.votesCount, url: URL(string: kpRating.link))
                        }

                        if let waRating = details.waRating {
                            let color = Color.red.mix(with: .green, by: Double(waRating.value / 10.0))

                            InfoColumn("World Art", waRating.value.description, StarsView(rating: waRating.value * 0.5, color: color), valueColor: color, hover: waRating.votesCount, url: URL(string: waRating.link))
                        }

                        if let duration = details.duration, duration > 0 {
                            InfoColumn(String(localized: "key.info.duration"), duration.description, Text(String(localized: "key.info.minutes-\(duration)").trimmingCharacters(in: .letters.inverted).lowercased()).font(.body.weight(.medium)))
                        }

                        if let ageRestriction = details.ageRestriction, !ageRestriction.isEmpty {
                            InfoColumn(String(localized: "key.info.age"), ageRestriction, Text(String(localized: "key.info.years_old").lowercased()).font(.body.weight(.medium)))
                        }
                    }

                    Divider()
                }
            }
            .padding(.horizontal, 36)
            .padding(.top, 18)
            .padding(.top, topSafeAreaInset)
            .background {
                ZStack {
                    KFImage
                        .url(URL(string: details.poster))
                        .placeholder {
                            Color.gray
                        }
                        .resizable()
                        .loadTransition(.opacity, animation: .easeInOut)
                        .cancelOnDisappear(true)
                        .retry(NetworkRetryStrategy())
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: blurHeght)
                        .clipShape(.rect)

                    Rectangle().fill(.ultraThickMaterial)

                    Rectangle()
                        .fill(.background)
                        .mask {
                            LinearGradient(stops: [
                                .init(color: .black.opacity(0.3), location: 0.9),
                                .init(color: .black, location: 1.0),
                            ],
                            startPoint: .top,
                            endPoint: .bottom)
                        }
                }
                .viewModifier { view in
                    if #available(macOS 26, *) {
                        view.backgroundExtensionEffect()
                    } else {
                        view
                    }
                }
            }

            HStack(alignment: .center, spacing: 18) {
                Text(details.description)
                    .font(.title3)
                    .textSelection(.enabled)

                if let trailerId {
                    #if DEBUG
                        let isLoggingEnabled = true
                    #else
                        let isLoggingEnabled = false
                    #endif

                    let trailer = YouTubePlayer(
                        source: .video(id: trailerId),
                        parameters: .init(
                            autoPlay: false,
                            loopEnabled: true,
                            showControls: true,
                            showFullscreenButton: true,
                        ),
                        configuration: .init(
                            openURLAction: .init { url, _ in
                                openURL(url)
                            },
                        ),
                        isLoggingEnabled: isLoggingEnabled,
                    )

                    YouTubePlayerView(trailer, transaction: .init(animation: .easeInOut)) { state in
                        if state.isIdle {
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else if let error = state.error {
                            switch error {
                            case .embeddedVideoPlayingNotAllowed:
                                EmptyView()
                            default:
                                Text("key.youtube.error")
                            }
                        }
                    }
                    .aspectRatio(16 / 9, contentMode: .fit)
                    .frame(maxWidth: .infinity)
                    .contentShape(.rect(cornerRadius: 6))
                    .clipShape(.rect(cornerRadius: 6))
                    .onScrollVisibilityChange { isVisible in
                        if !isVisible, trailer.isPlaying {
                            Task {
                                try? await trailer.pause()
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 36)

            if details.franchise != nil || details.schedule != nil {
                Divider()
                    .padding(.horizontal, 36)

                HStack(alignment: .top, spacing: 36) {
                    if let franchise = details.franchise, !franchise.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("key.franchise")
                                    .font(.title2.bold())

                                Spacer()
                            }

                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(franchise.prefix(franchiseExpanded ? franchise.count : 5)) { fr in
                                    if !fr.current {
                                        NavigationLink(value: Destinations.details(MovieSimple(movieId: fr.franchiseId, name: fr.name))) {
                                            HStack(alignment: .center, spacing: 4) {
                                                ZStack(alignment: .center) {
                                                    ZStack(alignment: .center) {
                                                        Text(verbatim: "\(fr.position)")
                                                            .font(.subheadline)
                                                            .foregroundStyle(.white)
                                                    }
                                                    .frame(width: 19, height: 19)
                                                    .background(LinearGradient(colors: [.secondary.opacity(colorScheme == .dark ? 1 : 0.5), .secondary.opacity(colorScheme == .dark ? 0.5 : 1)], startPoint: .top, endPoint: .bottom), in: .rect(cornerRadius: 6))
                                                }
                                                .frame(width: 24, height: 24)

                                                VStack(alignment: .leading) {
                                                    Text(fr.name).font(.body)
                                                        .lineLimit(1)

                                                    if let rating = fr.rating {
                                                        let color = Color.red.mix(with: .green, by: Double(rating / 10.0))
                                                        let rating = Text(verbatim: "\(rating)").foregroundStyle(color)
                                                        let star = Text(Image(systemName: "star.fill")).foregroundStyle(color)

                                                        Text("key.franchise.year-\(fr.year)-\(rating)-\(star)")
                                                            .font(.subheadline)
                                                            .foregroundStyle(.secondary)
                                                    } else {
                                                        Text("key.franchise.year-\(fr.year)").font(.subheadline).foregroundStyle(.secondary)
                                                    }
                                                }

                                                Spacer()

                                                Image(systemName: "chevron.right").font(.body)
                                            }
                                            .contentShape(.rect)
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.vertical, 8)
                                    } else {
                                        HStack(alignment: .center, spacing: 4) {
                                            ZStack(alignment: .center) {
                                                ZStack(alignment: .center) {
                                                    Text(String(fr.position))
                                                        .font(.subheadline)
                                                        .foregroundStyle(.white)
                                                }
                                                .frame(width: 19, height: 19)
                                                .background(LinearGradient(colors: [Color.accentColor.opacity(colorScheme == .dark ? 1 : 0.5), Color.accentColor.opacity(colorScheme == .dark ? 0.5 : 1)], startPoint: .top, endPoint: .bottom), in: .rect(cornerRadius: 6))
                                            }
                                            .frame(width: 24, height: 24)

                                            VStack(alignment: .leading) {
                                                Text(fr.name).font(.body)
                                                    .lineLimit(1)

                                                if let rating = fr.rating {
                                                    let color = Color.red.mix(with: .green, by: Double(rating / 10.0))
                                                    let rating = Text(verbatim: "\(rating)").foregroundStyle(color)
                                                    let star = Text(Image(systemName: "star.fill")).foregroundStyle(color)

                                                    Text("key.franchise.year-\(fr.year)-\(rating)-\(star)")
                                                        .font(.subheadline)
                                                        .foregroundStyle(.secondary)
                                                } else {
                                                    Text("key.franchise.year-\(fr.year)").font(.subheadline).foregroundStyle(.secondary)
                                                }
                                            }

                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                    }

                                    if fr != franchise.last || franchise.count > 5 {
                                        Divider()
                                    }
                                }

                                if franchise.count > 5 {
                                    HStack {
                                        Spacer()

                                        Button {
                                            withAnimation(.easeInOut) {
                                                franchiseExpanded.toggle()
                                            }
                                        } label: {
                                            Text(franchiseExpanded ? String(localized: "key.hide").lowercased() : String(localized: "key.view_more").lowercased())
                                                .font(.body)
                                                .foregroundStyle(.primary)
                                        }
                                        .buttonStyle(.accessoryBar)

                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .padding(.horizontal, 10)
                            .background(.quinary, in: .rect(cornerRadius: 6))
                            .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                        }
                    }

                    if let schedule = details.schedule, let first = schedule.first {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("key.schedule")
                                    .font(.title2.bold())

                                Spacer()
                            }

                            VStack(alignment: .leading, spacing: 10) {
                                Text(first.name)
                                    .font(.title3.bold())

                                LazyVStack(alignment: .leading, spacing: 0) {
                                    ForEach(first.items.prefix(5)) { item in
                                        HStack(alignment: .center) {
                                            VStack(alignment: .leading) {
                                                Text(item.russianEpisodeName)
                                                    .font(.body)
                                                    .lineLimit(1)

                                                if let originalEpisodeName = item.originalEpisodeName {
                                                    Text(originalEpisodeName)
                                                        .font(.body)
                                                        .lineLimit(1)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }

                                            Spacer()

                                            VStack(alignment: .trailing) {
                                                Text(item.releaseDate).font(.body).foregroundStyle(.secondary)

                                                Text(item.title).font(.subheadline).foregroundStyle(.secondary)
                                            }
                                        }
                                        .padding(.vertical, 8)

                                        if item != first.items.prefix(5).last || schedule.count > 1 || first.items.count > 5 {
                                            Divider()
                                        }
                                    }

                                    if schedule.count > 1 || first.items.count > 5 {
                                        HStack {
                                            Spacer()

                                            Button {
                                                isSchedulePresented = true
                                            } label: {
                                                Text(String(localized: "key.view_more").lowercased())
                                                    .font(.body)
                                                    .foregroundStyle(.primary)
                                            }
                                            .buttonStyle(.accessoryBar)

                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .background(.quinary, in: .rect(cornerRadius: 6))
                                .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                            }
                        }
                    }
                }
                .padding(.horizontal, 36)
            }

            Divider()
                .padding(.horizontal, 36)

            VStack(alignment: .leading, spacing: 18) {
                Text("key.watch_also").font(.title.bold())
                    .padding(.horizontal, 36)

                ScrollView(.horizontal) {
                    LazyHStack(alignment: .top, spacing: 18) {
                        ForEach(details.watchAlsoMovies) { movie in
                            CardView(movie: movie, reservesSpace: true)
                                .frame(width: 150)
                        }
                    }
                    .padding(.horizontal, 36)
                }
                .scrollIndicators(.never)
            }
            .padding(.bottom, 18)
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

                Spacer(minLength: 10)

                Text(info).font(.body).foregroundStyle(.secondary)
                    .lineLimit(1)
                    .help(info)
            }
            .padding(.vertical, 8)
        }
    }

    private struct InfoRowWithButtons<T: Named>: View {
        private let title: String
        private let description: String
        private let data: [T]

        @State private var isPresented: Bool = false

        @Binding private var countryDestination: MovieCountry?
        @Binding private var genreDestination: MovieGenre?
        @Binding private var personDestination: PersonSimple?
        @Binding private var listDestination: MovieList?
        @Binding private var collectionDestination: MoviesCollection?

        init(_ title: String,
             _ description: String,
             _ data: [T],
             countryDestination: Binding<MovieCountry?>,
             genreDestination: Binding<MovieGenre?>,
             personDestination: Binding<PersonSimple?>,
             listDestination: Binding<MovieList?>,
             collectionDestination: Binding<MoviesCollection?>)
        {
            self.title = title
            self.description = description
            self.data = data
            _countryDestination = countryDestination
            _genreDestination = genreDestination
            _personDestination = personDestination
            _listDestination = listDestination
            _collectionDestination = collectionDestination
        }

        var body: some View {
            HStack(alignment: .center) {
                Text(title)
                    .font(.body)

                Spacer(minLength: 10)

                HStack(alignment: .center, spacing: 4) {
                    HStack(alignment: .center, spacing: 0) {
                        ForEach(data.prefix(2)) { item in
                            NavigationLink(value: Destinations.fromNamed(item)) {
                                if let person = item as? PersonSimple, !person.photo.isEmpty {
                                    PersonTextWithPhoto(person: person)
                                        .contentShape(.rect)
                                } else if let list = item as? MovieList, let position = list.moviePosition?.toNumeral() {
                                    let place = Text("key.place-\(position)").foregroundStyle(.tertiary)

                                    Text("key.list-\(list.name)-\(place)")
                                        .foregroundStyle(.secondary)
                                        .font(.body)
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .contentShape(.rect)
                                } else {
                                    Text(item.name)
                                        .font(.body)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                        .contentShape(.rect)
                                }
                            }
                            .buttonStyle(.plain)

                            if item != data.prefix(2).last {
                                Text(verbatim: ", ")
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }

                    if data.count > 2 {
                        Button {
                            isPresented = true
                        } label: {
                            Image(systemName: "info.circle")
                                .font(.body)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .popover(isPresented: $isPresented, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                            VStack(alignment: .center, spacing: 6) {
                                Text(title)
                                    .font(.body.bold())
                                    .multilineTextAlignment(.center)

                                Text(description)
                                    .font(.caption)
                                    .multilineTextAlignment(.center)

                                VStack(alignment: .center, spacing: 0) {
                                    ForEach(data) { item in
                                        Button {
                                            switch Destinations.fromNamed(item) {
                                            case let .country(country):
                                                countryDestination = country
                                            case let .genre(genre):
                                                genreDestination = genre
                                            case let .person(person):
                                                personDestination = person
                                            case let .list(list):
                                                listDestination = list
                                            case let .collection(collection):
                                                collectionDestination = collection
                                            default:
                                                fatalError("Need \"named\" implementation")
                                            }
                                        } label: {
                                            if let person = item as? PersonSimple, !person.photo.isEmpty {
                                                HStack(alignment: .center, spacing: 8) {
                                                    KFImage
                                                        .url(URL(string: person.photo))
                                                        .placeholder {
                                                            Color.gray.shimmering()
                                                        }
                                                        .resizable()
                                                        .loadTransition(.blurReplace, animation: .easeInOut)
                                                        .removeBackground()
                                                        .cancelOnDisappear(true)
                                                        .retry(NetworkRetryStrategy())
                                                        .imageFill(2 / 3)
                                                        .frame(width: 36, height: 36)
                                                        .background(.quinary)
                                                        .clipShape(.circle)
                                                        .padding(2)
                                                        .overlay(.tertiary.opacity(0.2), in: .circle.stroke(lineWidth: 1))

                                                    Text(person.name)
                                                        .font(.body)
                                                        .lineLimit(nil)
                                                        .multilineTextAlignment(.center)
                                                }
                                                .contentShape(.rect)
                                            } else if let list = item as? MovieList, let position = list.moviePosition?.toNumeral() {
                                                let place = Text("key.place-\(position)").foregroundStyle(.secondary)

                                                Text("key.list-\(list.name)-\(place)")
                                                    .font(.body)
                                                    .lineLimit(nil)
                                                    .multilineTextAlignment(.center)
                                                    .contentShape(.rect)
                                            } else {
                                                Text(item.name)
                                                    .font(.body)
                                                    .lineLimit(nil)
                                                    .multilineTextAlignment(.center)
                                                    .contentShape(.rect)
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.vertical, 6)

                                        if item != data.last {
                                            Divider()
                                        }
                                    }
                                }
                            }
                            .padding(10)
                            .frame(width: 200)
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private struct InfoRowRating: View {
        private let title: String
        private let rating: Float
        private let rated: Bool
        private let votes: String?

        @State private var hover: Float?
        @State private var vote: Bool = false

        @Default(.isLoggedIn) private var isLoggedIn

        @Environment(DetailsViewModel.self) private var viewModel

        init(_ title: String, _ rating: Float, _ rated: Bool, _ votes: String?) {
            self.title = title
            self.rating = rating
            self.rated = rated
            self.votes = votes
        }

        private var stars: some View {
            HStack(spacing: 0) {
                ForEach(0 ..< 10) { index in
                    if !rated, isLoggedIn {
                        Button {
                            viewModel.rate(rating: index + 1)
                        } label: {
                            Image(systemName: "star.fill")
                                .font(.system(.body, design: .rounded))
                                .aspectRatio(contentMode: .fit)
                        }
                        .buttonStyle(.plain)
                        .onHover { hover in
                            withAnimation(.easeInOut(duration: 0.15)) {
                                if hover {
                                    self.hover = Float(index + 1)
                                } else {
                                    self.hover = nil
                                }
                            }
                        }
                    } else {
                        Image(systemName: "star.fill")
                            .font(.system(.body, design: .rounded))
                            .aspectRatio(contentMode: .fit)
                    }
                }
            }
        }

        var body: some View {
            HStack(alignment: .center) {
                Text(title)
                    .font(.body)

                Spacer(minLength: 10)

                HStack(alignment: .center, spacing: 4) {
                    stars
                        .background(alignment: .leading) {
                            GeometryReader { geometry in
                                (hover != nil ? Color.primary : Color.secondary)
                                    .frame(width: (CGFloat(hover ?? rating) / 10.0) * geometry.size.width)
                            }
                            .mask(stars)
                        }
                        .foregroundStyle(.tertiary)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(verbatim: "\(rating)")
                            .font(.body.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText(value: Double(rating)))

                        if let votes, vote {
                            Text(verbatim: "(\(votes))")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                                .contentTransition(.numericText())
                        }
                    }
                    .viewModifier { view in
                        if votes != nil {
                            view.onHover { hover in
                                withAnimation(.easeInOut) {
                                    vote = hover
                                }
                            }
                        } else {
                            view
                        }
                    }
                }
            }
            .padding(.vertical, 8)
        }
    }

    private struct PersonTextWithPhoto: View {
        private let person: PersonSimple

        init(person: PersonSimple) {
            self.person = person
        }

        @State private var show: Bool = false

        var body: some View {
            Text(person.name)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .onHover {
                    show = $0
                }
                .popover(isPresented: $show) {
                    KFImage
                        .url(URL(string: person.photo))
                        .placeholder {
                            Color.gray.shimmering()
                        }
                        .resizable()
                        .loadTransition(.blurReplace, animation: .easeInOut)
                        .removeBackground()
                        .cancelOnDisappear(true)
                        .retry(NetworkRetryStrategy())
                        .imageFill(2 / 3)
                        .frame(width: 64, height: 64)
                        .background(.quinary)
                        .clipShape(.circle)
                        .padding(4)
                        .overlay(.tertiary.opacity(0.2), in: .circle.stroke(lineWidth: 1))
                        .padding(4)
                }
        }
    }

    private struct StarsView: View {
        private let rating: CGFloat
        private let color: Color

        init(rating: Float, color: Color = .accentColor) {
            self.rating = CGFloat(rating)
            self.color = color
        }

        private var stars: some View {
            HStack(spacing: 0) {
                ForEach(0 ..< 5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(.body, design: .rounded))
                        .aspectRatio(contentMode: .fit)
                }
            }
        }

        var body: some View {
            stars
                .overlay(alignment: .leading) {
                    GeometryReader { geometry in
                        color.frame(width: (rating / 5.0) * geometry.size.width)
                    }
                    .mask(stars)
                }
                .foregroundStyle(.tertiary)
        }
    }

    private struct InfoColumn<T: View>: View {
        private let title: String
        private let value: String
        private let subtitle: T
        private let hover: String?
        private let valueColor: Color?
        private let url: URL?

        init(_ title: String, _ value: String, _ subtitle: T, valueColor: Color? = nil, hover: String? = nil, url: URL? = nil) {
            self.title = title
            self.value = value
            self.subtitle = subtitle
            self.hover = hover
            self.valueColor = valueColor
            self.url = url
        }

        @State private var show: Bool = false

        var body: some View {
            HStack(alignment: .center, spacing: 0) {
                Spacer()

                if let url {
                    Link(destination: url) {
                        VStack(alignment: .center, spacing: 2) {
                            Text(title).font(.body.weight(.medium))

                            HStack(alignment: .firstTextBaseline, spacing: 2) {
                                Text(value)
                                    .font(.system(.title, design: .rounded, weight: .semibold))
                                    .viewModifier { view in
                                        if let valueColor {
                                            view.foregroundStyle(valueColor)
                                        } else {
                                            view
                                        }
                                    }

                                if let hover, show {
                                    Text(verbatim: "(\(hover))")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .viewModifier { view in
                                if hover != nil {
                                    view.onHover { hover in
                                        withAnimation(.easeInOut) {
                                            show = hover
                                        }
                                    }
                                } else {
                                    view
                                }
                            }

                            subtitle
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                } else {
                    VStack(alignment: .center, spacing: 2) {
                        Text(title).font(.body.weight(.medium))

                        HStack(alignment: .center, spacing: 2) {
                            Text(value)
                                .font(.system(.title, design: .rounded, weight: .semibold))
                                .viewModifier { view in
                                    if let valueColor {
                                        view.foregroundStyle(valueColor)
                                    } else {
                                        view
                                    }
                                }

                            if let hover, show {
                                Text(verbatim: "(\(hover))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .viewModifier { view in
                            if hover != nil {
                                view.onHover { hover in
                                    withAnimation(.easeInOut) {
                                        show = hover
                                    }
                                }
                            } else {
                                view
                            }
                        }

                        subtitle
                    }
                }

                Spacer()
            }
        }
    }
}
