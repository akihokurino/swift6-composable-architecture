import Foundation
import SwiftData

enum AssetSource: String, Codable {
    case local
    case groupAsset
    case pologThumbnail
    case pologRouteAsset

    static func from(asset: Asset) -> AssetSource {
        switch asset {
        case .localAsset:
            return .local
        case .remoteAsset(let asset):
            switch asset.source {
            case .groupAsset:
                return .groupAsset
            case .pologThumbnail:
                return .pologThumbnail
            case .pologRouteAsset:
                return .pologRouteAsset
            }
        }
    }
}
