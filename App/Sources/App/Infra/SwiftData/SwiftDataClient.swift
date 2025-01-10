import Foundation
import SwiftData

final class SwiftDataClient: Sendable {
    let modelContainer: ModelContainer

    init() {
        let schema = Schema([
            SD_SearchHistory.self,
            SD_Polog.self,
            SD_PologRoute.self,
            SD_DraftedPolog.self
        ])
        let sqliteURL = URL.documentsDirectory
            .appending(component: "polog")
            .appendingPathExtension("sqlite")
        let modelConfiguration = ModelConfiguration(schema: schema, url: sqliteURL)
        self.modelContainer = try! ModelContainer(
            for: schema,
            configurations: modelConfiguration
        )
    }

    var modelContext: ModelContext {
        ModelContext(modelContainer)
    }

    func fetch<T: PersistentModel & SD_Entity>(context: ModelContext? = nil) throws -> [T] {
        let _context = context ?? ModelContext(modelContainer)
        let sortDescriptor = SortDescriptor(\T.createdAt, order: .reverse)
        let fetchDescriptor = FetchDescriptor<T>(sortBy: [sortDescriptor])
        let allItems = try _context.fetch(fetchDescriptor)
        return allItems
    }

    func fetchOne<T: PersistentModel & SD_Entity>(context: ModelContext? = nil) throws -> T? {
        let _context = context ?? ModelContext(modelContainer)
        var fetchDescriptor = FetchDescriptor<T>()
        fetchDescriptor.fetchLimit = 1
        let allItems = try _context.fetch(fetchDescriptor)
        return allItems.first
    }

    func save<T: PersistentModel & SD_Entity>(item: T, context: ModelContext? = nil) throws {
        let _context = context ?? ModelContext(modelContainer)
        _context.insert(item)
        try _context.save()
    }

    func delete<T: PersistentModel & SD_Entity>(item: T, context: ModelContext? = nil) throws {
        let targetId = item.id
        let _context = context ?? ModelContext(modelContainer)
        try _context.delete(model: T.self, where: #Predicate { v in v.id == targetId })
        try _context.save()
    }
}

protocol SD_Entity {
    var id: String { get }
    var createdAt: Date { get }
}
