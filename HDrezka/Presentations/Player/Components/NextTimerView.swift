import SwiftUI

struct NextTimerView: View {
    @Environment(PlayerViewModel.self) private var viewModel

    var body: some View {
        Group {
            if let nextTimer = viewModel.nextTimer, viewModel.isSeries, let seasons = viewModel.seasons, let season = viewModel.season, let episode = viewModel.episode {
                Button {
                    viewModel.nextTrack()
                } label: {
                    HStack(alignment: .center, spacing: 21) {
                        VStack(alignment: .leading) {
                            HStack(alignment: .bottom, spacing: 7) {
                                Image(systemName: "waveform.circle")
                                    .font(.title2.bold())

                                Text("key.next")
                                    .font(.title2.bold())
                            }
                            .foregroundStyle(Color.accentColor)

                            Spacer(minLength: 0)

                            if let nextEpisode = season.episodes.element(after: episode) {
                                Text("key.season-\(season.name).episode-\(nextEpisode.name)")
                                    .font(.title2.bold())
                            } else if let nextSeason = seasons.element(after: season), let nextEpisode = nextSeason.episodes.first {
                                Text("key.season-\(nextSeason.name).episode-\(nextEpisode.name)")
                                    .font(.title2.bold())
                            }
                        }

                        Image(systemName: "play.circle")
                            .resizable()
                            .frame(width: 28, height: 28)
                            .background(Color.accentColor, in: .circle.inset(by: -7).rotation(.degrees(-90)).trim(from: 0.0, to: nextTimer).stroke(style: .init(lineWidth: 6, lineCap: .round, lineJoin: .round)))
                            .background(.ultraThickMaterial, in: .circle.inset(by: -7).rotation(.degrees(-90)).trim(from: 0.0, to: nextTimer).stroke(style: .init(lineWidth: 8, lineCap: .round, lineJoin: .round)))
                            .background(Color.accentColor.opacity(0.3), in: .circle.inset(by: -7).rotation(.degrees(-90)).stroke(style: .init(lineWidth: 4, lineCap: .round, lineJoin: .round)))
                    }
                    .frame(height: 50)
                    .padding(.vertical, 16)
                    .padding(.leading, 16)
                    .padding(.trailing, 36)
                    .contentShape(.rect(topLeadingRadius: 6, bottomLeadingRadius: 6))
                    .background(.ultraThickMaterial, in: .rect(topLeadingRadius: 6, bottomLeadingRadius: 6))
                }
                .buttonStyle(.plain)
                .padding(.top, 102)
                .shadow(color: .black.opacity(0.5), radius: 4, y: 2)
            }
        }
    }
}
