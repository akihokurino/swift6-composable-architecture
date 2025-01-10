import Foundation

extension GroupAlbum: Identifiable {
    var assetDateRange: String {
        guard let from = includeAssetFrom?.iso8601, let to = includeAssetTo?.iso8601 else {
            return ""
        }

        return "\(from.ymDisplayJST)〜\(to.ymDisplayJST)"
    }
}

extension GroupAlbumOverview: Identifiable {}
