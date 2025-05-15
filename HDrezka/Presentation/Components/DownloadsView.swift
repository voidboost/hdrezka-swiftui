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
                    ForEach(downloader.downloads) { download in
                        HStack(alignment: .center, spacing: 15) {
                            ProgressView(download.progress)
                                .progressViewStyle(.linear)

                            Button {
                                download.cancel()
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.accent)
                                    .font(.system(size: 15))
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
