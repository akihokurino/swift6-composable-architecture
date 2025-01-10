import Foundation

extension GroupAsset: Identifiable, HasDate {
    var thumbnailUrl: URL? {
        switch kind {
        case .photo:
            return URL(string: signedUrl)
        case .video:
            return videoThumbnailSignedUrl != nil ? URL(string: videoThumbnailSignedUrl!) : nil
        default:
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
        return takenAt.iso8601
    }

    var isVideo: Bool {
        return kind == .video
    }
}
