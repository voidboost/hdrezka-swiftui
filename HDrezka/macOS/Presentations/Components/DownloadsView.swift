import Combine
import SwiftUI

struct DownloadsView: View {
    @Environment(Downloader.self) private var downloader

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(alignment: .leading, spacing: 5) {
                if downloader.downloads.isEmpty {
                    Text("key.downloads.empty")
                } else {
                    ForEach(downloader.downloads, id: \.gid) { download in
                        HStack(alignment: .center, spacing: 15) {
                            ProgressView(download.progress)
                                .progressViewStyle(.linear)

                            if let status = download.status {
                                Button {
                                    if status.status == .paused {
                                        downloader.unpause(download.gid)
                                    } else {
                                        downloader.pause(download.gid)
                                    }
                                } label: {
                                    Image(systemName: status.status == .paused ? "play.circle.fill" : "pause.circle.fill")
                                        .font(.title3)
                                        .contentTransition(.symbolEffect(.replace))
                                }
                                .buttonStyle(.plain)
                            }

                            Button {
                                downloader.remove(download.gid)
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(Color.accentColor)
                                    .font(.title3)
                            }
                            .buttonStyle(.plain)
                        }

                        if download != downloader.downloads.last {
                            Divider()
                        }
                    }
                }
            }
            .padding(15)
            .animation(.easeInOut, value: downloader.downloads)
        }
        .scrollIndicators(.never)
        .frame(maxHeight: 200)
    }
}
