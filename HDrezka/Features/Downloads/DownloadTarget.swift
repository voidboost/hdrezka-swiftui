import Foundation

struct DownloadTarget {
    let folder: URL
    let directory: URL
    let fileName: String
    let season: MovieSeason?
    let episode: MovieEpisode?

    var fileURL: URL {
        directory.appending(path: fileName, directoryHint: .notDirectory)
    }

    func subtitlesFileName(_ subtitles: MovieSubtitles, url: URL) -> String {
        fileName.replacingOccurrences(of: ".mp4", with: " [\(subtitles.name)].\(url.pathExtension)")
    }
}

extension DownloadData {
    var target: DownloadTarget? {
        guard let folder = resolvedFolder else { return nil }

        let name = details.nameRussian
        let actingName = acting.name.isEmpty ? "" : " [\(acting.name)]"
        let qualityName = quality.isEmpty ? "" : " [\(quality)]"
        let suffixLength = actingName.count + qualityName.count

        guard let season, let episode else {
            let file = name.count > 255 - 4 - suffixLength ? "\(name.prefix(255 - 8 - suffixLength))... \(qualityName)\(actingName).mp4" : "\(name)\(qualityName)\(actingName).mp4"

            return DownloadTarget(folder: folder, directory: folder, fileName: file.fileSystemSafe, season: nil, episode: nil)
        }

        let seasonName = String(localized: "key.season-\(season.name.contains(/^\d/) ? season.name : season.seasonId)")
        let episodeName = String(localized: "key.episode-\(episode.name.contains(/^\d/) ? episode.name : episode.episodeId)")

        let movieFolder = name.count > 255 - suffixLength ? "\(name.prefix(255 - suffixLength - 4))... \(qualityName)\(actingName)" : "\(name)\(qualityName)\(actingName)"
        let seasonFolder = seasonName.count > 255 ? "\(seasonName.prefix(255 - 3))..." : seasonName
        let file = episodeName.count > 255 - 4 ? "\(episodeName.prefix(255 - 8))... .mp4" : "\(episodeName).mp4"

        let directory = folder
            .appending(path: movieFolder.fileSystemSafe, directoryHint: .isDirectory)
            .appending(path: seasonFolder.fileSystemSafe, directoryHint: .isDirectory)

        return DownloadTarget(folder: folder, directory: directory, fileName: file.fileSystemSafe, season: season, episode: episode)
    }

    private var resolvedFolder: URL? {
        guard let folder else {
            return FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first?.appending(path: "HDrezka", directoryHint: .isDirectory)
        }

        var isStale = false

        return try? URL(resolvingBookmarkData: folder, options: .withSecurityScope, bookmarkDataIsStale: &isStale)
    }
}

private extension String {
    var fileSystemSafe: String {
        replacingOccurrences(of: ":", with: ".").replacingOccurrences(of: "/", with: ":")
    }
}
