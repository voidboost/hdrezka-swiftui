import Kingfisher
import SwiftUI
import YouTubePlayerKit

struct DetailsComponentView: View {
    private let details: MovieDetailed
    private let trailerId: String?
    private let topSafeAreaInset: CGFloat
    @Binding private var isSchedulePresented: Bool

    @Environment(Downloader.self) private var downloader

    init(details: MovieDetailed,
         trailerId: String?,
         topSafeAreaInset: CGFloat,
         isSchedulePresented: Binding<Bool>)
    {
        self.details = details
        self.trailerId = trailerId
        self.topSafeAreaInset = topSafeAreaInset
        _isSchedulePresented = isSchedulePresented
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

                        DetailsInfoRowsView(details: details)
                    }
                }

                Divider().opacity(0)
            }
            .onGeometryChange(for: CGFloat.self) { geometry in
                geometry.size.height
            } action: { height in
                blurHeght = height
            }

            DetailsInfoColumnsView(details: details)
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
                        showFullscreenButton: true
                    ),
                    configuration: .init(
                        openURLAction: .init { url, _ in
                            openURL(url)
                        }
                    ),
                    isLoggingEnabled: isLoggingEnabled
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
                        Task { @MainActor in
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
                                if !fr.current, let movieId = fr.franchiseId {
                                    NavigationLink(value: Destinations.details(MovieSimple(movieId: movieId, name: fr.name))) {
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
                            .equatable()
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
