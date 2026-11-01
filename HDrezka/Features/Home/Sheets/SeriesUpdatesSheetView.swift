import ComposableArchitecture
import FirebaseAnalytics
import SwiftUI

struct SeriesUpdatesSheetView: View {
    let store: StoreOf<SeriesUpdatesFeature>

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .center, spacing: 25) {
            VStack(spacing: 5) {
                Image(systemName: "bell")
                    .font(.largeTitle)
                    .foregroundStyle(Color.accentColor)

                Text("key.series_updates")
                    .font(.largeTitle.weight(.semibold))
            }

            Group {
                if let error = store.seriesUpdates.error {
                    VStack(alignment: .center, spacing: 9) {
                        Text(error.localizedDescription)
                            .lineLimit(nil)

                        Button {
                            store.send(.reload)
                        } label: {
                            Text("key.retry")
                                .foregroundStyle(Color.accentColor)
                        }
                        .buttonStyle(.accessoryBar)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let seriesUpdates = store.seriesUpdates.data {
                    if seriesUpdates.isEmpty {
                        VStack(alignment: .center, spacing: 9) {
                            Text("key.empty")

                            Button {
                                store.send(.reload)
                            } label: {
                                Text("key.retry")
                                    .foregroundStyle(Color.accentColor)
                            }
                            .buttonStyle(.accessoryBar)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(.vertical) {
                            LazyVStack(alignment: .leading, spacing: 10) {
                                ForEach(seriesUpdates) { group in
                                    CustomSection(group: group, isExpanded: group.id == seriesUpdates.first?.id) { movie in
                                        store.send(.movieTapped(movie))
                                    }

                                    if group.id != seriesUpdates.last?.id {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .scrollIndicators(.visible, axes: .vertical)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                } else {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }

            Button {
                dismiss()
            } label: {
                Text("key.done")
                    .frame(width: 250, height: 30)
                    .contentShape(.rect(cornerRadius: 6))
                    .background(.quinary.opacity(0.5), in: .rect(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 35)
        .padding(.top, 35)
        .padding(.bottom, 25)
        .frame(width: 520, height: 520)
        .onAppear {
            store.send(.reload)
        }
        .analyticsScreen(name: "series_updates_sheet", class: "SeriesUpdatesSheetView")
    }

    private struct CustomSection: View {
        private let group: SeriesUpdateGroup
        private let episodes: [SeriesUpdateItem]

        @State private var isExpanded: Bool

        private let onSelect: (MovieSimple) -> Void

        init(group: SeriesUpdateGroup, isExpanded: Bool, onSelect: @escaping (MovieSimple) -> Void) {
            self.group = group
            episodes = group.releasedEpisodes.filter(\.tracked) + group.releasedEpisodes.filter { !$0.tracked }
            self.isExpanded = isExpanded
            self.onSelect = onSelect
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 9) {
                Button {
                    withAnimation(.easeInOut) {
                        isExpanded.toggle()
                    }
                } label: {
                    Label(group.date, systemImage: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.title3.bold())
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(episodes) { item in
                            Button {
                                onSelect(.init(movieId: item.seriesId, name: item.seriesName))
                            } label: {
                                HStack(alignment: .center) {
                                    Text(verbatim: "\(item.seriesName) \(item.season)")
                                        .font(.body)
                                        .lineLimit(nil)

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(item.releasedEpisode).font(.subheadline).foregroundStyle(.secondary)
                                            .multilineTextAlignment(.trailing)

                                        if !item.chosenVoiceActing.isEmpty {
                                            HStack(spacing: 3) {
                                                if item.isChosenVoiceActingPremium {
                                                    Image(.premium)
                                                        .font(.subheadline)
                                                        .foregroundStyle(.white.opacity(0.8))
                                                }

                                                Text(item.chosenVoiceActing)
                                                    .font(.subheadline)
                                                    .foregroundStyle(item.isChosenVoiceActingPremium ? .white.opacity(0.8) : .secondary)
                                                    .multilineTextAlignment(.trailing)
                                            }
                                            .viewModifier { view in
                                                if item.isChosenVoiceActingPremium {
                                                    view
                                                        .padding(.vertical, 2)
                                                        .padding(.horizontal, 6)
                                                        .background(Const.premiumGradient, in: .capsule)
                                                } else {
                                                    view
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 8)
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)

                            if item.id != episodes.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .background(.quinary, in: .rect(cornerRadius: 6))
                    .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                }
            }
        }
    }
}
