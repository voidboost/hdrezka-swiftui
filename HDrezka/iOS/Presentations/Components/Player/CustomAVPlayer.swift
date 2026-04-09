import AVFoundation
import Defaults
import FactoryKit
import Foundation

class CustomAVPlayer: AVPlayer, AVAssetResourceLoaderDelegate {
    @LazyInjected(\.session) private var session

    private let mainScheme = "mainm3u8"
    private let fragmentsScheme = "fragmentsm3u8"
    private let subtitlesScheme = "subtitlesm3u8"
    private let extInfPrefix = "#EXTINF:"

    private let urls: [URL]
    private let subtitles: [MovieSubtitles]

    private var m3u8String: String?
    private var playlistDuration: Double = 0.0

    private let loaderQueue = DispatchQueue(label: "resourceLoader")

    init?(urls: [URL], subtitles: [MovieSubtitles]) {
        guard let customURL = urls.first?.replaceURLScheme(with: mainScheme) else {
            return nil
        }

        self.urls = urls
        self.subtitles = subtitles

        super.init()

        let asset = AVURLAsset(url: customURL)
        asset.resourceLoader.setDelegate(self, queue: loaderQueue)

        let playerItem = AVPlayerItem(asset: asset)
        playerItem.allowedAudioSpatializationFormats = Defaults[.spatialAudio].format

        preventsDisplaySleepDuringVideoPlayback = true
        audiovisualBackgroundPlaybackPolicy = .pauses

        replaceCurrentItem(with: playerItem)
    }

    func resourceLoader(_: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let scheme = loadingRequest.request.url?.scheme else {
            return false
        }

        switch scheme {
        case mainScheme:
            return handleMainRequest(loadingRequest)
        case fragmentsScheme:
            return handleFragments(loadingRequest)
        case subtitlesScheme:
            return handleSubtitles(loadingRequest)
        default:
            return false
        }
    }

    private func handleMainRequest(_ request: AVAssetResourceLoadingRequest) -> Bool {
        let request = session.request(urls.first!, method: .get, headers: [.userAgent(Const.userAgent)])
            .validate(statusCode: 200 ..< 400)
            .adapt(using: .adapter { [weak self] request, _, completion in
                guard let self else {
                    completion(.failure(URLError(.cancelled)))
                    return
                }

                var newRequest = request

                guard let currentURL = request.url,
                      let newUrl = urls.element(after: currentURL)
                else {
                    completion(.failure(URLError(.badURL)))
                    return
                }

                newRequest.url = newUrl

                completion(.success(newRequest))
            })
            .retry(using: .retrier { [weak self] request, _, _, completion in
                guard let self else {
                    completion(.doNotRetry)
                    return
                }

                if request.retryCount < urls.count - 1 {
                    completion(.retry)
                } else {
                    completion(.doNotRetry)
                }
            })
            .responseString { [weak self] response in
                guard let self,
                      let string = response.value,
                      let url = response.request?.url,
                      !string.isEmpty,
                      response.error == nil
                else {
                    request.finishLoading(with: response.error)
                    return
                }

                processPlaylist(string, url)
                finishRequestWithMainPlaylist(request)
            }

        request.resume()

        return true
    }

    private func handleFragments(_ request: AVAssetResourceLoadingRequest) -> Bool {
        guard let m3u8String,
              let data = m3u8String.data(using: .utf8)
        else {
            return false
        }

        request.dataRequest?.respond(with: data)
        request.finishLoading()

        return true
    }

    private func handleSubtitles(_ request: AVAssetResourceLoadingRequest) -> Bool {
        guard let url = request.request.url,
              let subtitles = subtitles.first(where: { $0.lang == url.host() }),
              let data = createSubtitlesm3u8(withDuration: playlistDuration, subtitles: subtitles).data(using: .utf8)
        else {
            return false
        }

        request.dataRequest?.respond(with: data)
        request.finishLoading()

        return true
    }

    private func processPlaylist(_ string: String, _ url: URL) {
        let lines = string.components(separatedBy: .newlines).filter { !$0.isEmpty }
        var newLines = [String]()
        var iterator = lines.makeIterator()

        playlistDuration = 0.0

        while let line = iterator.next() {
            newLines.append(line)

            if line.hasPrefix(extInfPrefix), let nextLine = iterator.next() {
                playlistDuration += getDuration(line)
                newLines.append(URL(string: nextLine, relativeTo: url.pathExtension.isEmpty ? url : url.deletingLastPathComponent())?.absoluteString ?? nextLine)
            }
        }

        m3u8String = newLines.joined(separator: "\n")
    }

    private func getDuration(_ line: String) -> Double {
        let parts = line.components(separatedBy: ":").filter { !$0.isEmpty }

        guard parts.count > 1 else { return 0.0 }

        return Double(parts[1].dropLast()) ?? 0.0
    }

    private func finishRequestWithMainPlaylist(_ request: AVAssetResourceLoadingRequest) {
        guard let data = createMainm3u8().data(using: .utf8) else {
            return
        }

        request.dataRequest?.respond(with: data)
        request.finishLoading()
    }

    private func createMainm3u8() -> String {
        """
        #EXTM3U
        \(subtitles
            .map { "#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID=\"subs\",NAME=\"\($0.name)\",DEFAULT=NO,AUTOSELECT=NO,FORCED=NO,URI=\"subtitlesm3u8://\($0.lang)\",LANGUAGE=\"\($0.lang.replacingOccurrences(of: "ua", with: "uk"))\""
            }
            .joined(separator: "\n"))
        \(subtitles.isEmpty ? "#EXT-X-STREAM-INF:BANDWIDTH=1280000,CLOSED-CAPTIONS=NONE\nfragmentsm3u8://foo" : "#EXT-X-STREAM-INF:BANDWIDTH=1280000,SUBTITLES=\"subs\",CLOSED-CAPTIONS=NONE\nfragmentsm3u8://foo")
        """
    }

    private func createSubtitlesm3u8(withDuration duration: Double, subtitles: MovieSubtitles) -> String {
        """
        #EXTM3U
        #EXT-X-VERSION:3
        #EXT-X-MEDIA-SEQUENCE:1
        #EXT-X-PLAYLIST-TYPE:VOD
        #EXT-X-ALLOW-CACHE:NO
        #EXT-X-TARGETDURATION:\(Int(duration))
        #EXTINF:\(String(format: "%.3f", duration)), no desc
        \(subtitles.link)
        #EXT-X-ENDLIST
        """
    }
}

private extension URL {
    func replaceURLScheme(with scheme: String) -> URL? {
        guard var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true) else { return nil }

        urlComponents.scheme = scheme

        return urlComponents.url
    }
}
