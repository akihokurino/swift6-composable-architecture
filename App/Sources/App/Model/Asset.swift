import Foundation

enum Asset: Equatable {
    case localAsset(LocalAsset)
    case remoteAsset(RemoteAsset)
    
    static func from(local: LocalAsset) -> Asset {
        return .localAsset(local)
    }
    
    static func from(group: GroupAsset) -> Asset {
        return .remoteAsset(RemoteAsset.from(asset: group))
    }
    
    var id: String {
        switch self {
        case .localAsset(let asset):
            return asset.id
        case .remoteAsset(let asset):
            return asset.id
        }
    }
    
    var date: Date {
        switch self {
        case .localAsset(let asset):
            return asset.creationDate ?? Date()
        case .remoteAsset(let asset):
            return asset.date ?? Date()
        }
    }
    
    var isVideo: Bool {
        switch self {
        case .localAsset(let asset):
            return asset.isVideo
        case .remoteAsset(let asset):
            return asset.isVideo
        }
    }
    
    var duration: Int? {
        switch self {
        case .localAsset(let asset):
            return asset.videoDurationSecond
        case .remoteAsset(let asset):
            return asset.videoDurationSecond
        }
    }
    
    var latlng: LatLon {
        switch self {
        case .localAsset(let asset):
            guard let coordinate = asset.location?.coordinate else {
                return LatLon(lat: 0, lng: 0)
            }
            return LatLon(lat: coordinate.latitude, lng: coordinate.longitude)
        case .remoteAsset(let asset):
            return asset.latlng
        }
    }
    
    var size: Size {
        switch self {
        case .localAsset(let asset):
            return Size(width: Double(asset.pixelWidth), height: Double(asset.pixelHeight))
        case .remoteAsset(let asset):
            return asset.size
        }
    }
}

struct RemoteAsset: Equatable {
    let id: String
    var source: RemoteAssetSource
    let date: Date?
    let kind: AssetKind
    let url: URL?
    let gsUrl: URL?
    let videoThumbnailURL: URL?
    let videoDurationSecond: Int?
    let videoStartSecond: Int?
    let videoEndSecond: Int?
    let videoIsMute: Bool?
    let latlng: LatLon
    let size: Size
    
    var thumbnailUrl: URL? {
        switch kind {
        case .photo:
            return url
        case .video:
            return videoThumbnailURL
        }
    }
    
    var isVideo: Bool {
        return kind == .video
    }
    
    static func from(asset: GroupAsset) -> RemoteAsset {
        return RemoteAsset(
            id: asset.id,
            source: .groupAsset,
            date: asset.takenAt.iso8601 ?? Date(),
            kind: asset.kind.value ?? AssetKind.photo,
            url: asset.signedUrl.url,
            gsUrl: asset.gsUrl.url,
            videoThumbnailURL: asset.videoThumbnailSignedUrl?.url,
            videoDurationSecond: asset.videoDurationSecond,
            videoStartSecond: asset.kind == .video ? 0 : nil,
            videoEndSecond: asset.kind == .video ? 15 : nil,
            videoIsMute: asset.kind == .video ? true : nil,
            latlng: LatLon(lat: asset.latlng.lat, lng: asset.latlng.lng),
            size: Size(width: asset.size.width, height: asset.size.height))
    }
    
    // サムネ用
    static func from(asset: Polog) -> RemoteAsset {
        return RemoteAsset(
            id: asset.id,
            source: .pologThumbnail,
            date: nil,
            kind: .photo,
            url: asset.thumbnailSignedUrl.url,
            gsUrl: asset.thumbnailGsUrl.url,
            videoThumbnailURL: nil,
            videoDurationSecond: nil,
            videoStartSecond: nil,
            videoEndSecond: nil,
            videoIsMute: nil,
            latlng: LatLon(lat: 0, lng: 0),
            size: Size(width: 0, height: 0))
    }
    
    static func from(asset: PologRoute) -> RemoteAsset {
        return RemoteAsset(
            id: asset.id,
            source: .pologRouteAsset,
            date: asset.assetDate.iso8601,
            kind: asset.assetKind.value ?? .photo,
            url: asset.assetSignedUrl.url,
            gsUrl: asset.assetGsUrl.url,
            videoThumbnailURL: asset.videoThumbnailSignedUrl?.url,
            videoDurationSecond: asset.videoDurationSecond,
            videoStartSecond: asset.videoStartSecond,
            videoEndSecond: asset.videoEndSecond,
            videoIsMute: asset.videoIsMute,
            latlng: LatLon(lat: asset.spot?.latlng.lat ?? 0, lng: asset.spot?.latlng.lat ?? 0),
            size: Size(width: 0, height: 0))
    }
}

enum RemoteAssetSource {
    case groupAsset
    case pologThumbnail
    case pologRouteAsset
}

struct LatLon: Equatable {
    var lat: Double
    var lng: Double
}

struct Size: Equatable {
    var width: Double
    var height: Double
}
