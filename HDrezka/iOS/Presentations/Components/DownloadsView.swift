import SwiftUI

struct DownloadsView: View {
    private let title = String(localized: "key.downloads")

    @Environment(Downloader.self) private var downloader

    var body: some View {
        List {
            ForEach(downloader.downloads) { download in
                ProgressView(download.progress)
                    .contextMenu {
                        Button {
                            withAnimation(.easeInOut) {
                                download.cancel()
                                downloader.downloads.removeAll(where: { $0.id == download.id })
                            }
                        } label: {
                            Text("key.cancel")
                        }
                    }
            }
            .onDelete { offsets in
                for offset in offsets {
                    withAnimation(.easeInOut) {
                        downloader.downloads[offset].cancel()
                        downloader.downloads.remove(at: offset)
                    }
                }
            }
        }
        .overlay {
            if downloader.downloads.isEmpty {
                Text("key.downloads.empty")
            }
        }
        .scrollIndicators(.visible, axes: .vertical)
        .viewModifier { view in
            if #available(iOS 26, *) {
                view.scrollEdgeEffectStyle(.soft, for: .all)
            } else {
                view
            }
        }
        .transition(.opacity)
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.large)
        .background(.background)
    }
}

#Preview {
    DownloadsView()
}
