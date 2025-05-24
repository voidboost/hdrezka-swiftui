import Defaults
import NukeUI
import SwiftUI

struct PersonView: View {
    private let person: PersonSimple
        
    @StateObject private var vm = PersonViewModel()
    
    @State private var showBar: Bool = false
    
    @Default(.mirror) private var mirror
    @Default(.isLoggedIn) private var isLoggedIn
    
    init(person: PersonSimple) {
        self.person = person
    }
    
    var body: some View {
        Group {
            if let error = vm.state.error {
                ErrorStateView(error, person.name) {
                    vm.getDetails(id: person.personId)
                }
                .padding(.vertical, 52)
                .padding(.horizontal, 36)
            } else if let details = vm.state.data {
                ScrollView(.vertical) {
                    LazyVStack(alignment: .leading, spacing: 18) {
                        PersonViewComponent(details: details)
                    }
                    .padding(.vertical, 52)
                    .padding(.vertical, 18)
                    .onGeometryChange(for: Bool.self) { geometry in
                        -geometry.frame(in: .named("scroll")).origin.y / 52 >= 1
                    } action: { showBar in
                        withAnimation(.easeInOut(duration: 0.15)) {
                            self.showBar = showBar
                        }
                    }
                }
                .coordinateSpace(name: "scroll")
                .scrollIndicators(.never)
            } else {
                LoadingStateView(person.name)
                    .padding(.vertical, 52)
                    .padding(.horizontal, 36)
            }
        }
        .navigationBar(title: person.name, showBar: showBar, navbar: {
            if case .data = vm.state {
                Button {
                    vm.getDetails(id: person.personId)
                } label: {
                    Image(systemName: "arrow.trianglehead.clockwise")
                }
                .buttonStyle(NavbarButtonStyle(width: 30, height: 22))
                .keyboardShortcut("r", modifiers: .command)
            }
        }, toolbar: {
            if case .data = vm.state {
                CustomShareLink(items: [(mirror != _mirror.defaultValue ? mirror : Const.redirectMirror).appending(path: person.personId, directoryHint: .notDirectory)]) {
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
                vm.getDetails(id: person.personId)
            }
        }
        .background(.background)
    }

    private struct PersonViewComponent: View {
        private let details: PersonDetailed
        
        @Environment(\.openWindow) private var openWindow
        
        init(details: PersonDetailed) {
            self.details = details
        }
                        
        var body: some View {
            HStack(alignment: .bottom, spacing: 27) {
                Button {
                    if let url = URL(string: details.hphoto) ?? URL(string: details.photo) {
                        openWindow(id: "imageViewer", value: url)
                    }
                } label: {
                    LazyImage(url: URL(string: details.hphoto), transaction: .init(animation: .easeInOut)) { state in
                        if let image = state.image {
                            image.resizable()
                                .transition(
                                    .asymmetric(
                                        insertion: .wipe(blurRadius: 10),
                                        removal: .wipe(reversed: true, blurRadius: 10)
                                    )
                                )
                        } else {
                            LazyImage(url: URL(string: details.photo), transaction: .init(animation: .easeInOut)) { state in
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
                    .frame(width: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .contentShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
        
                VStack(alignment: .leading, spacing: 16) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(details.nameRu)
                            .font(.largeTitle.weight(.semibold))
                            .textSelection(.enabled)
                                
                        if let nameOriginal = details.nameOrig {
                            Text(nameOriginal)
                                .font(.system(size: 15))
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
                        .background(.quinary)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(.tertiary, lineWidth: 1)
                        }
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
                        
                    Spacer()
                        
                    Text(info).font(.system(size: 13)).foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .padding(.vertical, 8)
            }
        }
        
        private struct MoviesRow: View {
            private let title: String
            private let movies: [MovieSimple]
            
            @EnvironmentObject private var appState: AppState

            init(_ title: String, _ movies: [MovieSimple]) {
                self.title = title
                self.movies = movies
            }
            
            var body: some View {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(alignment: .center, spacing: 9) {
                        Text(title).font(.system(size: 22).bold())
                        
                        Spacer()
                        
                        if movies.count > 10 {
                            Button {
                                appState.path.append(.customList(movies, title))
                            } label: {
                                HStack(alignment: .center) {
                                    Text("key.see_all")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.accent)

                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.accent)
                                }
                                .highlightOnHover()
                            }
                            .buttonStyle(.plain)
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
}
