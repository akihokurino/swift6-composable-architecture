import Foundation

struct DateGroup<T: HasDate & Equatable & Hashable>: Equatable, Identifiable {
    let date: Date
    let assets: [T]

    var id: String {
        return self.date.ISO8601Format()
    }

    static func from(assets: [T]) -> [DateGroup] {
        let groupedAssets = Dictionary(grouping: assets) { asset -> Date in
            asset.groupedDate() ?? Date()
        }

        let sortedGroups = groupedAssets.map { key, value -> DateGroup in
            DateGroup(date: key, assets: value)
        }.sorted { $0.date > $1.date }

        return sortedGroups
    }

    func isAllSelected(selected: Set<T>) -> Bool {
        return self.assets.allSatisfy { selected.contains($0) }
    }
}

protocol HasDate {
    var date: Date? { get }
}

extension HasDate {
    func mustDate() -> Date {
        return date ?? Date()
    }

    func groupedDate() -> Date? {
        guard let creationDate = date else {
            return nil
        }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: creationDate)
        return calendar.date(from: components)
    }
}
