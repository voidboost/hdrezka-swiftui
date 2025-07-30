import Combine
import Defaults
import FactoryKit
import SwiftData
import SwiftUI

struct OpenExternalPlayerSheetView: View {
    @Injected(\.saveWatchingStateUseCase) private var saveWatchingStateUseCase
    @Injected(\.getMovieDetailsUseCase) private var getMovieDetailsUseCase
    @Injected(\.getMovieVideoUseCase) private var getMovieVideoUseCase
    @Injected(\.getSeriesSeasonsUseCase) private var getSeriesSeasonsUseCase

    @State private var subscriptions: Set<AnyCancellable> = []

    @Environment(\.openURL) private var openURL
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Environment(AppState.self) private var appState

    @Query private var selectPositions: [SelectPosition]

    @Default(.isUserPremium) private var isUserPremium
    @Default(.isLoggedIn) private var isLoggedIn
    @Default(.defaultQuality) private var defaultQuality

    private let id: String

    @State private var details: MovieDetailed?
    @State private var seasons: [MovieSeason]?
    @State private var selectedActing: MovieVoiceActing?
    @State private var selectedSeason: MovieSeason?
    @State private var selectedEpisode: MovieEpisode?
    @State private var selectedQuality: String?
    @State private var selectedSubtitles: MovieSubtitles?
    @State private var movie: MovieVideo?

    @State private var error: Error?

    @State private var isErrorPresented: Bool = false
    @State private var isLoginPresented: Bool = false

    @State private var showRating: Bool = false

    init(id: String) {
        self.id = id
    }

    var body: some View {
        VStack(alignment: .center, spacing: 25) {
            VStack(alignment: .center, spacing: 5) {
                Image(systemName: "arrow.up.forward.app")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)

                Text("key.before_starting")
                    .font(.largeTitle.weight(.semibold))

                Text("key.open.description")
                    .font(.title3)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.center)
            }

            if let details {
                VStack(spacing: 18) {
                    if details.series != nil || !(details.voiceActing ?? []).filter({ !$0.name.isEmpty }).isEmpty {
                        VStack(spacing: 2.5) {
                            if let acting = details.voiceActing, !acting.filter({ !$0.name.isEmpty }).isEmpty {
                                ZStack(alignment: .center) {
                                    HStack {
                                        Text("key.acting")

                                        if let rating = details.voiceActingRating?.sorted(by: { $0.percent > $1.percent }), !rating.isEmpty {
                                            Button {
                                                showRating = true
                                            } label: {
                                                Image(systemName: "questionmark.circle")
                                                    .foregroundStyle(Color.accentColor)
                                                    .font(.system(size: 11))
                                            }
                                            .buttonStyle(.plain)
                                            .popover(isPresented: $showRating, arrowEdge: .trailing) {
                                                ScrollView(.vertical) {
                                                    LazyVStack(alignment: .leading, spacing: 5) {
                                                        ForEach(rating) { rate in
                                                            ProgressView(value: rate.percent / 100.0) {
                                                                Text(rate.name)
                                                            } currentValueLabel: {
                                                                Text(verbatim: "\(rate.percent)%")
                                                            }
                                                        }
                                                    }
                                                    .padding(15)
                                                    .progressViewStyle(.linear)
                                                }
                                                .scrollIndicators(.never)
                                                .frame(width: 300)
                                                .frame(maxHeight: 300)
                                            }
                                        }

                                        Spacer()

                                        Menu {
                                            if acting.filter({ $0 != selectedActing }).contains(where: \.isPremium) {
                                                Section {
                                                    ForEach(acting.filter(\.isPremium).filter { $0 != selectedActing }) { acting in
                                                        Button {
                                                            if isUserPremium != nil {
                                                                withAnimation(.easeInOut) {
                                                                    selectedActing = acting
                                                                }
                                                            } else {
                                                                dismiss()

                                                                appState.isPremiumPresented = true
                                                            }
                                                        } label: {
                                                            HStack(spacing: 2) {
                                                                Image("Premium")
                                                                    .renderingMode(.template)

                                                                Text(acting.name)
                                                            }
                                                        }
                                                    }
                                                } header: {
                                                    Text("key.premium")
                                                }

                                                Divider()
                                            }

                                            ForEach(acting.filter {
                                                !$0.isPremium
                                            }.filter { $0 != selectedActing }) { acting in
                                                Button {
                                                    withAnimation(.easeInOut) {
                                                        selectedActing = acting
                                                    }
                                                } label: {
                                                    Text(acting.name)
                                                }
                                            }
                                        } label: {
                                            let name = if let selectedActing {
                                                if selectedActing.name.isEmpty {
                                                    String(localized: "key.default")
                                                } else {
                                                    selectedActing.name
                                                }
                                            } else {
                                                String(localized: "key.acting.select")
                                            }

                                            Label(name, systemImage: "chevron.up.chevron.down")
                                        }
                                        .menuStyle(.button)
                                        .menuIndicator(.hidden)
                                        .buttonStyle(.plain)
                                        .labelStyle(CustomLabelStyle(iconVisible: acting.count > 1))
                                    }
                                    .padding(.vertical, 10)

                                    if acting.isEmpty != false {
                                        ProgressView().scaleEffect(0.6)
                                    }
                                }
                            }

                            if details.series != nil, selectedActing != nil {
                                if !(details.voiceActing ?? []).filter({ !$0.name.isEmpty }).isEmpty {
                                    Divider()
                                }

                                ZStack(alignment: .center) {
                                    HStack {
                                        Text("key.season")

                                        Spacer()

                                        Menu {
                                            ForEach((seasons ?? []).filter { $0 != selectedSeason }) { season in
                                                Button {
                                                    withAnimation(.easeInOut) {
                                                        selectedSeason = season
                                                    }
                                                } label: {
                                                    Text(season.name.contains(/^\d/) ? String(localized: "key.season-\(season.name)") : season.name)
                                                }
                                            }
                                        } label: {
                                            let name = if let selectedSeason {
                                                if selectedSeason.name.isEmpty {
                                                    String(localized: "key.season-\(1)")
                                                } else if selectedSeason.name.contains(/^\d/) {
                                                    String(localized: "key.season-\(selectedSeason.name)")
                                                } else {
                                                    selectedSeason.name
                                                }
                                            } else {
                                                String(localized: "key.season.select")
                                            }

                                            Label(name, systemImage: "chevron.up.chevron.down")
                                        }
                                        .menuStyle(.button)
                                        .menuIndicator(.hidden)
                                        .buttonStyle(.plain)
                                        .labelStyle(CustomLabelStyle(iconVisible: (seasons?.count ?? 0) > 1))
                                    }
                                    .padding(.vertical, 10)

                                    if seasons?.isEmpty != false {
                                        ProgressView().scaleEffect(0.6)
                                    }
                                }

                                Divider()

                                ZStack {
                                    HStack {
                                        Text("key.episode")

                                        Spacer()

                                        Menu {
                                            ForEach((selectedSeason?.episodes ?? []).filter { $0 != selectedEpisode }) { episode in
                                                Button {
                                                    withAnimation(.easeInOut) {
                                                        selectedEpisode = episode
                                                    }
                                                } label: {
                                                    Text(episode.name.contains(/^\d/) ? String(localized: "key.episode-\(episode.name)") : episode.name)
                                                }
                                            }
                                        } label: {
                                            let name = if let selectedEpisode {
                                                if selectedEpisode.name.isEmpty {
                                                    String(localized: "key.episode-\(1)")
                                                } else if selectedEpisode.name.contains(/^\d/) {
                                                    String(localized: "key.episode-\(selectedEpisode.name)")
                                                } else {
                                                    selectedEpisode.name
                                                }
                                            } else {
                                                String(localized: "key.episode.select")
                                            }

                                            Label(name, systemImage: "chevron.up.chevron.down")
                                        }
                                        .menuStyle(.button)
                                        .menuIndicator(.hidden)
                                        .buttonStyle(.plain)
                                        .labelStyle(CustomLabelStyle(iconVisible: (selectedSeason?.episodes.count ?? 0) > 1))
                                    }
                                    .padding(.vertical, 10)

                                    if selectedSeason?.episodes.isEmpty != false {
                                        ProgressView().scaleEffect(0.6)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        .background(.quinary)
                        .clipShape(.rect(cornerRadius: 6))
                        .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                    }

                    if (details.series == nil && selectedActing != nil) || selectedEpisode != nil {
                        ZStack(alignment: .center) {
                            HStack {
                                Text("key.quality")

                                if let selectedQuality, let movie, let link = movie.getClosestTo(quality: selectedQuality) {
                                    ShareLink(item: link) {
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundStyle(.secondary)
                                            .font(.system(size: 11))
                                    }
                                    .buttonStyle(.plain)
                                }

                                Spacer()

                                Menu {
                                    if !(movie?.getLockedQualities() ?? []).isEmpty {
                                        Section {
                                            ForEach(movie?.getLockedQualities() ?? [], id: \.self) { quality in
                                                Button {
                                                    if isLoggedIn {
                                                        withAnimation(.easeInOut) {
                                                            selectedQuality = quality
                                                        }
                                                    } else {
                                                        isLoginPresented = true
                                                    }
                                                } label: {
                                                    Text(quality)
                                                }
                                            }
                                        } header: {
                                            Text("key.sign_in.access")
                                        }

                                        Divider()
                                    }

                                    ForEach((movie?.getAvailableQualities() ?? []).filter { $0 != selectedQuality }, id: \.self) { quality in
                                        Button {
                                            withAnimation(.easeInOut) {
                                                selectedQuality = quality
                                            }
                                        } label: {
                                            Text(quality)
                                        }
                                    }
                                } label: {
                                    let name = if let selectedQuality {
                                        if selectedQuality.isEmpty {
                                            String(localized: "key.default")
                                        } else {
                                            selectedQuality
                                        }
                                    } else {
                                        String(localized: "key.quality.select")
                                    }

                                    Label(name, systemImage: "chevron.up.chevron.down")
                                }
                                .menuStyle(.button)
                                .menuIndicator(.hidden)
                                .buttonStyle(.plain)
                                .labelStyle(CustomLabelStyle(iconVisible: ((movie?.getAvailableQualities().count ?? 0) + (movie?.getLockedQualities().count ?? 0)) > 1))
                            }
                            .padding(.vertical, 10)

                            if movie?.getAvailableQualities().isEmpty != false {
                                ProgressView().scaleEffect(0.6)
                            }
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        .background(.quinary)
                        .clipShape(.rect(cornerRadius: 6))
                        .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                    }

                    if let movie, !movie.subtitles.isEmpty {
                        ZStack(alignment: .center) {
                            HStack {
                                Text("key.subtitles")

                                if let selectedSubtitles, let subtitles = movie.subtitles.first(where: { $0 == selectedSubtitles }), let url = URL(string: subtitles.link) {
                                    ShareLink(item: url) {
                                        Image(systemName: "square.and.arrow.up")
                                            .foregroundStyle(.secondary)
                                            .font(.system(size: 11))
                                    }
                                    .buttonStyle(.plain)
                                }

                                Spacer()

                                Menu {
                                    if selectedSubtitles != nil {
                                        Button {
                                            withAnimation(.easeInOut) {
                                                selectedSubtitles = nil
                                            }
                                        } label: {
                                            Text("key.none")
                                        }
                                    }

                                    ForEach(movie.subtitles.filter { $0 != selectedSubtitles }) { subtitles in
                                        Button {
                                            withAnimation(.easeInOut) {
                                                selectedSubtitles = subtitles
                                            }
                                        } label: {
                                            Text(subtitles.name)
                                        }
                                    }
                                } label: {
                                    let name = if let selectedSubtitles {
                                        if selectedSubtitles.name.isEmpty {
                                            String(localized: "key.default")
                                        } else {
                                            selectedSubtitles.name
                                        }
                                    } else {
                                        String(localized: "key.subtitles.select")
                                    }

                                    Label(name, systemImage: "chevron.up.chevron.down")
                                }
                                .menuStyle(.button)
                                .menuIndicator(.hidden)
                                .buttonStyle(.plain)
                                .labelStyle(CustomLabelStyle(iconVisible: movie.subtitles.count > 0))
                            }
                            .padding(.vertical, 10)
                        }
                        .padding(.horizontal, 15)
                        .padding(.vertical, 5)
                        .background(.quinary)
                        .clipShape(.rect(cornerRadius: 6))
                        .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                    }
                }
            } else {
                ProgressView()
            }

            VStack(alignment: .center, spacing: 10) {
                if !ExternalPlayers.allCases.compactMap({ NSWorkspace.shared.urlForApplication(withBundleIdentifier: $0.bundleIdentifier) }).isEmpty || !ExternalPlayers.allCases.compactMap({ NSWorkspace.shared.urlForApplication(toOpen: $0.url) }).isEmpty {
                    if NSWorkspace.shared.urlForApplication(toOpen: ExternalPlayers.iina.url) != nil {
                        Button {
                            if let selectedActing {
                                if isLoggedIn {
                                    saveWatchingStateUseCase(voiceActing: selectedActing, season: selectedSeason, episode: selectedEpisode, position: 0, total: 0)
                                        .sink { _ in } receiveValue: { _ in }
                                        .store(in: &subscriptions)
                                }

                                if let position = selectPositions.first(where: { position in
                                    position.id == selectedActing.voiceId
                                }) {
                                    position.acting = selectedActing.translatorId
                                    position.season = selectedSeason?.seasonId
                                    position.episode = selectedEpisode?.episodeId
                                } else {
                                    let position = SelectPosition(
                                        id: selectedActing.voiceId,
                                        acting: selectedActing.translatorId,
                                        season: selectedSeason?.seasonId,
                                        episode: selectedEpisode?.episodeId,
                                    )

                                    modelContext.insert(position)
                                }
                            }

                            if let movie, let selectedQuality, let movieURL = movie.getClosestTo(quality: selectedQuality)?.hls, let selectedSubtitles, let subtitlesURL = URL(string: selectedSubtitles.link) {
                                openURL(
                                    ExternalPlayers.iina.url.appending(queryItems: [
                                        .init(name: "url", value: movieURL.absoluteString),
                                        .init(name: "mpv_sub-files", value: subtitlesURL.absoluteString.replacingOccurrences(of: ":", with: "\\:")),
                                        .init(name: "new_window", value: "1"),
                                    ]),
                                )
                            } else if let movie, let selectedQuality, let movieURL = movie.getClosestTo(quality: selectedQuality)?.hls {
                                openURL(
                                    ExternalPlayers.iina.url.appending(queryItems: [
                                        .init(name: "url", value: movieURL.absoluteString),
                                        .init(name: "new_window", value: "1"),
                                    ]),
                                )
                            }
                        } label: {
                            Text(ExternalPlayers.iina.localizedKey)
                                .frame(width: 250, height: 30)
                                .foregroundStyle(.white)
                                .background(selectedQuality != nil ? Color.accentColor : Color.secondary)
                                .clipShape(.rect(cornerRadius: 6))
                                .contentShape(.rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedQuality == nil)
                    }

                    if NSWorkspace.shared.urlForApplication(toOpen: ExternalPlayers.infuse.url) != nil {
                        Button {
                            if let selectedActing {
                                if isLoggedIn {
                                    saveWatchingStateUseCase(voiceActing: selectedActing, season: selectedSeason, episode: selectedEpisode, position: 0, total: 0)
                                        .sink { _ in } receiveValue: { _ in }
                                        .store(in: &subscriptions)
                                }

                                if let position = selectPositions.first(where: { position in
                                    position.id == selectedActing.voiceId
                                }) {
                                    position.acting = selectedActing.translatorId
                                    position.season = selectedSeason?.seasonId
                                    position.episode = selectedEpisode?.episodeId
                                } else {
                                    let position = SelectPosition(
                                        id: selectedActing.voiceId,
                                        acting: selectedActing.translatorId,
                                        season: selectedSeason?.seasonId,
                                        episode: selectedEpisode?.episodeId,
                                    )

                                    modelContext.insert(position)
                                }
                            }

                            if let movie, let selectedQuality, let movieURL = movie.getClosestTo(quality: selectedQuality), let selectedSubtitles, let subtitlesURL = URL(string: selectedSubtitles.link) {
                                openURL(
                                    ExternalPlayers.infuse.url.appending(queryItems: [
                                        .init(name: "url", value: movieURL.absoluteString),
                                        .init(name: "sub", value: subtitlesURL.absoluteString),
                                    ]),
                                )
                            } else if let movie, let selectedQuality, let movieURL = movie.getClosestTo(quality: selectedQuality) {
                                openURL(
                                    ExternalPlayers.infuse.url.appending(queryItems: [
                                        .init(name: "url", value: movieURL.absoluteString),
                                    ]),
                                )
                            }
                        } label: {
                            Text(ExternalPlayers.infuse.localizedKey)
                                .frame(width: 250, height: 30)
                                .foregroundStyle(.white)
                                .background(selectedQuality != nil ? Color.accentColor : Color.secondary)
                                .clipShape(.rect(cornerRadius: 6))
                                .contentShape(.rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedQuality == nil)
                    }

                    if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: ExternalPlayers.mpv.bundleIdentifier) {
                        Button {
                            if let selectedActing {
                                if isLoggedIn {
                                    saveWatchingStateUseCase(voiceActing: selectedActing, season: selectedSeason, episode: selectedEpisode, position: 0, total: 0)
                                        .sink { _ in } receiveValue: { _ in }
                                        .store(in: &subscriptions)
                                }

                                if let position = selectPositions.first(where: { position in
                                    position.id == selectedActing.voiceId
                                }) {
                                    position.acting = selectedActing.translatorId
                                    position.season = selectedSeason?.seasonId
                                    position.episode = selectedEpisode?.episodeId
                                } else {
                                    let position = SelectPosition(
                                        id: selectedActing.voiceId,
                                        acting: selectedActing.translatorId,
                                        season: selectedSeason?.seasonId,
                                        episode: selectedEpisode?.episodeId,
                                    )

                                    modelContext.insert(position)
                                }
                            }

                            if let movie, let selectedQuality, let movieURL = movie.getClosestTo(quality: selectedQuality)?.hls, let selectedSubtitles, let subtitlesURL = URL(string: selectedSubtitles.link) {
                                do {
                                    try Process.run(
                                        appURL.appending(path: "Contents", directoryHint: .isDirectory).appending(path: "MacOS", directoryHint: .isDirectory).appending(path: appURL.deletingPathExtension().lastPathComponent, directoryHint: .notDirectory),
                                        arguments: [
                                            "--sub-files=\(subtitlesURL.absoluteString.replacingOccurrences(of: ":", with: "\\:"))",
                                            movieURL.absoluteString,
                                        ],
                                    )
                                } catch {
                                    self.error = error
                                    isErrorPresented = true
                                }
                            } else if let movie, let selectedQuality, let movieURL = movie.getClosestTo(quality: selectedQuality)?.hls {
                                do {
                                    try Process.run(
                                        appURL.appending(path: "Contents", directoryHint: .isDirectory).appending(path: "MacOS", directoryHint: .isDirectory).appending(path: appURL.deletingPathExtension().lastPathComponent, directoryHint: .notDirectory),
                                        arguments: [
                                            movieURL.absoluteString,
                                        ],
                                    )
                                } catch {
                                    self.error = error
                                    isErrorPresented = true
                                }
                            }
                        } label: {
                            Text(ExternalPlayers.mpv.localizedKey)
                                .frame(width: 250, height: 30)
                                .foregroundStyle(.white)
                                .background(selectedQuality != nil ? Color.accentColor : Color.secondary)
                                .clipShape(.rect(cornerRadius: 6))
                                .contentShape(.rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedQuality == nil)
                    }

                    if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: ExternalPlayers.vlc.bundleIdentifier) {
                        Button {
                            if let selectedActing {
                                if isLoggedIn {
                                    saveWatchingStateUseCase(voiceActing: selectedActing, season: selectedSeason, episode: selectedEpisode, position: 0, total: 0)
                                        .sink { _ in } receiveValue: { _ in }
                                        .store(in: &subscriptions)
                                }

                                if let position = selectPositions.first(where: { position in
                                    position.id == selectedActing.voiceId
                                }) {
                                    position.acting = selectedActing.translatorId
                                    position.season = selectedSeason?.seasonId
                                    position.episode = selectedEpisode?.episodeId
                                } else {
                                    let position = SelectPosition(
                                        id: selectedActing.voiceId,
                                        acting: selectedActing.translatorId,
                                        season: selectedSeason?.seasonId,
                                        episode: selectedEpisode?.episodeId,
                                    )

                                    modelContext.insert(position)
                                }
                            }

                            if let movie, let selectedQuality, let movieURL = movie.getClosestTo(quality: selectedQuality)?.hls, let selectedSubtitles, let subtitlesURL = URL(string: selectedSubtitles.link), subtitlesURL.pathExtension == "srt" {
                                do {
                                    try Process.run(
                                        appURL.appending(path: "Contents", directoryHint: .isDirectory).appending(path: "MacOS", directoryHint: .isDirectory).appending(path: appURL.deletingPathExtension().lastPathComponent, directoryHint: .notDirectory),
                                        arguments: [
                                            "--sub-file=\(subtitlesURL.absoluteString)",
                                            movieURL.absoluteString,
                                        ],
                                    )
                                } catch {
                                    self.error = error
                                    isErrorPresented = true
                                }
                            } else if let movie, let selectedQuality, let movieURL = movie.getClosestTo(quality: selectedQuality)?.hls {
                                do {
                                    try Process.run(
                                        appURL.appending(path: "Contents", directoryHint: .isDirectory).appending(path: "MacOS", directoryHint: .isDirectory).appending(path: appURL.deletingPathExtension().lastPathComponent, directoryHint: .notDirectory),
                                        arguments: [
                                            movieURL.absoluteString,
                                        ],
                                    )
                                } catch {
                                    self.error = error
                                    isErrorPresented = true
                                }
                            }
                        } label: {
                            Text(ExternalPlayers.vlc.localizedKey)
                                .frame(width: 250, height: 30)
                                .foregroundStyle(.white)
                                .background(selectedQuality != nil ? Color.accentColor : Color.secondary)
                                .clipShape(.rect(cornerRadius: 6))
                                .contentShape(.rect(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)
                        .disabled(selectedQuality == nil)
                    }
                } else {
                    Text("key.open.empty")
                        .frame(width: 250, height: 30)
                        .foregroundStyle(.white)
                        .background(Color.accentColor)
                        .clipShape(.rect(cornerRadius: 6))
                        .contentShape(.rect(cornerRadius: 6))
                }

                Button {
                    dismiss()
                } label: {
                    Text("key.cancel")
                        .frame(width: 250, height: 30)
                        .background(.quinary.opacity(0.5))
                        .clipShape(.rect(cornerRadius: 6))
                        .contentShape(.rect(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .alert("key.ops", isPresented: $isErrorPresented) {
            if let hdrezkaError = error as? HDrezkaError, case .loginRequired = hdrezkaError {
                Button(role: .destructive) {
                    dismiss()

                    appState.isSignInPresented = true
                } label: {
                    Text("key.sign_in")
                }
            }

            Button(role: .cancel) {
                dismiss()
            } label: {
                Text("key.ok")
            }
        } message: {
            if let error {
                Text(error.localizedDescription)
            }
        }
        .dialogSeverity(.critical)
        .confirmationDialog("key.sign_in.label", isPresented: $isLoginPresented) {
            Button {
                dismiss()

                appState.isSignInPresented = true
            } label: {
                Text("key.sign_in")
            }
        } message: {
            Text("key.sign_in.access")
        }
        .padding(.horizontal, 35)
        .padding(.top, 35)
        .padding(.bottom, 25)
        .fixedSize(horizontal: false, vertical: true)
        .frame(width: 520)
        .task {
            getMovieDetailsUseCase(movieId: id)
                .receive(on: DispatchQueue.main)
                .sink { completion in
                    guard case let .failure(error) = completion else { return }

                    self.error = error
                    isErrorPresented = true
                } receiveValue: { details in
                    withAnimation(.easeInOut) {
                        self.details = details
                    }
                }
                .store(in: &subscriptions)
        }
        .onChange(of: details) {
            if let details, let acting = details.voiceActing {
                withAnimation(.easeInOut) {
                    selectedActing = if !isLoggedIn,
                                        let position = selectPositions.first(where: { $0.id == details.movieId.id }),
                                        let first = acting.filter({ isUserPremium != nil || !$0.isPremium }).first(where: { $0.translatorId == position.acting })
                    {
                        first
                    } else if let series = details.series,
                              let first = acting.filter({ isUserPremium != nil || !$0.isPremium }).first(where: { $0.translatorId == series.acting })
                    {
                        first
                    } else if let first = acting.filter({ isUserPremium != nil || !$0.isPremium }).first(where: { $0.isSelected }) {
                        first
                    } else if let first = acting.filter({ isUserPremium != nil || !$0.isPremium }).first {
                        first
                    } else if let first = acting.first {
                        first
                    } else {
                        nil
                    }
                }
            }
        }
        .onChange(of: selectedActing) {
            withAnimation(.easeInOut) {
                selectedSeason = nil
                selectedEpisode = nil
                selectedQuality = nil
                seasons = nil
                movie = nil
            }

            if let details, let selectedActing {
                if details.series != nil {
                    if let movieId = details.movieId.id {
                        getSeriesSeasonsUseCase(movieId: movieId, voiceActing: selectedActing, favs: details.favs)
                            .receive(on: DispatchQueue.main)
                            .sink { completion in
                                guard case let .failure(error) = completion else { return }

                                self.error = error
                                isErrorPresented = true
                            } receiveValue: { seasons in
                                withAnimation(.easeInOut) {
                                    self.seasons = seasons

                                    selectedSeason = if !isLoggedIn,
                                                        let position = selectPositions.first(where: { $0.id == selectedActing.voiceId }),
                                                        let first = seasons.first(where: { $0.seasonId == position.season })
                                    {
                                        first
                                    } else if let series = details.series,
                                              let first = seasons.first(where: { $0.seasonId == series.season })
                                    {
                                        first
                                    } else if let first = seasons.first(where: { $0.isSelected }) {
                                        first
                                    } else if let first = seasons.first {
                                        first
                                    } else {
                                        nil
                                    }
                                }
                            }
                            .store(in: &subscriptions)
                    } else {
                        if !isErrorPresented {
                            isErrorPresented = true
                        }
                    }
                } else {
                    getMovieVideoUseCase(voiceActing: selectedActing, season: nil, episode: nil, favs: details.favs)
                        .receive(on: DispatchQueue.main)
                        .sink { completion in
                            guard case let .failure(error) = completion else { return }

                            self.error = error
                            isErrorPresented = true
                        } receiveValue: { movie in
                            if movie.needPremium {
                                dismiss()

                                appState.isPremiumPresented = true
                            } else {
                                withAnimation(.easeInOut) {
                                    self.movie = movie

                                    if defaultQuality != .ask,
                                       defaultQuality != .highest,
                                       movie.getAvailableQualities().contains(defaultQuality.rawValue)
                                    {
                                        selectedQuality = defaultQuality.rawValue
                                    } else if defaultQuality == .highest,
                                              let highest = movie.getAvailableQualities().last
                                    {
                                        selectedQuality = highest
                                    }

                                    selectedSubtitles = movie.subtitles.first(where: { $0.lang == selectPositions.first(where: { position in position.id == selectedActing.voiceId })?.subtitles?.replacingOccurrences(of: "uk", with: "ua") })
                                }
                            }
                        }
                        .store(in: &subscriptions)
                }
            }
        }
        .onChange(of: selectedSeason) {
            withAnimation(.easeInOut) {
                selectedQuality = nil
                movie = nil

                selectedEpisode = if !isLoggedIn,
                                     let position = selectPositions.first(where: { $0.id == selectedActing?.voiceId }),
                                     let first = selectedSeason?.episodes.first(where: { $0.episodeId == position.episode })
                {
                    first
                } else if let series = details?.series,
                          let first = selectedSeason?.episodes.first(where: { $0.episodeId == series.episode })
                {
                    first
                } else if let first = selectedSeason?.episodes.first(where: { $0.isSelected }) {
                    first
                } else if let first = selectedSeason?.episodes.first {
                    first
                } else {
                    nil
                }
            }
        }
        .onChange(of: selectedEpisode) {
            withAnimation(.easeInOut) {
                selectedQuality = nil
                movie = nil
            }

            if let details, let selectedSeason, let selectedEpisode, let selectedActing {
                getMovieVideoUseCase(voiceActing: selectedActing, season: selectedSeason, episode: selectedEpisode, favs: details.favs)
                    .receive(on: DispatchQueue.main)
                    .sink { completion in
                        guard case let .failure(error) = completion else { return }

                        self.error = error
                        isErrorPresented = true
                    } receiveValue: { movie in
                        if movie.needPremium {
                            dismiss()

                            appState.isPremiumPresented = true
                        } else {
                            withAnimation(.easeInOut) {
                                self.movie = movie

                                if defaultQuality != .ask,
                                   defaultQuality != .highest,
                                   movie.getAvailableQualities().contains(defaultQuality.rawValue)
                                {
                                    selectedQuality = defaultQuality.rawValue
                                } else if defaultQuality == .highest,
                                          let highest = movie.getAvailableQualities().last
                                {
                                    selectedQuality = highest
                                }

                                selectedSubtitles = movie.subtitles.first(where: { $0.lang == selectPositions.first(where: { position in position.id == selectedActing.voiceId })?.subtitles?.replacingOccurrences(of: "uk", with: "ua") })
                            }
                        }
                    }
                    .store(in: &subscriptions)
            }
        }
    }

    private struct CustomLabelStyle: LabelStyle {
        private let iconVisible: Bool

        init(iconVisible: Bool = true) {
            self.iconVisible = iconVisible
        }

        func makeBody(configuration: Configuration) -> some View {
            HStack(alignment: .center, spacing: 8) {
                configuration.title

                if iconVisible {
                    configuration.icon
                }
            }
        }
    }
}

enum ExternalPlayers: Int, CaseIterable, Identifiable {
    case iina = 0
    case infuse
    case mpv
    case vlc

    var id: Self { self }

    var url: URL {
        switch self {
        case .iina:
            URL(string: "iina://open")!
        case .infuse:
            URL(string: "infuse://x-callback-url/play")!
        case .mpv:
            URL(string: "mpv://temp")!
        case .vlc:
            URL(string: "vlc://temp")!
        }
    }

    var bundleIdentifier: String {
        switch self {
        case .iina:
            "com.colliderli.iina"
        case .infuse:
            "com.firecore.infuse"
        case .mpv:
            "io.mpv"
        case .vlc:
            "org.videolan.vlc"
        }
    }

    var localizedKey: LocalizedStringKey {
        switch self {
        case .iina:
            "key.open.iina"
        case .infuse:
            "key.open.infuse"
        case .mpv:
            "key.open.mpv"
        case .vlc:
            "key.open.vlc"
        }
    }
}
