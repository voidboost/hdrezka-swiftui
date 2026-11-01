import ComposableArchitecture
import SwiftUI

struct DownloadsView: View {
    let store: StoreOf<DownloadsFeature>

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .center, spacing: 5) {
                if store.downloads.isEmpty {
                    Text("key.downloads.empty")
                } else {
                    ForEach(store.downloads) { download in
                        HStack(alignment: .center, spacing: 15) {
                            ProgressView(download.progress)
                                .progressViewStyle(.linear)

                            if let status = download.status {
                                Button {
                                    if status.status == .paused {
                                        store.send(.unpauseTapped(gid: download.gid))
                                    } else {
                                        store.send(.pauseTapped(gid: download.gid))
                                    }
                                } label: {
                                    Image(systemName: status.status == .paused ? "play.circle.fill" : "pause.circle.fill")
                                        .font(.title3)
                                        .contentTransition(.symbolEffect(.replace))
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                store.send(.removeTapped(gid: download.gid))
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                        }

                        if download != store.downloads.last {
                            Divider()
                        }
                    }
                }
            }
            .padding(15)
            .animation(.easeInOut, value: store.downloads)
        }
        .scrollIndicators(.visible, axes: .vertical)
        .frame(minHeight: 100, maxHeight: 200)
    }
}
