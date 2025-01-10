import Foundation
import SwiftData

@Model
final class SD_StagingPolog: @unchecked Sendable, SD_Entity {
    @Attribute(.unique)
    var id: String
    var totalUploadCount: Int
    var uploadedRoutes: [SD_UploadedRoute]
    var createdAt: Date
    var finishedAt: Date?

    @Relationship(inverse: \SD_Polog.staging)
    var polog: SD_Polog?

    init(polog: InputPolog) {
        self.id = polog.id
        self.totalUploadCount = 0
        self.uploadedRoutes = []
        self.createdAt = Date()
        self.finishedAt = nil
        self.polog = SD_Polog(polog: polog)
    }

    init(polog: SD_Polog, totalUploadCount: Int, uploadedRoutes: [SD_UploadedRoute], createdAt: Date, finishedAt: Date?) {
        self.id = polog.id
        self.totalUploadCount = totalUploadCount
        self.uploadedRoutes = uploadedRoutes
        self.createdAt = createdAt
        self.finishedAt = finishedAt
        self.polog = polog
    }

    func updateTotalUploadCount(count: Int) -> SD_StagingPolog {
        return SD_StagingPolog(
            polog: self.polog!,
            totalUploadCount: count,
            uploadedRoutes: self.uploadedRoutes,
            createdAt: self.createdAt,
            finishedAt: self.finishedAt)
    }
}

struct SD_UploadedRoute: Codable {
    let id: String
    let assetGsUrl: String
}
