import Foundation
import SwiftData

@Model
final class SD_DraftedPolog: @unchecked Sendable, SD_Entity {
    @Attribute(.unique)
    var id: String
    var createdAt: Date

    @Relationship(inverse: \SD_Polog.draft)
    var polog: SD_Polog?

    init(polog: InputPolog) {
        self.id = polog.id
        self.createdAt = Date()
        self.polog = SD_Polog(polog: polog)
    }
}
