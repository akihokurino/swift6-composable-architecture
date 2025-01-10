import Foundation

struct InputPologRoute: Identifiable, Equatable, HasDate, Hashable {
    let asset: Asset
    var description: String = ""
    var isIncludeIndex: Bool = false
    var updatedAssetDate: Date?
    var priceLabel: String = ""
    var review: Int = 0
    var transportations: Set<Transportation> = Set()
    var videoStartSeconds: Double = 0.0
    var videoEndSeconds: Double = 15.0
    var isVideoMuted: Bool = false
    var isVideoPlaying: Bool = true
    var spotId: String?

    init(
        asset: Asset,
        description: String = "",
        isIncludeIndex: Bool = false,
        updatedAssetDate: Date? = nil,
        priceLabel: String = "",
        review: Int = 0,
        transportations: Set<Transportation> = Set(),
        videoStartSeconds: Double = 0.0,
        videoEndSeconds: Double = 15.0,
        isVideoMuted: Bool = false,
        isVideoPlaying: Bool = true,
        spotId: String? = nil
    ) {
        self.asset = asset
        self.description = description
        self.isIncludeIndex = isIncludeIndex
        self.updatedAssetDate = updatedAssetDate
        self.priceLabel = priceLabel
        self.review = review
        self.transportations = transportations
        self.videoStartSeconds = videoStartSeconds
        self.videoEndSeconds = videoEndSeconds
        self.isVideoMuted = isVideoMuted
        self.isVideoPlaying = isVideoPlaying
        self.spotId = spotId
    }

    var id: String {
        return asset.id
    }

    public func hash(into hasher: inout Hasher) {
        return hasher.combine(id)
    }

    public static func == (lhs: InputPologRoute, rhs: InputPologRoute) -> Bool {
        return lhs.id == rhs.id
    }

    var assetDate: Date {
        if let date = updatedAssetDate {
            return date
        }

        return asset.date
    }

    var date: Date? {
        return assetDate
    }

    var reviewPriceString: String {
        var reviewString = ""
        switch review {
        case 1:
            reviewString = "★"
        case 2:
            reviewString = "★★"
        case 3:
            reviewString = "★★★"
        case 4:
            reviewString = "★★★★"
        case 5:
            reviewString = "★★★★★"
        default:
            reviewString = ""
        }

        if reviewString.isEmpty && priceLabel.isEmpty {
            return ""
        }
        return "\(reviewString)・\(priceLabel)"
    }

    static func from(route: PologRoute) -> InputPologRoute {
        return InputPologRoute(
            asset: .remoteAsset(RemoteAsset.from(asset: route)),
            description: route.description ?? "",
            isIncludeIndex: route.isIncludeIndex,
            priceLabel: route.priceLabel ?? "",
            review: route.review ?? 0,
            transportations: Set(route.transportations.map { $0.value! }),
            videoStartSeconds: Double(route.videoStartSecond ?? 0),
            videoEndSeconds: Double(route.videoEndSecond ?? 0),
            isVideoMuted: route.videoIsMute ?? true,
            isVideoPlaying: false,
            spotId: route.spot?.id
        )
    }
}
