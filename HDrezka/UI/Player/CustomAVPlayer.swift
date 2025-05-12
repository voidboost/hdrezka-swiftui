import AVFoundation
import Defaults
import Foundation

class CustomAVPlayer: AVPlayer {
    private let loaderQueue = DispatchQueue(label: "resourceLoader")
    private let delegate: CustomAVAssetResourceLoaderDelegate
    
    init?(m3u8: URL, subtitles: [MovieSubtitles]) {
        self.delegate = CustomAVAssetResourceLoaderDelegate(m3u8: m3u8, subtitles: subtitles)
        
        guard let customURL = Self.replaceURLScheme(with: CustomAVAssetResourceLoaderDelegate.mainScheme, for: m3u8) else {
            return nil
        }
        
        let asset = AVURLAsset(url: customURL)
        asset.resourceLoader.setDelegate(delegate, queue: loaderQueue)
        
        let playerItem = AVPlayerItem(asset: asset)
        playerItem.allowedAudioSpatializationFormats = Defaults[.spatialAudio].format
       
        super.init()
        
        preventsDisplaySleepDuringVideoPlayback = true
        audiovisualBackgroundPlaybackPolicy = .pauses

        replaceCurrentItem(with: playerItem)
    }
    
    private static func replaceURLScheme(with scheme: String, for url: URL) -> URL? {
        guard let index = url.absoluteString.firstIndex(of: ":") else {
            return nil
        }
        
        return URL(string: scheme + url.absoluteString[index...])
    }
}
