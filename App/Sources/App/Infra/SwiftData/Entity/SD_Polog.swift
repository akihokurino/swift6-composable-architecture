import Foundation
import SwiftData

@Model
final class SD_Polog: @unchecked Sendable {
    @Attribute(.unique)
    var id: String
    var title: String
    var forewordHtml: String?
    var afterwordHtml: String?
    var label: SD_PologLabel?
    var thumbnailAssetId: String?
    var thumbnailAssetSource: AssetSource?
    var tags: [String]
    var visibility: PologVisibility?
    var isCommentable: Bool
    var innerCompanionIds: [String]
    var outerCompanionNames: [String]

    var draft: SD_DraftedPolog?
    var staging: SD_StagingPolog?

    @Relationship(inverse: \SD_PologRoute.parent)
    var routes: [SD_PologRoute] = []

    init(polog: InputPolog) {
        self.id = polog.id
        self.title = polog.title
        self.forewordHtml = polog.forewordHtml
        self.afterwordHtml = polog.afterwordHtml
        self.label = polog.label != nil ? SD_PologLabel(
            label1: polog.label!.label1,
            label2: polog.label!.label2,
            label3: polog.label!.label3) : nil
        self.thumbnailAssetId = polog.thumbnail?.id
        self.thumbnailAssetSource = polog.thumbnail != nil ? AssetSource.from(asset: polog.thumbnail!) : nil
        self.tags = polog.tags.map { $0.value }
        self.visibility = polog.visibility
        self.isCommentable = polog.isCommentable
        self.innerCompanionIds = polog.companions.compactMap {
            if case .inner(let companion) = $0 {
                return companion.id
            }
            return nil
        }
        self.outerCompanionNames = polog.companions.compactMap {
            if case .outer(let companion) = $0 {
                return companion.name
            }
            return nil
        }
        self.routes = polog.routes.map { route in SD_PologRoute(polog: polog, route: route) }
    }
}

@Model
final class SD_PologRoute: @unchecked Sendable {
    @Attribute(.unique)
    var id: String
    var assetId: String
    var assetSource: AssetSource
    var assetKind: AssetKind
    var assetDate: Date?
    var _description: String
    var isIncludeIndex: Bool
    var priceLabel: String
    var review: Int
    var transportations: [Transportation]
    var videoStartSeconds: Double
    var videoEndSeconds: Double
    var isVideoMuted: Bool
    var spotId: String?

    var parent: SD_Polog?

    init(polog: InputPolog, route: InputPologRoute) {
        self.id = "\(polog.id)_\(route.asset.id)"
        self.assetId = route.asset.id
        self.assetSource = AssetSource.from(asset: route.asset)
        self.assetKind = route.asset.isVideo ? .video : .photo
        self.assetDate = route.assetDate
        self._description = route.description
        self.isIncludeIndex = route.isIncludeIndex
        self.priceLabel = route.priceLabel
        self.review = route.review
        self.transportations = Array(route.transportations)
        self.videoStartSeconds = route.videoStartSeconds
        self.videoEndSeconds = route.videoEndSeconds
        self.isVideoMuted = route.isVideoMuted
        self.spotId = route.spotId
    }
}

extension Transportation: Codable {}
extension AssetKind: Codable {}
extension PologVisibility: Codable {}

struct SD_PologLabel: Codable {
    let label1: String
    let label2: String
    let label3: String
}
