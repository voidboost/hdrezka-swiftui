import Combine
import FactoryKit
import SwiftUI

struct SeriesUpdatesSheetView: View {
    @Injected(\.getSeriesUpdatesUseCase) private var getSeriesUpdatesUseCase

    @State private var subscriptions: Set<AnyCancellable> = []

    @State private var state: DataState<[SeriesUpdateGroup]> = .loading

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .center, spacing: 25) {
            VStack(spacing: 5) {
                Image(systemName: "bell")
                    .font(.system(size: 48))
                    .foregroundStyle(Color.accentColor)

                Text("key.series_updates")
                    .font(.largeTitle.weight(.semibold))
            }

            Group {
                if let error = state.error {
                    VStack(alignment: .center, spacing: 9) {
                        Text(error.localizedDescription)
                            .lineLimit(nil)

                        Button {
                            load()
                        } label: {
                            Text("key.retry")
                                .foregroundStyle(Color.accentColor)
                                .highlightOnHover()
                        }
                        .buttonStyle(.plain)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let seriesUpdates = state.data {
                    if seriesUpdates.isEmpty {
                        VStack(alignment: .center, spacing: 9) {
                            Text("key.empty")

                            Button {
                                load()
                            } label: {
                                Text("key.retry")
                                    .foregroundStyle(Color.accentColor)
                                    .highlightOnHover()
                            }
                            .buttonStyle(.plain)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(.vertical) {
                            LazyVStack(alignment: .leading, spacing: 10) {
                                ForEach(seriesUpdates) { group in
                                    CustomSection(group: group, dismiss: { dismiss() }, isExpanded: seriesUpdates.firstIndex(of: group) == 0)

                                    if group != seriesUpdates.last {
                                        Divider()
                                    }
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        .scrollIndicators(.never)
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
                    .background(.quinary.opacity(0.5))
                    .clipShape(.rect(cornerRadius: 6))
                    .contentShape(.rect(cornerRadius: 6))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 35)
        .padding(.top, 35)
        .padding(.bottom, 25)
        .frame(width: 520, height: 520)
        .task {
            load()
        }
    }

    private func load() {
        withAnimation(.easeInOut) {
            state = .loading
        }

        getSeriesUpdatesUseCase()
            .receive(on: DispatchQueue.main)
            .sink { completion in
                guard case let .failure(error) = completion else { return }

                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    withAnimation(.easeInOut) {
                        state = .error(error)
                    }
                }
            } receiveValue: { seriesUpdates in
                withAnimation(.easeInOut) {
                    state = .data(seriesUpdates)
                }
            }
            .store(in: &subscriptions)
    }

    private struct CustomSection: View {
        private let group: SeriesUpdateGroup

        private let dismiss: () -> Void

        @State private var isExpanded: Bool

        @EnvironmentObject private var appState: AppState

        init(group: SeriesUpdateGroup, dismiss: @escaping () -> Void, isExpanded: Bool) {
            self.group = group
            self.dismiss = dismiss
            self.isExpanded = isExpanded
        }

        var body: some View {
            VStack(alignment: .leading, spacing: 9) {
                Button {
                    withAnimation(.easeInOut) {
                        isExpanded.toggle()
                    }
                } label: {
                    Label(group.date, systemImage: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 15).bold())
                        .contentShape(.rect)
                }
                .buttonStyle(.plain)

                if isExpanded {
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(group.releasedEpisodes.filter(\.tracked)) { item in
                            Button {
                                dismiss()

                                appState.path.append(.details(MovieSimple(movieId: item.seriesId, name: item.seriesName)))
                            } label: {
                                HStack(alignment: .center) {
                                    Text(verbatim: "\(item.seriesName) \(item.season)")
                                        .font(.system(size: 13))
                                        .lineLimit(nil)

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(item.releasedEpisode).font(.system(size: 11)).foregroundStyle(.secondary)
                                            .multilineTextAlignment(.trailing)

                                        if !item.chosenVoiceActing.isEmpty {
                                            HStack(spacing: 3) {
                                                if item.isChosenVoiceActingPremium {
                                                    Image("Premium")
                                                        .renderingMode(.template)
                                                        .font(.system(size: 11))
                                                        .foregroundColor(.white.opacity(0.8))
                                                }

                                                Text(item.chosenVoiceActing)
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(item.isChosenVoiceActingPremium ? .white.opacity(0.8) : .secondary)
                                                    .multilineTextAlignment(.trailing)
                                            }
                                            .viewModifier { view in
                                                if item.isChosenVoiceActingPremium {
                                                    view
                                                        .padding(.vertical, 2)
                                                        .padding(.horizontal, 6)
                                                        .background(Const.premiumGradient)
                                                        .clipShape(.rect(cornerRadius: 40))
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

                            if item != group.releasedEpisodes.filter(\.tracked).last || !group.releasedEpisodes.filter({ !$0.tracked }).isEmpty {
                                Divider()
                            }
                        }

                        ForEach(group.releasedEpisodes.filter { !$0.tracked }) { item in
                            Button {
                                dismiss()

                                appState.path.append(.details(MovieSimple(movieId: item.seriesId, name: item.seriesName)))
                            } label: {
                                HStack(alignment: .center) {
                                    Text(verbatim: "\(item.seriesName) \(item.season)")
                                        .font(.system(size: 13))
                                        .lineLimit(nil)

                                    Spacer()

                                    VStack(alignment: .trailing, spacing: 2) {
                                        Text(item.releasedEpisode).font(.system(size: 11)).foregroundStyle(.secondary)
                                            .multilineTextAlignment(.trailing)

                                        if !item.chosenVoiceActing.isEmpty {
                                            HStack(spacing: 3) {
                                                if item.isChosenVoiceActingPremium {
                                                    Image("Premium")
                                                        .renderingMode(.template)
                                                        .font(.system(size: 11))
                                                        .foregroundColor(.white.opacity(0.8))
                                                }

                                                Text(item.chosenVoiceActing)
                                                    .font(.system(size: 11))
                                                    .foregroundStyle(item.isChosenVoiceActingPremium ? .white.opacity(0.8) : .secondary)
                                                    .multilineTextAlignment(.trailing)
                                            }
                                            .viewModifier { view in
                                                if item.isChosenVoiceActingPremium {
                                                    view
                                                        .padding(.vertical, 2)
                                                        .padding(.horizontal, 6)
                                                        .background(Const.premiumGradient)
                                                        .clipShape(.rect(cornerRadius: 40))
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

                            if item != group.releasedEpisodes.filter({ !$0.tracked }).last {
                                Divider()
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .background(.quinary)
                    .clipShape(.rect(cornerRadius: 6))
                    .overlay(.tertiary, in: .rect(cornerRadius: 6).stroke(lineWidth: 1))
                }
            }
        }
    }
}
