import CoreImage.CIFilterBuiltins
import Defaults
import Nuke
import NukeUI
import SwiftUI
import Vision
import YouTubePlayerKit

struct DetailsView: View {
    private let movie: MovieSimple
    
    @State private var vm = DetailsViewModel()
    
    @Default(.isLoggedIn) private var isLoggedIn
    @Default(.mirror) private var mirror
    @Environment(AppState.self) private var appState
    
    @State private var isBookmarksPresented = false
    @State private var isCreateBookmarkPresented = false
    @State private var isSchedulePresented = false
    
    @State private var showBar: Bool = false
    
    init(movie: MovieSimple) {
        self.movie = movie
    }
    
    var body: some View {
        Group {
            if let error = vm.state.error {
                ErrorStateView(error, movie.name) {
                    vm.getDetails(id: movie.movieId)
                }
                .padding(.vertical, 52)
                .padding(.horizontal, 36)
            } else if let details = vm.state.data {
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        DetailsViewComponent(details: details, trailer: vm.trailer, isSchedulePresented: $isSchedulePresented) { rating in
                            if let id = details.movieId.id {
                                vm.rate(id: id, rating: rating)
                            }
                        }
                    }
                }
                .scrollIndicators(.never)
                .onGeometryChange(for: Bool.self) { geometry in
                    -geometry.frame(in: .scrollView).origin.y / 52 >= 1
                } action: { showBar in
                    withAnimation(.easeInOut(duration: 0.15)) {
                        self.showBar = showBar
                    }
                }
            } else {
                LoadingStateView(movie.name)
                    .padding(.vertical, 52)
                    .padding(.horizontal, 36)
            }
        }
        .navigationBar(title: vm.state.data?.nameRussian ?? movie.name ?? "", showBar: showBar, navbar: {
            if case .data = vm.state {
                Button {
                    vm.getDetails(id: movie.movieId)
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .buttonStyle(NavbarButtonStyle(width: 30, height: 22))
                .keyboardShortcut("r", modifiers: .command)
            }
        }, toolbar: {
            if let details = vm.state.data {
                Button {
                    appState.path.append(.comments(details))
                } label: {
                    HStack(alignment: .center, spacing: 4) {
                        Image(systemName: "bubble.left.and.bubble.right")
                                
                        if details.commentsCount > 0 {
                            Text("(\(details.commentsCount.description))")
                        }
                    }
                }
                .buttonStyle(NavbarButtonStyle(height: 22, hPadding: 8))
                        
                Divider()
                    .padding(.vertical, 18)

                if isLoggedIn {
                    Button {
                        isBookmarksPresented = true
                    } label: {
                        Image(systemName: "bookmark")
                    }
                    .buttonStyle(NavbarButtonStyle(width: 30, height: 22))

                    Divider()
                        .padding(.vertical, 18)
                }
                             
                CustomShareLink(items: [
                    (mirror != _mirror.defaultValue ? mirror : Const.redirectMirror).appending(path: movie.movieId, directoryHint: .notDirectory),
                    Const.details.appending(queryItems: [.init(name: "id", value: movie.movieId)])
                ]) {
                    Image(systemName: "square.and.arrow.up")
                }
                .buttonStyle(NavbarButtonStyle(width: 30, height: 22))
            }
        })
        .load(isLoggedIn) {
            switch vm.state {
            case .data:
                break
            default:
                vm.getDetails(id: movie.movieId)
            }
        }
        .sheet(isPresented: $isBookmarksPresented) {
            BookmarksSheetView(movie: movie, isCreateBookmarkPresented: $isCreateBookmarkPresented)
        }
        .sheet(isPresented: $isCreateBookmarkPresented) {
            CreateBookmarkSheetView()
        }
        .sheet(isPresented: $isSchedulePresented) {
            if let details = vm.state.data, let schedule = details.schedule, !schedule.isEmpty {
                ScheduleSheetView(schedule: schedule)
            }
        }
        .alert("key.ops", isPresented: $vm.isErrorPresented) {
            Button("key.ok", role: .cancel) {}
        } message: {
            if let error = vm.error {
                Text(error.localizedDescription)
            }
        }
        .dialogSeverity(.critical)
        .onChange(of: isCreateBookmarkPresented) {
            isBookmarksPresented = !isCreateBookmarkPresented
        }
        .background(.background)
    }

    private struct DetailsViewComponent: View {
        private let details: MovieDetailed
        private let trailer: YouTubePlayer?
        @Binding private var isSchedulePresented: Bool
        private let rate: (Int) -> Void
        
        @Environment(AppState.self) private var appState

        init(details: MovieDetailed, trailer: YouTubePlayer?, isSchedulePresented: Binding<Bool>, rate: @escaping (Int) -> Void) {
            self.details = details
            self.trailer = trailer
            self._isSchedulePresented = isSchedulePresented
            self.rate = rate
        }
        
        @State private var isPlayPresented: Bool = false
        @State private var isDownloadPresented: Bool = false
        
        @State private var franchiseExpanded: Bool = false
        
        @State private var blurHeght: CGFloat = .zero
        @State private var showImage: Bool = false

        @Environment(\.openURL) private var openURL
        @Environment(\.colorScheme) private var colorScheme
        @Environment(\.openWindow) private var openWindow
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
                            LazyImage(url: URL(string: details.hposter), transaction: .init(animation: .easeInOut)) { state in
                                if let image = state.image {
                                    image.resizable()
                                        .transition(
                                            .asymmetric(
                                                insertion: .wipe(blurRadius: 10),
                                                removal: .wipe(reversed: true, blurRadius: 10)
                                            )
                                        )
                                } else {
                                    LazyImage(url: URL(string: details.poster), transaction: .init(animation: .easeInOut)) { state in
                                        if let image = state.image {
                                            image.resizable()
                                                .transition(
                                                    .asymmetric(
                                                        insertion: .wipe(blurRadius: 10),
                                                        removal: .wipe(reversed: true, blurRadius: 10)
                                                    )
                                                )
                                        } else {
                                            Rectangle()
                                                .fill(.gray)
                                                .shimmering()
                                                .transition(
                                                    .asymmetric(
                                                        insertion: .wipe(blurRadius: 10),
                                                        removal: .wipe(reversed: true, blurRadius: 10)
                                                    )
                                                )
                                        }
                                    }
                                    .onDisappear(.cancel)
                                    .transition(
                                        .asymmetric(
                                            insertion: .wipe(blurRadius: 10),
                                            removal: .wipe(reversed: true, blurRadius: 10)
                                        )
                                    )
                                }
                            }
                            .onDisappear(.cancel)
                            .imageFill(2 / 3)
                            .frame(width: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .contentShape(RoundedRectangle(cornerRadius: 6))
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(details.nameRussian)
                                    .font(.largeTitle.weight(.semibold))
                                    .textSelection(.enabled)
                                
                                if let nameOriginal = details.nameOriginal {
                                    Text(nameOriginal)
                                        .font(.system(size: 15))
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
                                            .font(.system(size: 13))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                    }
                                    .buttonStyle(.plain)
                                    .background(.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 40))
                                    .contentShape(RoundedRectangle(cornerRadius: 40))
                                    .sheet(isPresented: $isPlayPresented) {
                                        WatchSheetView(id: details.movieId)
                                    }
                                    
                                    Button {
                                        isDownloadPresented = true
                                    } label: {
                                        Label("key.download", systemImage: "arrow.down.circle")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.accent)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                    }
                                    .buttonStyle(.plain)
                                    .background(.tertiary.opacity(0.05))
                                    .clipShape(RoundedRectangle(cornerRadius: 40))
                                    .contentShape(RoundedRectangle(cornerRadius: 40))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 40)
                                            .stroke(.tertiary.opacity(0.2), lineWidth: 1)
                                    }
                                    .sheet(isPresented: $isDownloadPresented) {
                                        DownloadSheetView(id: details.movieId)
                                    }
                                } else if details.comingSoon {
                                    Button {} label: {
                                        Label("key.soon", systemImage: "clock")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                    }
                                    .buttonStyle(.plain)
                                    .background(.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 40))
                                    .disabled(true)
                                } else {
                                    Button {} label: {
                                        Label("key.unavailable", systemImage: "network.slash")
                                            .font(.system(size: 13))
                                            .foregroundStyle(.white)
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 7)
                                    }
                                    .buttonStyle(.plain)
                                    .background(.accent)
                                    .clipShape(RoundedRectangle(cornerRadius: 40))
                                    .disabled(true)
                                }
                            }
                            
                            if details.slogan?.isEmpty == false
                                ||
                                details.releaseDate?.isEmpty == false
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
                                    
                                    if let countries = details.countries, !countries.isEmpty {
                                        if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false {
                                            Divider()
                                        }
                                        
                                        InfoRowWithButtons(String(localized: "key.info.country"), String(localized: "key.info.country.description"), countries)
                                    }
                                    
                                    if let genres = details.genres, !genres.isEmpty {
                                        if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.countries?.isEmpty == false {
                                            Divider()
                                        }
                                        
                                        InfoRowWithButtons(String(localized: "key.info.genres"), String(localized: "key.info.genres.description"), genres)
                                    }

                                    if let producer = details.producer, !producer.isEmpty {
                                        if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.countries?.isEmpty == false || details.genres?.isEmpty == false {
                                            Divider()
                                        }
                                        
                                        InfoRowWithButtons(String(localized: "key.info.producer"), String(localized: "key.info.producer.description"), producer)
                                    }
                                    
                                    if let actors = details.actors, !actors.isEmpty {
                                        if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.countries?.isEmpty == false || details.genres?.isEmpty == false || details.producer?.isEmpty == false {
                                            Divider()
                                        }
                                        
                                        InfoRowWithButtons(String(localized: "key.info.actors"), String(localized: "key.info.actors.description"), actors)
                                    }
                                    
                                    if let lists = details.lists, !lists.isEmpty {
                                        if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.countries?.isEmpty == false || details.genres?.isEmpty == false || details.producer?.isEmpty == false || details.actors?.isEmpty == false {
                                            Divider()
                                        }
                                        
                                        InfoRowWithButtons(String(localized: "key.info.lists"), String(localized: "key.info.lists.description"), lists)
                                    }
                                    
                                    if let collections = details.collections, !collections.isEmpty {
                                        if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.countries?.isEmpty == false || details.genres?.isEmpty == false || details.producer?.isEmpty == false || details.actors?.isEmpty == false || details.lists?.isEmpty == false {
                                            Divider()
                                        }
                                        
                                        InfoRowWithButtons(String(localized: "key.info.collections"), String(localized: "key.info.collections.description"), collections)
                                    }
                                    
                                    if let rating = details.rating {
                                        if details.slogan?.isEmpty == false || details.releaseDate?.isEmpty == false || details.countries?.isEmpty == false || details.genres?.isEmpty == false || details.producer?.isEmpty == false || details.actors?.isEmpty == false || details.lists?.isEmpty == false || details.collections?.isEmpty == false {
                                            Divider()
                                        }
                                        
                                        InfoRowRating(String(localized: "key.info.rating"), rating, details.rated, details.votes) { rating in
                                            rate(rating)
                                        }
                                    }
                                }
                                .padding(.horizontal, 10)
                                .background(.quinary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(.tertiary, lineWidth: 1)
                                }
                            }
                        }
                    }
                    
                    Divider().opacity(0)
                }
                .onGeometryChange(for: CGFloat.self) { geometry in
                    geometry.size.height
                } action: { height in
                    self.blurHeght = height
                }
                
                if details.imdbRating != nil
                    ||
                    details.kpRating != nil
                    ||
                    details.duration != nil
                    ||
                    details.ageRestriction != nil
                {
                    HStack(alignment: .center) {
                        if let imdbRating = details.imdbRating {
                            let color = Color(
                                NSColor
                                    .red
                                    .blended(withFraction: CGFloat(imdbRating.value / 10.0), of: NSColor.green) ?? NSColor.labelColor
                            )
                            
                            InfoColumn("IMDb", imdbRating.value.description, StarsView(rating: imdbRating.value * 0.5, color: color), valueColor: color, hover: imdbRating.votesCount) {
                                if let url = URL(string: imdbRating.link) {
                                    openURL(url)
                                }
                            }
                        }
                    
                        if let kpRating = details.kpRating {
                            let color = Color(
                                NSColor
                                    .red
                                    .blended(withFraction: CGFloat(kpRating.value / 10.0), of: NSColor.green) ?? NSColor.labelColor
                            )
                            
                            InfoColumn("КиноПоиск", kpRating.value.description, StarsView(rating: kpRating.value * 0.5, color: color), valueColor: color, hover: kpRating.votesCount) {
                                if let url = URL(string: kpRating.link) {
                                    openURL(url)
                                }
                            }
                        }
                    
                        if let duration = details.duration, duration > 0 {
                            InfoColumn(String(localized: "key.info.duration"), duration.description, Text(String(localized: "key.info.minutes-\(duration)").trimmingCharacters(in: .letters.inverted).lowercased()).font(.system(size: 13).weight(.medium)))
                        }
                    
                        if let ageRestriction = details.ageRestriction, !ageRestriction.isEmpty {
                            InfoColumn(String(localized: "key.info.age"), ageRestriction, Text(String(localized: "key.info.years_old").lowercased()).font(.system(size: 13).weight(.medium)))
                        }
                    }
                
                    Divider()
                }
            }
            .padding(.horizontal, 36)
            .padding(.top, 18)
            .padding(.top, 52)
            .background {
                ZStack(alignment: .topLeading) {
                    if showImage {
                        LazyImage(url: URL(string: details.poster), transaction: .init(animation: .easeInOut)) { state in
                            if let image = state.image {
                                image.resizable()
                            } else {
                                Rectangle()
                                    .fill(.gray)
                            }
                        }
                        .onDisappear(.cancel)
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: blurHeght)
                        .clipShape(Rectangle())
                    }
                    
                    VStack {}
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThickMaterial)
//                        .ifLet(movie.cat) { view, cat in
//                            view.overlay {
//                                HStack {
//                                    Divider()
//                                        .background(cat.color.opacity(0.5))
//
//                                    Spacer()
//
//                                    Divider()
//                                        .background(cat.color.opacity(0.5))
//                                }
//                            }
//                        }
                       
                    VStack {}
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.background)
                        .mask {
                            LinearGradient(stops: [
                                .init(color: .black.opacity(0.3), location: 0.9),
                                .init(color: .black, location: 1.0)
                            ],
                            startPoint: .top,
                            endPoint: .bottom)
                        }
                }
                .task {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                        withAnimation(.easeInOut) {
                            self.showImage = true
                        }
                    }
                }
            }
            
            HStack(alignment: .center, spacing: 18) {
                Text(details.description)
                    .font(.system(size: 15))
                    .textSelection(.enabled)
                                
                if let trailer {
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
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(RoundedRectangle(cornerRadius: 6))
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
                                    .font(.system(size: 17).bold())
                                
                                Spacer()
                            }
                        
                            LazyVStack(alignment: .leading, spacing: 0) {
                                ForEach(franchise.prefix(franchiseExpanded ? franchise.count : 5)) { fr in
                                    if !fr.current {
                                        Button {
                                            appState.path.append(.details(MovieSimple(movieId: fr.franchiseId, name: fr.name)))
                                        } label: {
                                            HStack(alignment: .center, spacing: 4) {
                                                ZStack(alignment: .center) {
                                                    ZStack(alignment: .center) {
                                                        Text(fr.position.description)
                                                            .font(.system(size: 11))
                                                            .foregroundStyle(.white)
                                                    }
                                                    .frame(width: 19, height: 19)
                                                    .background(LinearGradient(colors: [.secondary.opacity(colorScheme == .dark ? 1 : 0.5), .secondary.opacity(colorScheme == .dark ? 0.5 : 1)], startPoint: .top, endPoint: .bottom))
                                                    .clipShape(RoundedRectangle(cornerRadius: 6))
                                                }
                                                .frame(width: 24, height: 24)
                                                
                                                VStack(alignment: .leading) {
                                                    Text(fr.name).font(.system(size: 13))
                                                        .lineLimit(1)
                                                    
                                                    if let rating = fr.rating {
                                                        let color = Color(
                                                            NSColor
                                                                .red
                                                                .blended(withFraction: CGFloat(rating / 10.0), of: NSColor.green) ?? NSColor.labelColor
                                                        )
        
                                                        Text("\(String(localized: "key.franchise.year-\(fr.year)")) • \(Text(rating.description).foregroundStyle(color)) \(Text(Image(systemName: "star.fill")).font(.system(size: 9)).foregroundStyle(color))").font(.system(size: 11)).foregroundStyle(.secondary)
                                                    } else {
                                                        Text("key.franchise.year-\(fr.year)").font(.system(size: 11)).foregroundStyle(.secondary)
                                                    }
                                                }
                                            
                                                Spacer()
                                                
                                                Image(systemName: "chevron.right").font(.system(size: 13))
                                            }
                                            .contentShape(Rectangle())
                                        }
                                        .buttonStyle(.plain)
                                        .padding(.vertical, 8)
                                    } else {
                                        HStack(alignment: .center, spacing: 4) {
                                            ZStack(alignment: .center) {
                                                ZStack(alignment: .center) {
                                                    Text(String(fr.position))
                                                        .font(.system(size: 11))
                                                        .foregroundStyle(.white)
                                                }
                                                .frame(width: 19, height: 19)
                                                .background(LinearGradient(colors: [.accent.opacity(colorScheme == .dark ? 1 : 0.5), .accent.opacity(colorScheme == .dark ? 0.5 : 1)], startPoint: .top, endPoint: .bottom))
                                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                            }
                                            .frame(width: 24, height: 24)
                                        
                                            VStack(alignment: .leading) {
                                                Text(fr.name).font(.system(size: 13))
                                                    .lineLimit(1)
                                                
                                                if let rating = fr.rating {
                                                    let color = Color(
                                                        NSColor
                                                            .red
                                                            .blended(withFraction: CGFloat(rating / 10.0), of: NSColor.green) ?? NSColor.labelColor
                                                    )
    
                                                    Text("\(String(localized: "key.franchise.year-\(fr.year)")) • \(Text(rating.description).foregroundStyle(color)) \(Text(Image(systemName: "star.fill")).font(.system(size: 9)).foregroundStyle(color))").font(.system(size: 11)).foregroundStyle(.secondary)
                                                } else {
                                                    Text("key.franchise.year-\(fr.year)").font(.system(size: 11)).foregroundStyle(.secondary)
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
                                                .font(.system(size: 13))
                                                .highlightOnHover()
                                        }
                                        .buttonStyle(.plain)
                                        
                                        Spacer()
                                    }
                                    .padding(.vertical, 8)
                                }
                            }
                            .padding(.horizontal, 10)
                            .background(.quinary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(.tertiary, lineWidth: 1)
                            }
                        }
                    }
                    
                    if let schedule = details.schedule, let first = schedule.first {
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("key.schedule")
                                    .font(.system(size: 17).bold())
                                
                                Spacer()
                            }
                            
                            VStack(alignment: .leading, spacing: 10) {
                                Text(first.name)
                                    .font(.system(size: 15).bold())

                                LazyVStack(alignment: .leading, spacing: 0) {
                                    ForEach(first.items.prefix(5)) { item in
                                        HStack(alignment: .center) {
                                            VStack(alignment: .leading) {
                                                Text(item.russianEpisodeName)
                                                    .font(.system(size: 13))
                                                    .lineLimit(1)
                                                        
                                                if let originalEpisodeName = item.originalEpisodeName {
                                                    Text(originalEpisodeName)
                                                        .font(.system(size: 13))
                                                        .lineLimit(1)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                                    
                                            Spacer()
                                                    
                                            VStack(alignment: .trailing) {
                                                Text(item.releaseDate).font(.system(size: 13)).foregroundStyle(.secondary)

                                                Text(item.title).font(.system(size: 11)).foregroundStyle(.secondary)
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
                                                    .font(.system(size: 13))
                                                    .highlightOnHover()
                                            }
                                            .buttonStyle(.plain)
                                            
                                            Spacer()
                                        }
                                        .padding(.vertical, 8)
                                    }
                                }
                                .padding(.horizontal, 10)
                                .background(.quinary)
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(.tertiary, lineWidth: 1)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 36)
            }
            
            Divider()
                .padding(.horizontal, 36)

            VStack(alignment: .leading, spacing: 18) {
                Text("key.watch_also").font(.system(size: 22).bold())
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
            .padding(.bottom, 52)
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
                        .font(.system(size: 13))
                    
                    Spacer(minLength: 10)
                    
                    Text(info).font(.system(size: 13)).foregroundStyle(.secondary)
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
            
            @Environment(AppState.self) private var appState

            init(_ title: String, _ description: String, _ data: [T]) {
                self.title = title
                self.description = description
                self.data = data
            }
            
            var body: some View {
                HStack(alignment: .center) {
                    Text(title)
                        .font(.system(size: 13))
                    
                    Spacer(minLength: 10)

                    HStack(alignment: .center, spacing: 4) {
                        HStack(alignment: .center, spacing: 0) {
                            ForEach(data.prefix(2)) { item in
                                Button {
                                    appState.path.append(.fromNamed(item))
                                } label: {
                                    if let person = item as? PersonSimple, !person.photo.isEmpty {
                                        PersonTextWithPhoto(person: person)
                                            .contentShape(Rectangle())
                                    } else if let list = item as? MovieList, let position = list.moviePosition?.toNumeral() {
                                        Text(
                                            "\(Text(list.name).foregroundStyle(.secondary)) \(Text("key.place-\(position)").foregroundStyle(.tertiary))"
                                        )
                                        .font(.system(size: 13))
                                        .lineLimit(1)
                                        .truncationMode(.middle)
                                        .contentShape(Rectangle())
                                    } else {
                                        Text(item.name)
                                            .font(.system(size: 13))
                                            .foregroundStyle(.secondary)
                                            .lineLimit(1)
                                            .contentShape(Rectangle())
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                if item != data.prefix(2).last {
                                    Text(", ")
                                        .font(.system(size: 13))
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        
                        if data.count > 2 {
                            Button {
                                isPresented = true
                            } label: {
                                Image(systemName: "info.circle")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                            .popover(isPresented: $isPresented, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                                VStack(alignment: .center, spacing: 6) {
                                    Text(title)
                                        .font(.system(size: 13).bold())
                                        .multilineTextAlignment(.center)
                                    
                                    Text(description)
                                        .font(.system(size: 10))
                                        .multilineTextAlignment(.center)
                                    
                                    VStack(alignment: .center, spacing: 0) {
                                        ForEach(data) { item in
                                            Button {
                                                isPresented = false
                                                
                                                appState.path.append(.fromNamed(item))
                                            } label: {
                                                if let person = item as? PersonSimple, !person.photo.isEmpty {
                                                    HStack(alignment: .center, spacing: 8) {
                                                        LazyImage(url: URL(string: person.photo), transaction: .init(animation: .easeInOut)) { state in
                                                            if let image = state.image {
                                                                image.resizable()
                                                            } else {
                                                                Rectangle()
                                                                    .fill(.gray)
                                                                    .shimmering()
                                                            }
                                                        }
                                                        .processors([.process(id: person.photo) { $0.removeBackground() }])
                                                        .onDisappear(.cancel)
                                                        .imageFill(2 / 3)
                                                        .frame(width: 36, height: 36)
                                                        .background(.quinary)
                                                        .clipShape(RoundedRectangle(cornerRadius: 18))
                                                        .padding(2)
                                                        .overlay {
                                                            RoundedRectangle(cornerRadius: 20)
                                                                .stroke(.tertiary.opacity(0.2), lineWidth: 1)
                                                        }
                                                        
                                                        Text(person.name)
                                                            .font(.system(size: 13))
                                                            .lineLimit(nil)
                                                            .multilineTextAlignment(.center)
                                                    }
                                                    .contentShape(Rectangle())
                                                } else if let list = item as? MovieList, let position = list.moviePosition?.toNumeral() {
                                                    Text(
                                                        "\(Text(list.name)) \(Text("key.place-\(position)").foregroundStyle(.secondary))"
                                                    )
                                                    .font(.system(size: 13))
                                                    .lineLimit(nil)
                                                    .multilineTextAlignment(.center)
                                                    .contentShape(Rectangle())
                                                } else {
                                                    Text(item.name)
                                                        .font(.system(size: 13))
                                                        .lineLimit(nil)
                                                        .multilineTextAlignment(.center)
                                                        .contentShape(Rectangle())
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
            private let rate: (Int) -> Void
            
            @State private var hover: Float?
            @State private var vote: Bool = false
            
            @Default(.isLoggedIn) private var isLoggedIn

            init(_ title: String, _ rating: Float, _ rated: Bool, _ votes: String?, rate: @escaping (Int) -> Void) {
                self.title = title
                self.rating = rating
                self.rated = rated
                self.votes = votes
                self.rate = rate
            }
            
            private var stars: some View {
                HStack(spacing: 0) {
                    ForEach(0 ..< 10) { index in
                        if !rated, isLoggedIn {
                            Button {
                                rate(index + 1)
                            } label: {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 13, design: .rounded))
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
                                .font(.system(size: 13, design: .rounded))
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                }
            }
            
            var body: some View {
                HStack(alignment: .center) {
                    Text(title)
                        .font(.system(size: 13))
                    
                    Spacer(minLength: 10)

                    HStack(alignment: .center, spacing: 4) {
                        stars
                            .background {
                                GeometryReader { geometry in
                                    let width = (CGFloat(hover ?? rating) / 10.0) * geometry.size.width
                                    
                                    HStack {
                                        Rectangle()
                                            .frame(width: width)
                                            .foregroundStyle(hover != nil ? .primary : .secondary)
                                        
                                        Spacer(minLength: 0)
                                    }
                                }
                                .mask(stars)
                            }
                            .foregroundStyle(.tertiary)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 2) {
                            Text(rating.description)
                                .font(.system(size: 13).monospacedDigit())
                                .foregroundStyle(.secondary)
                                .contentTransition(.numericText(value: Double(rating)))
                                
                            if let votes, vote {
                                Text("(\(votes))")
                                    .font(.system(size: 9).monospacedDigit())
                                    .foregroundStyle(.secondary)
                                    .contentTransition(.numericText())
                            }
                        }
                        .ifLet(votes) { view, _ in
                            view.onHover { hover in
                                withAnimation(.easeInOut) {
                                    vote = hover
                                }
                            }
                        }
                    }
                }
                .padding(.vertical, 8)
            }
        }
        
        private struct PersonTextWithPhoto: View {
            private let person: PersonSimple
            @State private var show: Bool = false
            
            init(person: PersonSimple) {
                self.person = person
            }
            
            var body: some View {
                Text(person.name)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .onHover {
                        show = $0
                    }
                    .popover(isPresented: $show) {
                        LazyImage(url: URL(string: person.photo), transaction: .init(animation: .easeInOut)) { state in
                            if let image = state.image {
                                image.resizable()
                                    .transition(
                                        .asymmetric(
                                            insertion: .wipe(blurRadius: 10),
                                            removal: .wipe(reversed: true, blurRadius: 10)
                                        )
                                    )
                            } else {
                                Rectangle()
                                    .fill(.gray)
                                    .shimmering()
                                    .transition(
                                        .asymmetric(
                                            insertion: .wipe(blurRadius: 10),
                                            removal: .wipe(reversed: true, blurRadius: 10)
                                        )
                                    )
                            }
                        }
                        .processors([.process(id: person.photo) { $0.removeBackground() }])
                        .onDisappear(.cancel)
                        .imageFill(2 / 3)
                        .frame(width: 64, height: 64)
                        .background(.quinary)
                        .clipShape(RoundedRectangle(cornerRadius: 32))
                        .padding(4)
                        .overlay {
                            RoundedRectangle(cornerRadius: 36)
                                .stroke(.tertiary.opacity(0.2), lineWidth: 1)
                        }
                        .padding(4)
                    }
            }
        }
        
        private struct StarsView: View {
            private let rating: CGFloat
            private let color: Color
            
            init(rating: Float, color: Color = .accent) {
                self.rating = CGFloat(rating)
                self.color = color
            }
            
            private var stars: some View {
                HStack(spacing: 0) {
                    ForEach(0 ..< 5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 13, design: .rounded))
                            .aspectRatio(contentMode: .fit)
                    }
                }
            }
            
            var body: some View {
                stars
                    .overlay {
                        GeometryReader { geometry in
                            let width = (rating / 5.0) * geometry.size.width
                            
                            HStack {
                                Rectangle()
                                    .frame(width: width)
                                    .foregroundStyle(color)
                                
                                Spacer(minLength: 0)
                            }
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
            private let action: (() -> Void)?
            
            @State private var show: Bool = false

            init(_ title: String, _ value: String, _ subtitle: T, valueColor: Color? = nil, hover: String? = nil, action: (() -> Void)? = nil) {
                self.title = title
                self.value = value
                self.subtitle = subtitle
                self.hover = hover
                self.valueColor = valueColor
                self.action = action
            }
            
            var body: some View {
                HStack(alignment: .center, spacing: 0) {
                    Spacer()
                
                    if let action {
                        Button {
                            action()
                        } label: {
                            VStack(alignment: .center, spacing: 2) {
                                Text(title).font(.system(size: 13).weight(.medium))
                                
                                HStack(alignment: .firstTextBaseline, spacing: 2) {
                                    Text(value)
                                        .font(.system(size: 24, design: .rounded).weight(.semibold))
                                        .ifLet(valueColor) {
                                            $0.foregroundStyle($1)
                                        }
                                    
                                    if let hover, show {
                                        Text("(\(hover))")
                                            .font(.system(size: 11))
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .ifLet(hover) { view, _ in
                                    view.onHover { hover in
                                        withAnimation(.easeInOut) {
                                            show = hover
                                        }
                                    }
                                }
                                
                                subtitle
                            }
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        VStack(alignment: .center, spacing: 2) {
                            Text(title).font(.system(size: 13).weight(.medium))
                            
                            HStack(alignment: .center, spacing: 2) {
                                Text(value)
                                    .font(.system(size: 24, design: .rounded).weight(.semibold))
                                    .ifLet(valueColor) {
                                        $0.foregroundStyle($1)
                                    }
                                
                                if let hover, show {
                                    Text("(\(hover))")
                                        .font(.system(size: 11))
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .ifLet(hover) { view, _ in
                                view.onHover { hover in
                                    withAnimation(.easeInOut) {
                                        show = hover
                                    }
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
}

private extension PlatformImage {
    func removeBackground() -> PlatformImage? {
        func processImage(image: CGImage) -> PlatformImage? {
            let inputImage = CIImage(cgImage: image)
            let handler = VNImageRequestHandler(ciImage: inputImage)
            let request = VNGenerateForegroundInstanceMaskRequest()
            
            do { try handler.perform([request]) } catch { return nil }
                      
            guard let result = request.results?.first,
                  let maskPixelBuffer = try? result.generateScaledMaskForImage(forInstances: result.allInstances, from: handler),
                  let outputImage = apply(maskImage: CIImage(cvPixelBuffer: maskPixelBuffer), to: inputImage)
            else {
                return nil
            }
                
            return render(ciImage: outputImage)
        }

        func apply(maskImage: CIImage, to inputImage: CIImage) -> CIImage? {
            let filter = CIFilter.blendWithMask()
            filter.inputImage = inputImage
            filter.maskImage = maskImage
            filter.backgroundImage = CIImage.empty()
            return filter.outputImage
        }

        func render(ciImage: CIImage) -> PlatformImage? {
            guard let cgImage = CIContext(options: nil).createCGImage(ciImage, from: ciImage.extent) else { return nil }
            
            return .init(cgImage: cgImage, size: CGSize(width: cgImage.width, height: cgImage.height))
        }
        
        guard let cgImage = cgImage(forProposedRect: nil, context: nil, hints: nil) else { return self }

        return processImage(image: cgImage) ?? self
    }
}
