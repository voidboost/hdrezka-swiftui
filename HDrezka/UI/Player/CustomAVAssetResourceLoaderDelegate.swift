import AVFoundation
import Foundation

class CustomAVAssetResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate {
    static let mainScheme = "mainm3u8"
    private let fragmentsScheme = "fragmentsm3u8"
    private let subtitlesScheme = "subtitlesm3u8"
    private let extInfPrefix = "#EXTINF:"
    private var m3u8: URL
    private var subtitles: [MovieSubtitles]
    private var m3u8String: String?
    private var playlistDuration: Double = 0.0
    
    init(m3u8: URL, subtitles: [MovieSubtitles]) {
        self.m3u8 = m3u8
        self.subtitles = subtitles
        
        super.init()
    }
    
    func resourceLoader(_ resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
        guard let scheme = loadingRequest.request.url?.scheme else {
            return false
        }
                        
        switch scheme {
        case Self.mainScheme:
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
        let request = Const.session.request(m3u8, method: .get, headers: [.userAgent(Const.userAgent)])
            .validate(statusCode: 200 ..< 400)
            .responseString { [weak self] response in
                guard let self,
                      let string = response.value,
                      !string.isEmpty,
                      response.error == nil
                else {
                    request.finishLoading(with: response.error)
                    return
                }
            
                self.processPlaylist(string)
                self.finishRequestWithMainPlaylist(request)
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
    
    private func processPlaylist(_ string: String) {
        let lines = string.components(separatedBy: .newlines)
        var newLines = [String]()
        var iterator = lines.makeIterator()
        
        playlistDuration = 0.0
        
        while let line = iterator.next() {
            newLines.append(line)
            
            if line.hasPrefix(extInfPrefix), let nextLine = iterator.next() {
                playlistDuration += getDuration(forEXTINFLine: line)
                newLines.append(appendBasePath(to: nextLine))
            }
        }
        
        m3u8String = newLines.joined(separator: "\n")
    }
    
    private func getDuration(forEXTINFLine line: String) -> Double {
        let parts = line.components(separatedBy: ":")
        
        guard parts.count > 1 else { return 0.0 }
      
        return Double(parts[1].dropLast()) ?? 0.0
    }
    
    private func appendBasePath(to string: String) -> String {
        guard var components = URLComponents(url: m3u8, resolvingAgainstBaseURL: false) else {
            return string
        }
        
        components.query = nil
        
        if let baseURL = components.url?.deletingLastPathComponent().absoluteString {
            return baseURL + string
        } else {
            return string
        }
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
