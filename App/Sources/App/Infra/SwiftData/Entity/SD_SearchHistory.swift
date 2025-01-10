import Foundation
import SwiftData

@Model
final class SD_SearchHistory: @unchecked Sendable, SD_Entity {
    @Attribute(.unique)
    var id: String
    var values: [String]
    var createdAt: Date

    init(values: [String]) {
        self.id = "singleton"
        self.values = values
        self.createdAt = Date()
    }

    func add(query: String) -> SD_SearchHistory {
        var newValues = self.values.filter { $0 != query }
        newValues.insert(query, at: 0)
        newValues = newValues.count > 10 ? Array(newValues.prefix(10)) : newValues
        return SD_SearchHistory(values: newValues)
    }

    func delete(query: String) -> SD_SearchHistory {
        let newValues = self.values.filter { $0 != query }
        return SD_SearchHistory(values: newValues)
    }

    static func empty() -> SD_SearchHistory {
        return SD_SearchHistory(values: [])
    }
}
