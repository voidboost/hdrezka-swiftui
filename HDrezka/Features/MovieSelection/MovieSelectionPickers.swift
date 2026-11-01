import ComposableArchitecture
import Defaults
import Dependencies
import SwiftUI

struct ActingPicker: View {
    @Bindable var store: StoreOf<MovieSelectionFeature>
    let acting: [MovieVoiceActing]
    let rating: [MovieVoiceActingRating]

    @Environment(\.dismiss) private var dismiss
    @Dependency(\.appRouter) private var appRouter
    @Default(.isUserPremium) private var isUserPremium

    @State private var showRating: Bool = false

    var body: some View {
        let others = acting.filter { $0 != store.selectedActing }
        let premium = others.filter(\.isPremium)

        SelectionRow("key.acting", value: value, isMenuIconVisible: acting.count > 1, isLoading: acting.isEmpty) {
            if !rating.isEmpty {
                ratingButton
            }
        } items: {
            if !premium.isEmpty {
                Section {
                    ForEach(premium) { acting in
                        Button {
                            if isUserPremium != nil {
                                withAnimation(.easeInOut) {
                                    store.selectedActing = acting
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

            ForEach(others.filter { !$0.isPremium }) { acting in
                Button {
                    withAnimation(.easeInOut) {
                        store.selectedActing = acting
                    }
                } label: {
                    Text(acting.name)
                }
            }
        }
    }

    private var value: String {
        guard let selectedActing = store.selectedActing else { return String(localized: "key.acting.select") }

        return selectedActing.name.isEmpty ? String(localized: "key.default") : selectedActing.name
    }

    private var ratingButton: some View {
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
}

struct SeasonPicker: View {
    @Bindable var store: StoreOf<MovieSelectionFeature>

    var body: some View {
        let seasons = store.seasons ?? []

        SelectionRow("key.season", value: value, isMenuIconVisible: seasons.count > 1, isLoading: seasons.isEmpty) {
            ForEach(seasons.filter { $0 != store.selectedSeason }) { season in
                Button {
                    withAnimation(.easeInOut) {
                        store.selectedSeason = season
                    }
                } label: {
                    Text(season.name.contains(/^\d/) ? String(localized: "key.season-\(season.name)") : season.name)
                }
            }
        }
    }

    private var value: String {
        guard let selectedSeason = store.selectedSeason else { return String(localized: "key.season.select") }

        if selectedSeason.name.isEmpty {
            return String(localized: "key.season-\(1)")
        }

        return selectedSeason.name.contains(/^\d/) ? String(localized: "key.season-\(selectedSeason.name)") : selectedSeason.name
    }
}

struct EpisodePicker: View {
    @Bindable var store: StoreOf<MovieSelectionFeature>

    var body: some View {
        let episodes = store.selectedSeason?.episodes ?? []

        SelectionRow("key.episode", value: value, isMenuIconVisible: episodes.count > 1, isLoading: episodes.isEmpty) {
            ForEach(episodes.filter { $0 != store.selectedEpisode }) { episode in
                Button {
                    withAnimation(.easeInOut) {
                        store.selectedEpisode = episode
                    }
                } label: {
                    Text(episode.name.contains(/^\d/) ? String(localized: "key.episode-\(episode.name)") : episode.name)
                }
            }
        }
    }

    private var value: String {
        guard let selectedEpisode = store.selectedEpisode else { return String(localized: "key.episode.select") }

        if selectedEpisode.name.isEmpty {
            return String(localized: "key.episode-\(1)")
        }

        return selectedEpisode.name.contains(/^\d/) ? String(localized: "key.episode-\(selectedEpisode.name)") : selectedEpisode.name
    }
}

struct QualityPicker: View {
    @Bindable var store: StoreOf<MovieSelectionFeature>
    @Binding var isLoginPresented: Bool

    @Environment(\.dismiss) private var dismiss
    @Dependency(\.appRouter) private var appRouter
    @Default(.isUserPremium) private var isUserPremium
    @Default(.isLoggedIn) private var isLoggedIn

    var body: some View {
        let available = store.movie?.getAvailableQualities() ?? []
        let account = store.movie?.getAccountQualities() ?? []
        let premium = store.movie?.getPremiumQualities() ?? []
        let locked = store.movie?.getLockedQualities() ?? []

        SelectionRow("key.quality", value: value, isMenuIconVisible: available.count + account.count + premium.count + locked.count > 1, isLoading: available.isEmpty) {
            if let selectedQuality = store.selectedQuality, let links = store.movie?.getClosestTo(quality: selectedQuality) {
                ForEach(links, id: \.self) { link in
                    ShareButton(url: link)
                }
            }
        } items: {
            section("key.sign_in.access", account) { quality in
                if isLoggedIn {
                    select(quality)
                } else {
                    isLoginPresented = true
                }
            }

            section("key.premium", premium) { quality in
                if isUserPremium != nil {
                    select(quality)
                } else {
                    presentPremium()
                }
            }

            section("key.locked", locked) { quality in
                if isUserPremium != nil, isLoggedIn {
                    select(quality)
                } else if isLoggedIn {
                    presentPremium()
                } else if isUserPremium != nil {
                    isLoginPresented = true
                }
            }

            ForEach(available.filter { $0 != store.selectedQuality }, id: \.self) { quality in
                Button {
                    select(quality)
                } label: {
                    Text(quality)
                }
            }
        }
    }

    private var value: String {
        guard let selectedQuality = store.selectedQuality else { return String(localized: "key.quality.select") }

        return selectedQuality.isEmpty ? String(localized: "key.default") : selectedQuality
    }

    @ViewBuilder
    private func section(_ header: LocalizedStringKey, _ qualities: [String], action: @escaping (String) -> Void) -> some View {
        if !qualities.isEmpty {
            Section {
                ForEach(qualities, id: \.self) { quality in
                    Button {
                        action(quality)
                    } label: {
                        Text(quality)
                    }
                }
            } header: {
                Text(header)
            }

            Divider()
        }
    }

    private func select(_ quality: String) {
        withAnimation(.easeInOut) {
            store.selectedQuality = quality
        }
    }

    private func presentPremium() {
        dismiss()

        appRouter.present(.premium)
    }
}

struct SubtitlesPicker: View {
    @Bindable var store: StoreOf<MovieSelectionFeature>
    let subtitles: [MovieSubtitles]

    var body: some View {
        SelectionRow("key.subtitles", value: value, isMenuIconVisible: !subtitles.isEmpty, isLoading: false) {
            if let selectedSubtitles = store.selectedSubtitles, let url = subtitles.first(where: { $0 == selectedSubtitles }).flatMap({ URL(string: $0.link) }) {
                ShareButton(url: url)
            }
        } items: {
            if store.selectedSubtitles != nil {
                Button {
                    withAnimation(.easeInOut) {
                        store.selectedSubtitles = nil
                    }
                } label: {
                    Text("key.none")
                }
            }

            ForEach(subtitles.filter { $0 != store.selectedSubtitles }) { subtitles in
                Button {
                    withAnimation(.easeInOut) {
                        store.selectedSubtitles = subtitles
                    }
                } label: {
                    Text(subtitles.name)
                }
            }
        }
    }

    private var value: String {
        guard let selectedSubtitles = store.selectedSubtitles else { return String(localized: "key.subtitles.select") }

        return selectedSubtitles.name.isEmpty ? String(localized: "key.default") : selectedSubtitles.name
    }
}

private struct SelectionRow<Accessory: View, Items: View>: View {
    private let title: LocalizedStringKey
    private let value: String
    private let isMenuIconVisible: Bool
    private let isLoading: Bool
    private let accessory: Accessory
    private let items: Items

    init(_ title: LocalizedStringKey, value: String, isMenuIconVisible: Bool, isLoading: Bool, @ViewBuilder accessory: () -> Accessory, @ViewBuilder items: () -> Items) {
        self.title = title
        self.value = value
        self.isMenuIconVisible = isMenuIconVisible
        self.isLoading = isLoading
        self.accessory = accessory()
        self.items = items()
    }

    var body: some View {
        HStack {
            Text(title)

            accessory

            Spacer()

            Menu {
                items
            } label: {
                Label(value, systemImage: "chevron.up.chevron.down")
            }
            .menuStyle(.button)
            .menuIndicator(.hidden)
            .buttonStyle(.plain)
            .labelStyle(MenuLabelStyle(iconVisible: isMenuIconVisible))
            .disabled(isLoading)
        }
        .overlay {
            if isLoading {
                ProgressView().scaleEffect(0.6)
            }
        }
    }
}

extension SelectionRow where Accessory == EmptyView {
    init(_ title: LocalizedStringKey, value: String, isMenuIconVisible: Bool, isLoading: Bool, @ViewBuilder items: () -> Items) {
        self.init(title, value: value, isMenuIconVisible: isMenuIconVisible, isLoading: isLoading, accessory: { EmptyView() }, items: items)
    }
}

private struct MenuLabelStyle: LabelStyle {
    let iconVisible: Bool

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .center, spacing: 8) {
            configuration.title

            if iconVisible {
                configuration.icon
            }
        }
    }
}

private struct ShareButton: View {
    let url: URL

    var body: some View {
        ShareLink(item: url) {
            Image(systemName: "square.and.arrow.up")
                .foregroundStyle(.secondary)
                .font(.subheadline)
        }
        .buttonStyle(.plain)
    }
}
