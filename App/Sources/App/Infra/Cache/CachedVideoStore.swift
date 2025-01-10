import AVKit
import UIKit

actor CachedVideoStore {
    static let shared = CachedVideoStore()

    private init() {}

    private let cache = NSCache<NSString, AVAsset>()

    func get(key: String) -> AVAsset? {
        return cache.object(forKey: NSString(string: key))
    }

    func set(key: String, video: AVAsset) {
        cache.setObject(video, forKey: NSString(string: key))
    }
}
