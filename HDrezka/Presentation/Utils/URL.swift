import Foundation

extension URL {
    var hls: URL? { URL(string: "\(absoluteString):hls:manifest.m3u8") }
}
