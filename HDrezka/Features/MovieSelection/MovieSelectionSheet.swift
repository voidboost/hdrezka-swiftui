import ComposableArchitecture
import Defaults
import Dependencies
import SwiftUI

struct MovieSelectionSheet<Actions: View>: View {
    @Bindable var store: StoreOf<MovieSelectionFeature>

    private let icon: String
    private let description: LocalizedStringKey
    private let showsSubtitles: Bool
    private let actions: Actions

    init(store: StoreOf<MovieSelectionFeature>, icon: String, description: LocalizedStringKey, showsSubtitles: Bool, @ViewBuilder actions: () -> Actions) {
        self.store = store
        self.icon = icon
        self.description = description
        self.showsSubtitles = showsSubtitles
        self.actions = actions()
    }

    private var details: MovieDetailed? { store.details }
    private var seasons: [MovieSeason]? { store.seasons }
    private var movie: MovieVideo? { store.movie }
    private var error: (any Error)? { store.error?.base }

    private var selectedActing: MovieVoiceActing? {
        get { store.selectedActing }
        nonmutating set { store.selectedActing = newValue }
    }

    private var selectedSeason: MovieSeason? {
        get { store.selectedSeason }
        nonmutating set { store.selectedSeason = newValue }
    }

    private var selectedEpisode: MovieEpisode? {
        get { store.selectedEpisode }
        nonmutating set { store.selectedEpisode = newValue }
    }

    private var selectedQuality: String? {
        get { store.selectedQuality }
        nonmutating set { store.selectedQuality = newValue }
    }

    private var selectedSubtitles: MovieSubtitles? {
        get { store.selectedSubtitles }
        nonmutating set { store.selectedSubtitles = newValue }
    }

    @Environment(\.dismiss) private var dismiss

    @Dependency(\.appRouter) private var appRouter

    @Default(.isUserPremium) private var isUserPremium
    @Default(.isLoggedIn) private var isLoggedIn

    @State private var isLoginPresented: Bool = false

    @State private var showRating: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 25) {
            VStack(alignment: .center, spacing: 5) {
                Image(systemName: icon)
                    .font(.largeTitle)
                    .foregroundStyle(Color.accentColor)

                Text("key.before_starting")
                    .font(.largeTitle.weight(.semibold))

                Text(description)
                    .font(.title3)
                    .lineLimit(2, reservesSpace: true)
                    .multilineTextAlignment(.center)
            }

            selection

            VStack(alignment: .center, spacing: 10) {
                actions

                Button {
                    dismiss()
                } label: {
                    Text("key.cancel")
                        .frame(width: 250, height: 30)
                        .contentShape(.rect(cornerRadius: 6))
                        .background(.quinary.opacity(0.5), in: .rect(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .alert("key.ops", isPresented: $store.isErrorPresented) {
            if let hdrezkaError = error as? HDrezkaError, case .loginRequired = hdrezkaError {
                Button(role: .destructive) {
                    dismiss()

                    appRouter.present(.signIn)
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

                appRouter.present(.signIn)
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
        .onAppear {
            store.send(.onAppear)
        }
    }

    @ViewBuilder
    private var selection: some View {
        if let details {
            VStack(spacing: 18) {
                if details.series != nil || (details.voiceActing ?? []).contains(where: { !$0.name.isEmpty }) {
                    VStack(spacing: 2.5) {
                        if let acting = details.voiceActing, acting.contains(where: { !$0.name.isEmpty }) {
                            HStack {
                                Text("key.acting")

                                if let rating = details.voiceActingRating?.sorted(by: { $0.percent > $1.percent }), !rating.isEmpty {
                                    Button {
                                        showRating = true
                                    } label: {
                                        Image(systemName: "questionmark.circle")
                                            .foregroundStyle(Color.accentColor)
                                            .font(.subheadline)
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
                                        .scrollIndicators(.visible, axes: .vertical)
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

                                                        appRouter.present(.premium)
                                                    }
                                                } label: {
                                                    Label {
                                                        Text(acting.name)
                                                    } icon: {
                                                        Image(.premium)
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
                                .disabled(acting.isEmpty != false)
                            }
                            .padding(.vertical, 10)
                            .overlay {
                                if acting.isEmpty != false {
                                    ProgressView().scaleEffect(0.6)
                                }
                            }
                        }

                        if details.series != nil, selectedActing != nil {
                            if (details.voiceActing ?? []).contains(where: { !$0.name.isEmpty }) {
                                Divider()
                            }

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
                                .disabled(seasons?.isEmpty != false)
                            }
                            .padding(.vertical, 10)
                            .overlay {
                                if seasons?.isEmpty != false {
                                    ProgressView().scaleEffect(0.6)
                                }
                            }

                            Divider()

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
                                .disabled(selectedSeason?.episodes.isEmpty != false)
                            }
                            .padding(.vertical, 10)
                            .overlay {
                                if selectedSeason?.episodes.isEmpty != false {
                                    ProgressView().scaleEffect(0.6)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 5)
                    .background(.quinary, in: .rect(cornerRadius: 6))
                    .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                }

                if (details.series == nil && selectedActing != nil) || selectedEpisode != nil {
                    HStack {
                        Text("key.quality")

                        if let selectedQuality, let movie, let links = movie.getClosestTo(quality: selectedQuality) {
                            ForEach(links, id: \.self) { link in
                                ShareLink(item: link) {
                                    Image(systemName: "square.and.arrow.up")
                                        .foregroundStyle(.secondary)
                                        .font(.subheadline)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Spacer()

                        Menu {
                            if !(movie?.getAccountQualities() ?? []).isEmpty {
                                Section {
                                    ForEach(movie?.getAccountQualities() ?? [], id: \.self) { quality in
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

                            if !(movie?.getPremiumQualities() ?? []).isEmpty {
                                Section {
                                    ForEach(movie?.getPremiumQualities() ?? [], id: \.self) { quality in
                                        Button {
                                            if isUserPremium != nil {
                                                withAnimation(.easeInOut) {
                                                    selectedQuality = quality
                                                }
                                            } else {
                                                dismiss()

                                                appRouter.present(.premium)
                                            }
                                        } label: {
                                            Text(quality)
                                        }
                                    }
                                } header: {
                                    Text("key.premium")
                                }

                                Divider()
                            }

                            if !(movie?.getLockedQualities() ?? []).isEmpty {
                                Section {
                                    ForEach(movie?.getLockedQualities() ?? [], id: \.self) { quality in
                                        Button {
                                            if isUserPremium != nil, isLoggedIn {
                                                withAnimation(.easeInOut) {
                                                    selectedQuality = quality
                                                }
                                            } else if isLoggedIn {
                                                dismiss()

                                                appRouter.present(.premium)
                                            } else if isUserPremium != nil {
                                                isLoginPresented = true
                                            }
                                        } label: {
                                            Text(quality)
                                        }
                                    }
                                } header: {
                                    Text("key.locked")
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
                        .labelStyle(CustomLabelStyle(iconVisible: ((movie?.getAvailableQualities().count ?? 0) + (movie?.getAccountQualities().count ?? 0) + (movie?.getPremiumQualities().count ?? 0) + (movie?.getLockedQualities().count ?? 0)) > 1))
                        .disabled(movie?.getAvailableQualities().isEmpty != false)
                    }
                    .padding(.horizontal, 15)
                    .padding(.vertical, 15)
                    .background(.quinary, in: .rect(cornerRadius: 6))
                    .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                    .overlay {
                        if movie?.getAvailableQualities().isEmpty != false {
                            ProgressView().scaleEffect(0.6)
                        }
                    }
                }

                if showsSubtitles, let movie, !movie.subtitles.isEmpty {
                    HStack {
                        Text("key.subtitles")

                        if let selectedSubtitles, let subtitles = movie.subtitles.first(where: { $0 == selectedSubtitles }), let url = URL(string: subtitles.link) {
                            ShareLink(item: url) {
                                Image(systemName: "square.and.arrow.up")
                                    .foregroundStyle(.secondary)
                                    .font(.subheadline)
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
                    .padding(.horizontal, 15)
                    .padding(.vertical, 15)
                    .background(.quinary, in: .rect(cornerRadius: 6))
                    .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                }
            }
        } else {
            ProgressView()
        }
    }

    private struct CustomLabelStyle: LabelStyle {
        private let iconVisible: Bool

        init(iconVisible: Bool = true) {
            self.iconVisible = iconVisible
        }

        func makeBody(configuration: LabelStyle.Configuration) -> some View {
            HStack(alignment: .center, spacing: 8) {
                configuration.title

                if iconVisible {
                    configuration.icon
                }
            }
        }
    }
}

struct MovieSelectionActionButton: View {
    private let title: LocalizedStringKey
    private let isActive: Bool
    private let action: () -> Void

    init(_ title: LocalizedStringKey, isActive: Bool, action: @escaping () -> Void) {
        self.title = title
        self.isActive = isActive
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(width: 250, height: 30)
                .foregroundStyle(.white)
                .contentShape(.rect(cornerRadius: 6))
                .background(isActive ? Color.accentColor : Color.secondary, in: .rect(cornerRadius: 6))
        }
        .buttonStyle(.plain)
        .disabled(!isActive)
    }
}
