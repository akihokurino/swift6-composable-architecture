import Foundation

extension PologOverview: Identifiable {
    var sortedUniqueTransportations: [Transportation] {
        let items = Set(self.routes.flatMap { $0.transportations }).compactMap { $0.value }
        return items.sorted { a, b -> Bool in
            if let aIndex = Transportation.allCases.firstIndex(of: a),
               let bIndex = Transportation.allCases.firstIndex(of: b)
            {
                return aIndex < bIndex
            } else {
                return false
            }
        }
    }

    var dateLabel: String {
        if let firstDate = self.routes.first?.assetDate.iso8601, let lastDate = self.routes.last?.assetDate.iso8601 {
            let days = firstDate.calculateDateDifference(to: lastDate)
            return firstDate.toUnitString(timeZone: TimeZone.current) + " " + days
        } else {
            return ""
        }
    }
}

extension Polog: Identifiable {
    var sortedUniqueTransportations: [Transportation] {
        let items = Set(self.routes.flatMap { $0.transportations }).compactMap { $0.value }
        return items.sorted { a, b -> Bool in
            if let aIndex = Transportation.allCases.firstIndex(of: a),
               let bIndex = Transportation.allCases.firstIndex(of: b)
            {
                return aIndex < bIndex
            } else {
                return false
            }
        }
    }

    var dateLabel: String {
        if let firstDate = self.routes.first?.assetDate.iso8601, let lastDate = self.routes.last?.assetDate.iso8601 {
            let days = firstDate.calculateDateDifference(to: lastDate)
            return firstDate.toUnitString(timeZone: TimeZone.current) + " " + days
        } else {
            return ""
        }
    }
}
