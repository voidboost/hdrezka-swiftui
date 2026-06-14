import Foundation

extension URL {
    var hls: URL? {
        URL(string: "\(absoluteString):hls:manifest.m3u8")
    }

    var id: String? {
        guard pathComponents.count(where: { $0 != "/" }) == 3,
              pathExtension == "html"
        else {
            return nil
        }

        let id = lastPathComponent.substringBefore("-")

        guard !id.isEmpty, id.isNumber else { return nil }

        return id
    }

    var cleanPath: String? {
        guard !path().isEmpty else { return nil }

        return String(path().trimmingPrefix("/"))
    }

    var cleanFragment: String? {
        guard let fragment = fragment(),
              !fragment.isEmpty
        else {
            return nil
        }

        return fragment
    }
}
