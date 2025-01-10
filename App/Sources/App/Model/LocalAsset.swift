import UIKit

extension LocalAsset: @retroactive Identifiable, HasDate {
    public var id: String {
        return localIdentifier
    }

    var videoDurationSecond: Int? {
        if isVideo {
            return Int(round(duration))
        } else {
            return nil
        }
    }

    var displayDurationSecond: String {
        guard let second = videoDurationSecond else {
            return ""
        }
        return "\(second)S"
    }

    var date: Date? {
        return creationDate
    }

    var isVideo: Bool {
        return mediaType == .video
    }
}

extension LocalAssetCollection: @retroactive Identifiable {
    var title: String {
        return localizedTitle ?? "名前無し"
    }
}
