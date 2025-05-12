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
                        ProgressRowView(download: download)

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

    private struct ProgressRowView: View {
        private let download: Download

        init(download: Download) {
            self.download = download
        }

        @State private var fractionCompleted: Double?
        @State private var localizedAdditionalDescription: String?
        @State private var subscriptions: Set<AnyCancellable> = []

        var body: some View {
            HStack(alignment: .center, spacing: 15) {
                if let fractionCompleted, let localizedAdditionalDescription {
                    ProgressView(value: fractionCompleted) {
                        Text(download.name)
                    } currentValueLabel: {
                        Text(localizedAdditionalDescription)
                    }
                    .progressViewStyle(.linear)
                } else {
                    ProgressView()
                        .progressViewStyle(.linear)
                }

                Button {
                    download.cancel()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.accent)
                        .font(.system(size: 15))
                }
                .buttonStyle(.plain)
            }
            .task {
                subscriptions.forEach { $0.cancel() }
                subscriptions.removeAll()

                download.progress.publisher(for: \.fractionCompleted)
                    .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
                    .sink { fractionCompleted in
                        self.fractionCompleted = fractionCompleted
                    }
                    .store(in: &subscriptions)

                download.progress.publisher(for: \.localizedAdditionalDescription)
                    .throttle(for: .seconds(1), scheduler: DispatchQueue.main, latest: true)
                    .sink { localizedAdditionalDescription in
                        self.localizedAdditionalDescription = localizedAdditionalDescription
                    }
                    .store(in: &subscriptions)
            }
        }
    }
}
