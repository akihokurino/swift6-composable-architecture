import Foundation
import UIKit

actor CachedImageStore {
    static let shared = CachedImageStore()

    private init() {}

    private let cache = NSCache<NSString, UIImage>()

    func get(key: String) -> UIImage? {
        return cache.object(forKey: NSString(string: key))
    }

    func set(key: String, image: UIImage) {
        cache.setObject(image, forKey: NSString(string: key))
    }
}

actor DiskCachedImageStore {
    static let shared = DiskCachedImageStore()

    private init() {}

    private let fileManager = FileManager.default
    private let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]

    func get(key: String) -> UIImage? {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        guard let imageData = try? Data(contentsOf: fileURL) else { return nil }
        return UIImage(data: imageData)
    }

    func set(key: String, image: UIImage) {
        let fileURL = cacheDirectory.appendingPathComponent(key)
        if let data = image.jpegData(compressionQuality: 1.0) {
            try? data.write(to: fileURL)
        }
    }
}
