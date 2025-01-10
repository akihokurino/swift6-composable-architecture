import Foundation
import Nuke

private class ImageCache: URLCache, @unchecked Sendable {
    override func cachedResponse(for request: URLRequest) -> CachedURLResponse? {
        super.cachedResponse(for: ignoreNonCacheParams(request: request))
    }

    override func storeCachedResponse(_ cachedResponse: CachedURLResponse, for request: URLRequest) {
        super.storeCachedResponse(cachedResponse, for: ignoreNonCacheParams(request: request))
    }

    func ignoreNonCacheParams(request: URLRequest) -> URLRequest {
        var request = request
        request.url = request.url?.withoutQuery
        return request
    }
}

extension ImagePipeline {
    static func custom() -> ImagePipeline {
        let urlCache = DataLoader.sharedUrlCache
        let conf = URLSessionConfiguration.default
        conf.urlCache = ImageCache(memoryCapacity: urlCache.memoryCapacity, diskCapacity: urlCache.diskCapacity, diskPath: "com.github.kean.Nuke.Cache")
        conf.requestCachePolicy = .returnCacheDataElseLoad
        return ImagePipeline(configuration: .init(dataLoader: Nuke.DataLoader(configuration: conf)))
    }
}
